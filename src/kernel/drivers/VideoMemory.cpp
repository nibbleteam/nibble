#define _USE_MATH_DEFINES
#include <cmath>
#include <SFML/OpenGL.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <iostream>
#include <cstring>

const uint64_t VideoMemory::nibblesPerPixel = 8;
const uint64_t VideoMemory::bytesPerPixel = 4;
const uint32_t VideoMemory::vertexArrayLength = 4096;

// Vertex shader padrão do SFML sem alterações
const string VideoMemory::shaderVertex = R"(
void main()
{
    // transform the vertex position
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    // transform the texture coordinates
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;

    // forward the vertex color
    gl_FrontColor = gl_Color;
}
)";

// Desenha Quads e Sprites
const string VideoMemory::spriteShaderFragment = R"(
#define HIGH(x) int(x*255.0)/16
#define LOW(x) int(x*255.0)-HIGH(x)*16

const float screen_w = 8192.0;
const float nibbles_per_pixel = 8.0;
// Sprites
uniform sampler2D sprites;
// Paleta
uniform sampler2D palette;

void main()
{
    // Sprite desenhado no buffer de cor ou tempo
    if (HIGH(gl_Color.r) == 1 || HIGH(gl_Color.r) == 2) {
        vec2 coord = vec2(gl_TexCoord[0].x, gl_TexCoord[0].y);
        // Em qual byte e nibble do pixel estamos
        int nibble = int(mod(coord.x*screen_w, nibbles_per_pixel));
        int byte = nibble/2;
        vec4 pix = texture2D(sprites, coord);

        float source;

        if (byte == 0) {
            source = pix.r;
        } else if (byte == 1) {
            source = pix.g;
        } else if (byte == 2) {
            source = pix.b;
        } else {
            source = pix.a;
        }

        float shade;
        
        if (mod(float(nibble), 2.0) == 0.0)
            shade = float(HIGH(source))/256.0;
        else
            shade = float(LOW(source))/256.0;
 
        // Aplica a paleta
        shade = shade + (float(LOW(gl_Color.r))/256.0)*16.0;

        vec4 color = texture2D(palette, vec2(mod(shade*2.0, 1.0), 0.5));

        if (color.a == 0.0)
            discard;

        // Desenha tempo
        if (HIGH(gl_Color.r) == 2) {
            gl_FragColor = vec4(0.0, gl_Color.gba);
        }
        // Desenha cor
        else {
            gl_FragColor = vec4(shade, shade, shade, shade);
        }
    }
    // Quad no buffer de cor ou tempo
    else if (HIGH(gl_Color.r) == 3 || HIGH(gl_Color.r) == 0) {
        gl_FragColor = vec4(0.0, gl_Color.gba);
    }
}
)";

// Utiliza duas texturas adicionais com as
// informações de timing das duas texturas utilizadas para desenhar
// de forma que pode escolher apenas desenhar cada pixel
// daquela atualizada mais recentemente
const string VideoMemory::combineShaderFragment = R"(
// Converte um vetor de float pra um int de 4bytes
#define INT4BYTES(x) int(x.g*255.0)*256*256+int(x.b*255.0)*256+int(x.a*255.0)

const float screen_w = 320.0;
// 4 canais na textura (RGBA)
const float bytes_per_pixel = 4.0;

// Primeira textura esticada, desenhos da CPU
uniform sampler2D cpuTexture;
// Segunda textura, desenhos da GPU 
uniform sampler2D gpuTextureLines;
uniform sampler2D gpuTextureTris;
uniform sampler2D gpuTextureQuads;
// Timing
uniform sampler2D cpuTiming;
uniform sampler2D gpuTimingLines;
uniform sampler2D gpuTimingTris;
uniform sampler2D gpuTimingQuads;

void main()
{
    // Coordenadas no espaço da textura
    vec2 coord = vec2(gl_TexCoord[0].x, gl_TexCoord[0].y);
    // Alinha as coordenadas a 4 bytes
    float x = float(int(coord.x*screen_w)/int(bytes_per_pixel))*bytes_per_pixel/screen_w + 0.5/screen_w;

    // Constroi a saída 4 pixels por vez
    vec4 pixelCpu = texture2D(cpuTexture, vec2(coord.x, 1.0-coord.y));
    for (int i=0;i<int(bytes_per_pixel);i++) {
        vec4 cpuTimeV = texture2D(cpuTiming, vec2(x, 1.0-coord.y));
        vec4 gpuTimeQuadsV = texture2D(gpuTimingQuads, vec2(x, coord.y));
        vec4 pixelGpuQuads = texture2D(gpuTextureQuads, vec2(x, coord.y));
        vec4 gpuTimeTrisV= texture2D(gpuTimingTris, vec2(x, coord.y));
        vec4 pixelGpuTris = texture2D(gpuTextureTris, vec2(x, coord.y));
        vec4 gpuTimeLinesV = texture2D(gpuTimingLines, vec2(x, coord.y));
        vec4 pixelGpuLines = texture2D(gpuTextureLines, vec2(x, coord.y));

        int cpuTime = INT4BYTES(cpuTimeV);
        int gpuTimeQuads = INT4BYTES(gpuTimeQuadsV);
        int gpuTimeTris = INT4BYTES(gpuTimeTrisV);
        int gpuTimeLines = INT4BYTES(gpuTimeLinesV);

        // Utiliza o buffer mais atualizado
        if (cpuTime >= gpuTimeQuads &&
            cpuTime >= gpuTimeLines &&
            cpuTime >= gpuTimeTris) {
            gl_FragColor[i] = pixelCpu[i];
        } else if (gpuTimeQuads > gpuTimeTris &&
                   gpuTimeQuads > gpuTimeLines) {
            gl_FragColor[i] = pixelGpuQuads.a;
        } else if (gpuTimeTris > gpuTimeLines) {
            gl_FragColor[i] = pixelGpuTris.a;
        } else if (gpuTimeLines > 0) {
            gl_FragColor[i] = pixelGpuLines.a;
        } else {
            discard;
        }

        // Próximo pixel
        x += 1.0/screen_w;
    }
}
)";

// Recebe duas texturas com 1/4 do comprimento da tela
// esticada para o tamanho da tela e endereça cada 
// pixel na imagem como 4 pixels na tela.
// Para fazer isso considera cada canal como
// um pixel
const string VideoMemory::toRGBAShaderFragment = R"(
const float screen_w = 320.0;
// 4 canais na textura (RGBA)
const float bytes_per_pixel = 4.0;

// Textura comprimida onde 1 pixel real são 4 pixels virtuais
uniform sampler2D source;
// Textura 1xN da paleta
uniform sampler2D palette;

void main()
{
    // Coordenadas no espaço da textura
    vec2 coord = gl_TexCoord[0].xy;
    // Em qual byte do pixel estamos
    int byte = int(mod(coord.x*screen_w, bytes_per_pixel));

    // Cor do pixel na textura
    vec4 pixel = texture2D(source, coord);

    // Qual canal do pixel da textura vamos
    // usar para o pixel na tela
    float source;
    // Primeiro byte, segundo byte etc
    // Os módulos limitam a 8 paletas
    if (byte == 0)
        source = pixel.r;
    else if (byte == 1)
        source = pixel.g; 
    else if (byte == 2)
        source = pixel.b;
    else if (byte == 3)
        source = pixel.a;

    vec4 color = texture2D(palette, vec2(mod(source*2.0, 1.0), 0.0));

    gl_FragColor = vec4(color.r, color.g, color.b, 1.0);
}
)";

VideoMemory::VideoMemory(sf::RenderWindow &window,
                         const unsigned int w,
                         const unsigned int h,
                         const uint64_t addr):
    w(w), h(h), address(addr), length(w*h),
    gpuTQuadsBuffer(sf::Quads, 4), gpuQuadsBuffer(sf::Quads, 4),
    gpuTLinesBuffer(sf::Lines, 2), gpuLinesBuffer(sf::Lines, 2),
    gpuTTrisBuffer(sf::Triangles, 3), gpuTrisBuffer(sf::Triangles, 3),
    currentDraw(1), window(window), colormap(NULL) {
    // Tamanho da textura é 1/4 do tamanho da tela
    // uma vez que um pixel no sfml são quatro bytes
    // e no console é apenas um
    cpuTexture.create(w/bytesPerPixel, h);
    gpuRenderTextureQuads.create(w, h);
    gpuRenderTextureTris.create(w, h);
    gpuRenderTextureLines.create(w, h);
    framebuffer.create(w/bytesPerPixel, h);
    // Timings das operações de desenho
    cpuTiming.create(w, h);
    gpuRenderTimingQuads.create(w, h);
    gpuRenderTimingTris.create(w, h);
    gpuRenderTimingLines.create(w, h);

    gpuRenderTextureQuads.clear(sf::Color::Transparent);
    gpuRenderTextureTris.clear(sf::Color::Transparent);
    gpuRenderTextureLines.clear(sf::Color::Transparent);
    framebuffer.clear(sf::Color::Transparent);
    gpuRenderTimingQuads.clear(sf::Color::Transparent);
    gpuRenderTimingTris.clear(sf::Color::Transparent);
    gpuRenderTimingLines.clear(sf::Color::Transparent);

    // Texturas para ler as RenderTextures
    auto &gpuTextureLines = gpuRenderTextureLines.getTexture();
    auto &gpuTextureTris = gpuRenderTextureTris.getTexture();
    auto &gpuTextureQuads = gpuRenderTextureQuads.getTexture();
    auto &gpuTimingQuads = gpuRenderTimingQuads.getTexture();
    auto &gpuTimingTris = gpuRenderTimingTris.getTexture();
    auto &gpuTimingLines = gpuRenderTimingLines.getTexture();
    auto &framebufferTexture = framebuffer.getTexture();
    
    // Sprites para desenhar as RenderTextures
    // Framebuffer na tela inteira
    framebufferSpr = sf::Sprite(framebufferTexture);
    framebufferSpr.setScale(bytesPerPixel, 1);
    // combineSpr na área de cpuTexture, gpuTexture e framebuffer
    combineSpr = sf::Sprite(cpuTexture);
    combineSpr.setScale(1, 1);
    
    // Cria a textura da palleta
    paletteTex.create(GPU::paletteLength*GPU::paletteAmount, 1);
    
    spriteTex.create(1024, 1024);
    
    // Tenta carregar o shader, em caso de erro termina
    // uma vez que não será possível mostrar nada
    if (!combineShader.loadFromMemory(shaderVertex, combineShaderFragment)) {
        cout << "video " << "error loading combine shader" << endl;
        exit(1);
    }
    else {
        // Passa texuras de entrada
        combineShader.setUniform("cpuTexture", cpuTexture);
        combineShader.setUniform("gpuTextureLines", gpuTextureLines);
        combineShader.setUniform("gpuTextureTris", gpuTextureTris);
        combineShader.setUniform("gpuTextureQuads", gpuTextureQuads);
        
        // Passa texturas de timing
        combineShader.setUniform("cpuTiming", cpuTiming);
        combineShader.setUniform("gpuTimingLines", gpuTimingLines);
        combineShader.setUniform("gpuTimingTris", gpuTimingTris);
        combineShader.setUniform("gpuTimingQuads", gpuTimingQuads);
    }
    // Shader de final de pipeline
    if (!toRGBAShader.loadFromMemory(shaderVertex, toRGBAShaderFragment)) {
        cout << "video " << "error loading toRGBA shader" << endl;
        exit(1);
    }
    else {
        // Passa textura do framebuffer e paleta
        toRGBAShader.setUniform("source", framebufferTexture);
        toRGBAShader.setUniform("palette", paletteTex);
    }
    // Shader para desenhar sprites
    if (!spriteShader.loadFromMemory(shaderVertex, spriteShaderFragment)) {
        cout << "video" << "error loading sprite shader" << endl;
        exit(1);
    } else {
        spriteShader.setUniform("sprites", spriteTex);
        spriteShader.setUniform("palette", paletteTex);
    }

    // Usa o shader de sprites no buffer de Quads
    gpuQuadsBuffer.setShader(&spriteShader);
    gpuTQuadsBuffer.setShader(&spriteShader);

    const uint64_t videoRamSize = w*h;

    // Inicializa a memória
    buffer = new uint8_t[videoRamSize];
    for (unsigned int i=0;i<videoRamSize;i++) {
        buffer[i] = int(255*sin(i/14))%0x10;
        //buffer[i] = 0;
    }
    timingBuffer = new uint8_t[bytesPerPixel*videoRamSize];

    for (unsigned int i=0;i<videoRamSize*bytesPerPixel;i++) {
        timingBuffer[i] = 0;
    }

    // Inicializa com bytes não inicializados
    cpuTexture.update(buffer);
}

VideoMemory::~VideoMemory() {
    if (colormap != NULL) {
        stopCapturing();
    }

    delete[] timingBuffer;
    delete[] buffer;
}

bool VideoMemory::startCapturing(const string& path) {
    int error;

    // Cria um colormap a partir da paleta
    colormap = getColorMap();

    // Abre um GIF pra salvar a tela
    gif = EGifOpenFileName(path.c_str(), false, &error);
    // Versão nova do GIF
    EGifSetGifVersion(gif, true);
    // Coonfigurações da screen
    error = EGifPutScreenDesc(gif, w, h,
                              GPU::paletteLength*GPU::paletteAmount, 0,
                              colormap);
    // Limpa a paleta que foi escrita
    GifFreeMapObject(colormap);

    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    char loop[] {
        0x01, 0x00, 0x00
            };
    error = 0;
    error |= EGifPutExtensionLeader(gif, APPLICATION_EXT_FUNC_CODE);
    error |= EGifPutExtensionBlock(gif, 0x0b, "NETSCAPE2.0");
    error |= EGifPutExtensionBlock(gif, 0x03, loop);
    error |= EGifPutExtensionTrailer(gif);

    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    return true;
}

bool VideoMemory::stopCapturing() {
    int error;
    EGifCloseFile(gif, &error);
    if (error != GIF_OK) {
        return false;
    }

    gif = NULL;
    colormap = NULL;

    return true;
}

bool VideoMemory::captureFrame() {
    int error;
    char graphics[] {
        0, 4&0xFF, 4>>8, 0
            };
    error = EGifPutExtension(
        gif,
        GRAPHICS_EXT_FUNC_CODE,
        sizeof(graphics),
        &graphics);

    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    error = EGifPutImageDesc(gif, 0, 0, w, h,
                             false, NULL);
    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }
    error = EGifPutLine(gif, buffer, w*h);
    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    return true;
}

ColorMapObject* VideoMemory::getColorMap() {
    // "Paleta" do GIF
    GifColorType colors[GPU_PALETTE_LENGTH*GPU_PALETTE_AMOUNT];
    auto image = paletteTex.copyToImage();

    // Preenche o color map no formato do GIF
    // a partir do formato de paleta do console
    for (uint64_t i=0;i<GPU_PALETTE_LENGTH*GPU_PALETTE_AMOUNT;i++) {
        sf::Color color = image.getPixel(i, 0);
        // Remove o alpha
        colors[i] = GifColorType {
            color.r, color.g, color.b
        };
    }

    colormap = GifMakeMapObject(GPU_PALETTE_LENGTH*GPU_PALETTE_AMOUNT, colors);

    return colormap;
}

void VideoMemory::clearCpuTiming() {
    memset(timingBuffer, 0, w*h*4);
    cpuTiming.update(timingBuffer, w, h, 0, 0);
}

void VideoMemory::drawCpuTiming(uint32_t time, uint64_t p, uint64_t size) {
    // Converte o tempo para big endian
    uint8_t *otime = (uint8_t*)&time;
    uint8_t ntime[4];

    ntime[0] = otime[3];
    ntime[1] = otime[2];
    ntime[2] = otime[1];
    ntime[3] = otime[0];

    // A textura de timing tem 4 bytes por pixel
    p = p*sizeof(time);
    // Escreve os primeiros 4 bytes
    memmove(timingBuffer+p, ntime, sizeof(time));

    // Início
    uint64_t start = p;
    // Em que posição da memória esse processo acaba
    uint64_t end = p+size*sizeof(time);
    // Quantos bytes vamos transferir na próxima iteração
    uint64_t transfer = sizeof(time);

    // Copia dobrando a quantidade até onde possível
    p += sizeof(time);
    while (p+transfer < end) {
        memmove(timingBuffer+p, timingBuffer+start, transfer);
        p += transfer;
        transfer *= 2;
    }
    
    // Copia o restante
    memmove(timingBuffer+p, timingBuffer+start, end-p);
}

sf::Color VideoMemory::pal2Color(uint8_t pal) {
    return sf::Color {
        uint8_t('\x10'+pal),
            0,
            0,
            0
            };
}

sf::Color VideoMemory::index2Color(uint8_t color) {
    return sf::Color {
        '\x30'+8,
            0,
            0,
            color
            };
}

sf::Color VideoMemory::time2Color(uint32_t time) {
    return sf::Color {
        0,
            (uint8_t)(time>>16),
            (uint8_t)(time>>8),
            (uint8_t)time
            };
}

sf::Color VideoMemory::spriteTime2Color(uint8_t pal, uint32_t time) {
    return sf::Color {
        uint8_t('\x20'+pal),
            (uint8_t)(time>>16),
            (uint8_t)(time>>8),
            (uint8_t)time
            };
}

void VideoMemory::gpuLine(RenderBuffer &buffer, sf::Color color,
                          const int16_t x1, const int16_t y1,
                          const int16_t x2, const int16_t y2) {
    buffer.add({
            sf::Vertex(sf::Vector2f(x1, y1), color),
                sf::Vertex(sf::Vector2f(x2, y2), color),
                });
}

void VideoMemory::gpuRect(RenderBuffer &buffer, sf::Color color,
                          const int16_t x, const int16_t y,
                          const int16_t w, const int16_t h) {
    buffer.add({
            sf::Vertex(sf::Vector2f(x, y), color),
                sf::Vertex(sf::Vector2f(x+w, y), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(x+w, y), color),
                sf::Vertex(sf::Vector2f(x+w, y+h), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(x+w, y+h), color),
                sf::Vertex(sf::Vector2f(x, y+h), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(x, y+h+1), color),
                sf::Vertex(sf::Vector2f(x, y), color),
                });
}

void VideoMemory::gpuQuad(RenderBuffer &buffer, sf::Color color,
                          const int16_t x1, const int16_t y1,
                          const int16_t x2, const int16_t y2,
                          const int16_t x3, const int16_t y3,
                          const int16_t x4, const int16_t y4) {
    buffer.add({
            sf::Vertex(sf::Vector2f(x1, y1), color),
                sf::Vertex(sf::Vector2f(x2, y2), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(x2, y2), color),
                sf::Vertex(sf::Vector2f(x3, y3), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(x3, y3), color),
                sf::Vertex(sf::Vector2f(x4-0.5, y4), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(x4-0.5, y4), color),
                sf::Vertex(sf::Vector2f(x1, y1), color),
                });
}

void VideoMemory::gpuTri(RenderBuffer &buffer, sf::Color color,
                         const int16_t x1, const int16_t y1,
                         const int16_t x2, const int16_t y2,
                         const int16_t x3, const int16_t y3) {
    buffer.add({
            sf::Vertex(sf::Vector2f(0.5+x1, 0.5+y1), color),
                sf::Vertex(sf::Vector2f(0.5+x2, 0.5+y2), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(0.5+x2, 0.5+y2), color),
                sf::Vertex(sf::Vector2f(0.5+x3, 0.5+y3), color),
                });
    buffer.add({
            sf::Vertex(sf::Vector2f(0.5+x3, 0.5+y3), color),
                sf::Vertex(sf::Vector2f(0.5+x1, 0.5+y1), color),
                });
}

void VideoMemory::gpuCircle(RenderBuffer &buffer, sf::Color color,
                            const int16_t destX, const int16_t destY,
                            const int16_t radius) {
    unsigned int size = radius/6>0?radius/6:1;
    unsigned int segments = radius * 2 * M_PI/size;

    float theta = 2 * M_PI / float(segments); 
    float c = cosf(theta);
    float s = sinf(theta);
    float tmp;

    float x = radius;
    float y = 0; 
    
    float px, py;

    for(unsigned int i = 0; i < segments; i++) {
        px = x; py = y;   

        // Rotacionando x e y
        tmp = x;
        x = c * x - s * y;
        y = s * tmp + c * y;

        buffer.add({
                sf::Vertex(sf::Vector2f(px+destX, py+destY), color),
                    sf::Vertex(sf::Vector2f(x+destX, y+destY), color),
                    });
    }
}

void VideoMemory::gpuFillCircle(RenderBuffer &buffer, sf::Color color,
                                const int16_t destX, const int16_t destY,
                                const int16_t radius) {
    unsigned int size = radius/6>0?radius/6:1;
    unsigned int segments = ceil(radius * 2 * M_PI/float(size));

    float theta = 2 * M_PI / float(segments); 
    float c = cosf(theta);
    float s = sinf(theta);
    float tmp;

    float x = radius;
    float y = 0; 
    
    float px, py;

    for(unsigned int i = 0; i < segments; i++) {
        px = x; py = y;   

        // Rotacionando x e y
        tmp = x;
        x = c * x - s * y;
        y = s * tmp + c * y;

        buffer.add({
                sf::Vertex(sf::Vector2f(destX, destY), color),
                    sf::Vertex(sf::Vector2f(px+destX, py+destY), color),
                    sf::Vertex(sf::Vector2f(x+destX, y+destY), color),
                    });
    }
}

void VideoMemory::gpuFillRect(RenderBuffer &buffer, sf::Color color,
                              const int16_t x, const int16_t y,
                              const int16_t w, const int16_t h) {
    buffer.add({
            sf::Vertex(sf::Vector2f(x, y), color),
                sf::Vertex(sf::Vector2f(x+w, y), color),
                sf::Vertex(sf::Vector2f(x+w, y+h), color),
                sf::Vertex(sf::Vector2f(x, y+h), color)
                });
}

void VideoMemory::gpuSprite(RenderBuffer &buffer, sf::Color color,
                            const int16_t sx, const int16_t sy,
                            const int16_t x, const int16_t y,
                            const int16_t w, const int16_t h) {
    float a, b, c, d;
    auto size = spriteTex.getSize();

    a = float(sx)/(size.x*8);
    b = float(sy)/size.y;
    c = float(sx+w)/(size.x*8);
    d = float(sy+h)/size.y;

    buffer.add({
            sf::Vertex(sf::Vector2f(x, y), color, sf::Vector2f(a, b)),
                sf::Vertex(sf::Vector2f(x+w, y), color, sf::Vector2f(c, b)),
                sf::Vertex(sf::Vector2f(x+w, y+h), color, sf::Vector2f(c, d)),
                sf::Vertex(sf::Vector2f(x, y+h), color, sf::Vector2f(a, d))
                });
}

void VideoMemory::gpuFillTri(RenderBuffer &buffer, sf::Color color,
                             const int16_t x1, const int16_t y1,
                             const int16_t x2, const int16_t y2,
                             const int16_t x3, const int16_t y3) {
    buffer.add({
                sf::Vertex(sf::Vector2f(x1, y1), color),
                sf::Vertex(sf::Vector2f(x2, y2), color),
                sf::Vertex(sf::Vector2f(x3, y3), color)
                });
}

void VideoMemory::gpuFillQuad(RenderBuffer &buffer, sf::Color color,
                              const int16_t x1, const int16_t y1,
                              const int16_t x2, const int16_t y2,
                              const int16_t x3, const int16_t y3,
                              const int16_t x4, const int16_t y4) {
    buffer.add({
            sf::Vertex(sf::Vector2f(x1, y1), color),
                sf::Vertex(sf::Vector2f(x2, y2), color),
                sf::Vertex(sf::Vector2f(x3, y3), color),
                sf::Vertex(sf::Vector2f(x4, y4), color)
                });
}

uint8_t VideoMemory::next8Arg(uint8_t *&arg) {
    return *arg++;
}

int16_t VideoMemory::next16Arg(uint8_t *&arg) {
    int16_t value = (int16_t)arg[0]<<8 | (uint16_t)arg[1];
    arg+=sizeof(int16_t);
    return value;
}

void VideoMemory::execGpuCommand(uint8_t *cmd) {
    enum Commands {
        Clear = 0x00,
        FillRect,
        FillQuad,
        FillTri,
        FillCircle,
        Line,
        Rect,
        Quad,
        Tri,
        Circle,
        Sprite,
    };

    switch (*cmd++) {
    case Clear: {
        auto color = next8Arg(cmd);
        
        gpuFillRect(gpuQuadsBuffer, index2Color(color),
                    0, 0, w, h);
        gpuFillRect(gpuTQuadsBuffer, time2Color(currentDraw),
                    0, 0, w, h);
    }
        break;
    case FillRect: {
        auto color = next8Arg(cmd);
        auto x = next16Arg(cmd), y = next16Arg(cmd);
        auto w = next16Arg(cmd), h = next16Arg(cmd);
        
        gpuFillRect(gpuQuadsBuffer, index2Color(color),
                    x, y, w, h);
        gpuFillRect(gpuTQuadsBuffer, time2Color(currentDraw),
                    x, y, w, h);
    }
        break;
    case FillQuad: {
        auto color = next8Arg(cmd);
        auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
        auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
        auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);
        auto x4 = next16Arg(cmd), y4 = next16Arg(cmd);

        gpuFillQuad(gpuQuadsBuffer, index2Color(color),
                    x1, y1, x2, y2, x3, y3, x4, y4);
        gpuFillQuad(gpuTQuadsBuffer, time2Color(currentDraw),
                    x1, y1, x2, y2, x3, y3, x4, y4);
    }
        break;
    case FillTri: {
        auto color = next8Arg(cmd);
        auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
        auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
        auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);

        gpuFillTri(gpuTrisBuffer, index2Color(color),
                   x1, y1, x2, y2, x3, y3);
        gpuFillTri(gpuTTrisBuffer, time2Color(currentDraw),
                   x1, y1, x2, y2, x3, y3);
    }
        break;
    case Line: {
        auto color = next8Arg(cmd);
        auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
        auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);

        gpuLine(gpuLinesBuffer, index2Color(color),
                x1, y1, x2, y2);
        gpuLine(gpuTLinesBuffer, time2Color(currentDraw),
                x1, y1, x2, y2);
    }
        break;
    case Rect: {
        auto color = next8Arg(cmd);
        auto x = next16Arg(cmd), y = next16Arg(cmd);
        auto w = next16Arg(cmd), h = next16Arg(cmd);

        gpuRect(gpuLinesBuffer, index2Color(color),
                x, y, w, h);
        gpuRect(gpuTLinesBuffer, time2Color(currentDraw),
                x, y, w, h);
    }
        break;
    case Quad: {
        auto color = next8Arg(cmd);
        auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
        auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
        auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);
        auto x4 = next16Arg(cmd), y4 = next16Arg(cmd);

        gpuQuad(gpuLinesBuffer, index2Color(color),
                x1, y1, x2, y2, x3, y3, x4, y4);
        gpuQuad(gpuTLinesBuffer, time2Color(currentDraw),
                x1, y1, x2, y2, x3, y3, x4, y4);
    }
        break;
    case Tri: {
        auto color = next8Arg(cmd);
        auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
        auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
        auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);

        gpuTri(gpuLinesBuffer, index2Color(color),
               x1, y1, x2, y2, x3, y3);
        gpuTri(gpuTLinesBuffer, time2Color(currentDraw),
               x1, y1, x2, y2, x3, y3);
    }
        break;
    case Circle: {
        auto color = next8Arg(cmd);
        auto x = next16Arg(cmd), y = next16Arg(cmd);
        auto r = next16Arg(cmd);

        gpuCircle(gpuLinesBuffer, index2Color(color),
                  x, y, r);
        gpuCircle(gpuTLinesBuffer, time2Color(currentDraw),
                  x, y, r);
    }
        break;
    case FillCircle: {
        auto color = next8Arg(cmd);
        auto x = next16Arg(cmd), y = next16Arg(cmd);
        auto r = next16Arg(cmd);

        gpuFillCircle(gpuTrisBuffer, index2Color(color),
                      x, y, r);
        gpuFillCircle(gpuTTrisBuffer, time2Color(currentDraw),
                      x, y, r);
    }
        break;
    case Sprite: {
        auto pal = next8Arg(cmd)&0x0F;
        auto sx = next16Arg(cmd), sy = next16Arg(cmd);
        auto x = next16Arg(cmd), y = next16Arg(cmd);
        auto w = next16Arg(cmd), h = next16Arg(cmd);

        gpuSprite(gpuQuadsBuffer, pal2Color(pal),
                  sx, sy, x, y, w, h);
        gpuSprite(gpuTQuadsBuffer, spriteTime2Color(pal, currentDraw),
                  sx, sy, x, y, w, h);
    }
        break;
    }

    currentDraw++;
}

void VideoMemory::draw() {
    // Renderiza polígonos e seus timings na GPU
    if (gpuTQuadsBuffer.hasContent())
        gpuTQuadsBuffer.draw(gpuRenderTimingQuads);
    if (gpuTTrisBuffer.hasContent())
        gpuTTrisBuffer.draw(gpuRenderTimingTris);
    if (gpuTLinesBuffer.hasContent())
        gpuTLinesBuffer.draw(gpuRenderTimingLines);
    if (gpuQuadsBuffer.hasContent())
        gpuQuadsBuffer.draw(gpuRenderTextureQuads);
    if (gpuTrisBuffer.hasContent())
        gpuTrisBuffer.draw(gpuRenderTextureTris);
    if (gpuLinesBuffer.hasContent())
        gpuLinesBuffer.draw(gpuRenderTextureLines);

    // Atualiza textura de timing da CPU
    cpuTiming.update(timingBuffer, w, h, 0, 0);
    // Atualiza resultado do render da CPU
    // TODO: Apenas atualizar se houver desenho feito na CPU
    cpuTexture.update(buffer, w/4, h, 0, 0);

    // Desenha as texturas combinadas da CPU e GPU
    framebuffer.draw(combineSpr,
                     sf::RenderStates(sf::BlendNone,
                                      sf::Transform::Identity,
                                      NULL,
                                      &combineShader));

    // Copia o resultado de volta para a RAM
    auto img = framebufferSpr.getTexture()->copyToImage();
    memcpy(buffer, img.getPixelsPtr(), w*h);

    if (colormap == NULL) {
        //startCapturing("screencap.gif");
    } else {
        captureFrame();
    }

    window.clear();
    // Desenha o framebuffer na tela, usando o shader para converter do
    // formato 1byte por pixel para cores RGBA nos pixels
    window.draw(framebufferSpr, &toRGBAShader);

    // Zera o timing dos draws
    currentDraw = 1;
    gpuTQuadsBuffer.clear();
    gpuQuadsBuffer.clear();
    gpuTTrisBuffer.clear();
    gpuTrisBuffer.clear();
    gpuTLinesBuffer.clear();
    gpuLinesBuffer.clear();
    gpuRenderTimingQuads.clear(sf::Color::Transparent);
    gpuRenderTimingTris.clear(sf::Color::Transparent);
    gpuRenderTimingLines.clear(sf::Color::Transparent);
    clearCpuTiming();
}

void VideoMemory::resize() {
    // Mantém o aspect ratio
    auto windowSize = window.getSize();
    if (windowSize.x > windowSize.y) {
        auto ratio = (float)windowSize.y/(float)windowSize.x*(float)w/(float)h;
        float spriteWidth = ratio*bytesPerPixel;
        framebufferSpr.setScale(spriteWidth, 1.0);
        framebufferSpr.setPosition((float)w*(1-ratio)/2.0, 0);
    }
    else {
        auto ratio = (float)windowSize.x/(float)windowSize.y*(float)h/(float)w;
        float spriteHeight = ratio;
        framebufferSpr.setScale(bytesPerPixel, spriteHeight);
        framebufferSpr.setPosition(0, (float)h*(1-ratio)/2.0);
    }
}

void VideoMemory::updatePalette(const uint8_t* palette) {
    paletteTex.update(palette, paletteTex.getSize().x, paletteTex.getSize().y, 0, 0);
}

void VideoMemory::updateSpriteSheet(const uint64_t p, const uint8_t* data, const uint64_t size) {
    // TODO: Atualizar apenas parte da imagem
    auto spriteSize = spriteTex.getSize();
    spriteTex.update(data, spriteSize.x, spriteSize.y, 0, 0);
}

// Escreve data (que tem size bytes) na posição p na memória de vídeo
uint64_t VideoMemory::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
    // Copia dados para RAM
    memcpy(buffer+p, data, size);
    drawCpuTiming(currentDraw, p, size);
    currentDraw++;
    return size;
}

uint64_t VideoMemory::read(const uint64_t p, uint8_t* data, const uint64_t size) {
    // Copia da memória de vídeo para o buffer do cliente
    memcpy(data, buffer+p, size);
	
    return size;
}

uint64_t VideoMemory::size() {
    return length;
}

uint64_t VideoMemory::addr() {
    return address;
}

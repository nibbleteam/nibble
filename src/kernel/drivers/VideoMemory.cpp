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

// Utiliza duas texturas adicionais com as
// informações de timing das duas texturas utilizadas para desenhar
// de forma que pode escolher apenas desenhar cada pixel
// daquela atualizada mais recentemente
const string VideoMemory::combineShaderFragment = R"(
// Converte um vetor de float pra um int de 4bytes
#define INT4BYTES(x) int(x.r*255.0)*256*256*256+int(x.g*255.0)*256*256+int(x.b*255.0)*256+int(x.a*255.0)

const float screen_w = 320.0;
// 4 canais na textura (RGBA)
const float bytes_per_pixel = 4.0;

// Primeira textura "esticada", desenhos da CPU
uniform sampler2D cpuTexture;
// Segunda textura, desenhos da GPU 
uniform sampler2D gpuTexture;
// Timing
uniform sampler2D cpuTiming;
uniform sampler2D gpuTiming;

void main()
{
    // Coordenadas no espaço da textura
    vec2 coord = vec2(gl_TexCoord[0].x, gl_TexCoord[0].y);
    // Alinha as coordenadas a 4 bytes
    float x = float(int(coord.x*screen_w)/int(bytes_per_pixel))*bytes_per_pixel/screen_w + 0.5/screen_w;

    // Constroi a saída 4 pixels por vez
    vec4 pixelCpu = texture2D(cpuTexture, vec2(coord.x, 1.0-coord.y));
    for (int i=0;i<int(bytes_per_pixel);i++) {
        vec4 pixelGpu = texture2D(gpuTexture, coord);
        vec4 cpuTimeV = texture2D(cpuTiming, vec2(x, 1.0-coord.y));
        vec4 gpuTimeV = texture2D(gpuTiming, coord);

        int cpuTime = INT4BYTES(cpuTimeV);
        int gpuTime = INT4BYTES(gpuTimeV);

        // Utiliza o buffer mais atualizado
        if (cpuTime >= gpuTime) {
            gl_FragColor[i] = pixelCpu[i];
        } else {
            gl_FragColor[i] = pixelGpu[i];
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

// Textura "comprimida" onde 1 pixel real são 4 pixels virtuais
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

    vec4 color = texture2D(palette, vec2(mod(source*2.0, 1.0), 0.5));

    // Não desenha pixels transparentes
    //if (color.a == 0.0)
    //    discard;

    gl_FragColor = vec4(color.rgb, 1.0);
}
)";

VideoMemory::VideoMemory(sf::RenderWindow &window,
                         const unsigned int w,
                         const unsigned int h,
                         const uint64_t addr):
	w(w), h(h), address(addr), length(w*h), window(window),
    colormap(NULL), currentDraw(0),
    gpuTimingBuffer(sf::Quads, 4), gpuQuadsBuffer(sf::Quads, 4) {
    // Tamanho da textura é 1/4 do tamanho da tela
    // uma vez que um pixel no sfml são quatro bytes
    // e no console é apenas um
	cpuTexture.create(w/bytesPerPixel, h);
	gpuRenderTexture.create(w, h);
    framebuffer.create(w/bytesPerPixel, h);
    // Timings das operações de desenho
    cpuTiming.create(w, h);
    gpuRenderTiming.create(w, h);

    // Texturas para ler as RenderTextures
	auto &gpuTexture = gpuRenderTexture.getTexture();
    auto &gpuTiming = gpuRenderTiming.getTexture();
    auto &framebufferTexture = framebuffer.getTexture();

    // Sprites para desenhar as RenderTextures
    // Framebuffer na tela inteira
	framebufferSpr = sf::Sprite(framebufferTexture);
    framebufferSpr.setScale(bytesPerPixel, 1);
    // combineSpr na área de cpuTexture, gpuTexture e framebuffer
	combineSpr = sf::Sprite(cpuTexture);
    combineSpr.setScale(1, 1);

    // Cria a textura da palleta
    paletteTex.create(128, 1);

    // Tenta carregar o shader, em caso de erro termina
    // uma vez que não será possível mostrar nada
    if (!combineShader.loadFromMemory(shaderVertex, combineShaderFragment)) {
        cout << "video " << "error loading combine shader" << endl;
        exit(1);
    }
    else {
        // Passa texuras de entrada
        combineShader.setUniform("cpuTexture", cpuTexture);
        combineShader.setUniform("gpuTexture", gpuTexture);

        // Passa texturas de timing
        combineShader.setUniform("cpuTiming", cpuTiming);
        combineShader.setUniform("gpuTiming", gpuTiming);
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

    const uint64_t videoRamSize = w*h;

    // Inicializa a memória
    buffer = new uint8_t[videoRamSize];
    for (unsigned int i=0;i<videoRamSize;i++) {
        buffer[i] = (i%8)+rand();
        //buffer[i] = 0;
    }
    timingBuffer = new uint8_t[bytesPerPixel*videoRamSize];

    // Inicializa com bytes não inicializados
    cpuTexture.update(buffer);
}

VideoMemory::~VideoMemory() {
    if (colormap != NULL) {
        stopCapturing();
    }

    delete timingBuffer;
    delete buffer;
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
        cerr << GifErrorString(error) << endl;
        return false;
    }

    gif = NULL;
    colormap = NULL;

    return true;
}

bool VideoMemory::captureFrame() {
    int error;
    char graphics[] {
        0, 2&0xFF, 2>>8, 0
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
}

ColorMapObject* VideoMemory::getColorMap() {
    // Tamanho da paleta do console
    uint64_t paletteSize = GPU::paletteLength*GPU::paletteAmount;
    // "Paleta" do GIF
    GifColorType colors[paletteSize];
    auto image = paletteTex.copyToImage();

    // Preenche o color map no formato do GIF
    // a partir do formato de paleta do console
    for (uint64_t i=0;i<paletteSize;i++) {
        sf::Color color = image.getPixel(i, 0);
        // Remove o alpha
        colors[i] = GifColorType {
            color.r, color.g, color.b
        };
    }

    colormap = GifMakeMapObject(paletteSize, colors);

    return colormap;
}

void VideoMemory::clearCpuTiming() {
    memset(timingBuffer, 0, w*h*4);
    cpuTiming.update(timingBuffer, w, h, 0, 0);
}

void VideoMemory::drawCpuTiming(uint32_t time, uint64_t p, uint64_t size) {
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

    uint64_t end = p+size*sizeof(time);

    // Copia os outros
    while (p+sizeof(time) < end) {
        memmove(timingBuffer+p+sizeof(time), timingBuffer+p, sizeof(time));

        p += sizeof(time);
    }
}

void VideoMemory::drawGpuTiming(uint32_t time,
                                const uint32_t x, const uint32_t y,
                                const uint32_t w, const uint32_t h) {
    // Converte o timing para uma cor
    sf::Color color = sf::Color {
        (uint8_t)(time>>24),
        (uint8_t)(time>>16),
        (uint8_t)(time>>8),
        (uint8_t)time
    };

    gpuTimingBuffer.add({
        sf::Vertex(sf::Vector2f(x, y), color),
        sf::Vertex(sf::Vector2f(x+w, y), color),
        sf::Vertex(sf::Vector2f(x+w, y+h), color),
        sf::Vertex(sf::Vector2f(x, y+h), color)
    });
}

void VideoMemory::drawGpuQuad(uint8_t color,
                              const uint16_t x, const uint16_t y,
                              const uint16_t w, const uint16_t h) {
    // Gera cor
    sf::Color sfcolor {color, color, color, color};

    gpuQuadsBuffer.add({
        sf::Vertex(sf::Vector2f(x, y), sfcolor),
        sf::Vertex(sf::Vector2f(x+w, y), sfcolor),
        sf::Vertex(sf::Vector2f(x+w, y+h), sfcolor),
        sf::Vertex(sf::Vector2f(x, y+h), sfcolor)
    });
}

void VideoMemory::execGpuCommand(uint8_t *cmd) {
    enum Commands {
        Clear = 0x00,
        FillRect
    };

    switch (*cmd) {
        case Clear:
            //cout << "gpu clear" << endl;
            break;
        case FillRect:
            // TODO: Inverter Y
            uint8_t color = cmd[1];
            uint16_t x = (uint16_t)cmd[2]<<8 | cmd[3];
            uint16_t y = (uint16_t)cmd[4]<<8 | cmd[5];
            uint16_t w = (uint16_t)cmd[6]<<8 | cmd[7];
            uint16_t h = (uint16_t)cmd[8]<<8 | cmd[9];

            drawGpuQuad(color, x, y, w, h);
            drawGpuTiming(currentDraw, x, y, w, h);

            break;
    }

    currentDraw++;
}

void VideoMemory::draw() {
    gpuTimingBuffer.draw(gpuRenderTiming);
    gpuQuadsBuffer.draw(gpuRenderTexture);

    // Atualiza textura de timing da CPU
    cpuTiming.update(timingBuffer, w, h, 0, 0);
    // Atualiza resultado do render da CPU
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
        startCapturing("screencap.gif");
    } else {
        captureFrame();
    }

	// Desenha o framebuffer na tela, usando o shader para converter do
    // formato 1byte por pixel para cores RGBA nos pixels
    window.draw(framebufferSpr, &toRGBAShader);

    // Zera o timing dos draws
    currentDraw = 1;
    gpuTimingBuffer.clear();
    gpuQuadsBuffer.clear();
    gpuRenderTiming.clear(sf::Color::Transparent);
    clearCpuTiming();
}

void VideoMemory::updatePalette(const uint8_t* palette) {
    paletteTex.update(palette, paletteTex.getSize().x, paletteTex.getSize().y, 0, 0);
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
    // Será necessário quando estivermos usando a GPU para desenhar
	//if (dirty) {
	//	// Carrega da GPU para a RAM
	//	img = tex->copyToImage();
	//	dirty = false;
	//}

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

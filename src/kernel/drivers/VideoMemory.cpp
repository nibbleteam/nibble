#define _USE_MATH_DEFINES
#include <cmath>
#include <SFML/OpenGL.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <iostream>
#include <cstring>

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

vec4 get_pix(int p) {
    float fp = float(p)/192.0;

    return texture2D(palette, vec2(fp+0.5/192.0, 0.5));
}

float color_routing2(float i) {
    int p = int(i*2.0*128.0);
    vec4 pix = get_pix(p/4+160);
    int byte = int(mod(float(p), 4.0));
    float source = 0.0;

    if (byte == 0) {
        source = pix.r;
    } else if (byte == 1) {
        source = pix.g;
    } else if (byte == 2) {
        source = pix.b;
    } else {
        source = pix.a;
    }

    return source;
}

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

    float rt2 = color_routing2(mod(source, 0.5));
    vec4 color = texture2D(palette, vec2(mod(rt2, 1.0)*4.0/3.0, 0.0));
    
    gl_FragColor = vec4(color.rgb, 1.0);
}
)";

VideoMemory::VideoMemory(sf::RenderWindow &window, const uint64_t addr):
    window(window), address(addr), colormap(NULL),
    screenScale(2), screenOffsetX(0), screenOffsetY(0) {
    // Tamanho da textura é 1/4 do tamanho da tela
    // uma vez que um pixel no sfml são quatro bytes
    // e no console é apenas um
    framebuffer.create(SCREEN_W/BYTES_PER_TEXEL, SCREEN_H);

    // Sprite para desenhar o framebuffer na tela
    framebufferSpr = sf::Sprite(framebuffer);
    framebufferSpr.setScale(BYTES_PER_TEXEL, 1);
    
    // Cria a textura da palleta
    paletteTex.create(GPU::paletteLength*GPU::paletteAmount+
                      (2*GPU::paletteLength*GPU::paletteAmount)/BYTES_PER_TEXEL, 1);
    
    // Shader de final de pipeline
    if (!toRGBAShader.loadFromMemory(shaderVertex, toRGBAShaderFragment)) {
        cout << "video " << "error loading toRGBA shader" << endl;
        exit(1);
    }
    else {
        // Passa textura do framebuffer e paleta
        toRGBAShader.setUniform("source", framebuffer);
        toRGBAShader.setUniform("palette", paletteTex);
    }

    // Inicializa a memória
    for (size_t i=0;i<VIDEO_MEMORY_LENGTH;i++) {
      buffer[i] = int(0xFF*sin(i/14))%0x10;
      //buffer[i] = (i%320+rand()%4)%8 == 0 ? (rand()%0x10) : (0);
    }

    // Inicializa com bytes não inicializados
    framebuffer.update(buffer);

    paletteData = nullptr;

    // Aspect-ratio correto
    resize();
}

VideoMemory::~VideoMemory() {
    if (colormap != NULL) {
        stopCapturing();
    }
}

string VideoMemory::name() {
	return "VIDEO";
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
    error = EGifPutScreenDesc(gif, SCREEN_W, SCREEN_H,
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

    error = EGifPutImageDesc(gif, 0, 0, SCREEN_W, SCREEN_H, false, NULL);
    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    error = EGifPutLine(gif, buffer, VIDEO_MEMORY_LENGTH);

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

// Render de Software
//

inline void VideoMemory::fixRectBounds(int16_t& x, int16_t& y,
                                       int16_t& w, int16_t& h,
                                       int16_t bw, int16_t bh) {
    if (x < 0) {
        w = max(w+x, 0);
        x = 0;
    }
    if (x+w >= bw) {
        w = bw-x;
    }

    if (y < 0) {
        h = max(h+y, 0);
        y = 0;
    }
    if (y+h >= bh) {
        h = bh-y;
    }
}

inline void VideoMemory::line(int16_t x1, int16_t y1,
                              int16_t x2, int16_t y2,
                              uint8_t color) {
    // Linha vertical
    if (x1 == x2) {
        if (y1 < y2) {
            const auto yf = y2+1;

            for (;y1<yf;y1++) {
                buffer[x1+y1*SCREEN_W] = color;
            }
        } else {
            const auto yf = y1+1;

            for (;y2<yf;y2++) {
                buffer[x1+y2*SCREEN_W] = color;
            }
        }
    }
    // Bresenham para inteiros
    else {
        const int16_t dx = abs(x1-x2);
        const int16_t dy = -abs(y1-y2);
        const int16_t yi = y1>y2 ? -1 : 1; 
        const int16_t xi = x1>x2 ? -1 : 1; 
        register int16_t D2;
        int16_t D = dx + dy;

        while (true) {
            if (!OUT_OF_BOUNDS(x1, y1)) {
                buffer[x1+y1*SCREEN_W] = color;
            }

            D2 = D<<1;

            if (D2 >= dy) {
                if (x1 == x2) break;

                D += dy;
                x1 += xi;
            }

            if (D2 <= dx) {
                if (y1 == y2) break;

                D += dx;
                y1 += yi;
            }
        }
    }
}

inline void VideoMemory::rect(int16_t x, int16_t y,
                              int16_t w, int16_t h,
                              uint8_t color) {
    fixRectBounds(x, y, w, h, SCREEN_W, SCREEN_H);

    auto ex = max(x+w-1, 0);
    auto ey = max(y+h-1, 0);

    line(x, y, ex, y, color);
    line(x, y, x, ey, color);
    line(ex, y, ex, ey, color);
    line(x, ey, ex, ey, color);
}

inline void VideoMemory::tri(int16_t x1, int16_t y1,
                             int16_t x2, int16_t y2,
                             int16_t x3, int16_t y3,
                             uint8_t color) {
    line(x1, y1, x2, y2, color);
    line(x2, y2, x3, y3, color);
    line(x3, y3, x1, y1, color);
}

inline void VideoMemory::quad(int16_t x1, int16_t y1,
                              int16_t x2, int16_t y2,
                              int16_t x3, int16_t y3,
                              int16_t x4, int16_t y4,
                              uint8_t color) {
    line(x1, y1, x2, y2, color);
    line(x2, y2, x3, y3, color);
    line(x3, y3, x4, y4, color);
    line(x4, y4, x1, y1, color);
}

inline void VideoMemory::circle(int16_t dx, int16_t dy, int16_t r, uint8_t color) {
    // Decisão inicial, começamos a desenhar de (r, 0):
    // midpoint(r, 0) => (r-0.5), (0+1)
    // P do midpoint => P(r-0.5, 1) = (r-0.5)²+1²-r² = r²-r+.5²+1-r² = (1+.25)-r = 1.25-r
    // Arredondando:
    int16_t d = 1-r;
    int16_t x = r, y = 0;

    while(x > y) {
        // Desenha o pixel anterior, replicado em 8
        if (!OUT_OF_BOUNDS(dx+x, dy+y)) {
            buffer[dx+x+(dy+y)*SCREEN_W] = color;
        }
        if (!OUT_OF_BOUNDS(dx-x, dy-y)) {
            buffer[dx-x+(dy-y)*SCREEN_W] = color;
        }
        if (!OUT_OF_BOUNDS(dx+x, dy-y)) {
            buffer[dx+x+(dy-y)*SCREEN_W] = color;
        }
        if (!OUT_OF_BOUNDS(dx-x, dy+y)) {
            buffer[dx-x+(dy+y)*SCREEN_W] = color;
        }
        if (!OUT_OF_BOUNDS(dx+y, dy+x)) {
            buffer[dx+y+(dy+x)*SCREEN_W] = color;
        }
        if (!OUT_OF_BOUNDS(dy-y, dy-x)) {
            buffer[dx-y+(dy-x)*SCREEN_W] = color;
        }
        if (!OUT_OF_BOUNDS(dy+y, dy-x)) {
            buffer[dx+y+(dy-x)*SCREEN_W] = color;
        }
        if (!OUT_OF_BOUNDS(dy-y, dy+x)) {
            buffer[dx-y+(dy+x)*SCREEN_W] = color;
        }

        // Escolhe entre (x-1, y+1) e (x, y+1)
        if (d <= 0) {
            d += ((y+1)<<1)+1;
        } else {
            d += ((y+1)<<1)-((x-1)<<1)+1;

            x--;
        }

        y++;
    }
}

inline void VideoMemory::rectFill(int16_t x, int16_t y,
                                  int16_t w, int16_t h,
                                  uint8_t color) {
    fixRectBounds(x, y, w, h, SCREEN_W, SCREEN_H);

    auto ptr = buffer+y*SCREEN_W+x;
    const auto ptrF = ptr+SCREEN_W*h;

    for(;ptr < ptrF;ptr+=SCREEN_W) {
        memset(ptr, color, w);
    }
}

inline void VideoMemory::triFill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t) { }
inline void VideoMemory::quadFill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t) { }

inline void VideoMemory::scanLine(int16_t x1, int16_t x2, int16_t y, uint8_t color) {
    if (!SCAN_OUT_OF_BOUNDS(x1, x2, y)) {
        x1 = max(x1, (int16_t)0);
        x2 = min(x2, (int16_t)(SCREEN_W-1));

        memset(buffer+x1+y*SCREEN_W, color, x2-x1+1);
    }
}

inline void VideoMemory::circleFill(int16_t dx, int16_t dy, int16_t r, uint8_t color) {
    int16_t d = 1-r;
    int16_t x = r, y = 0;

    while(x >= y) {
        scanLine(dx-x, dx+x, dy+y, color);
        scanLine(dx-x, dx+x, dy-y, color);
        scanLine(dx-y, dx+y, dy-x, color);
        scanLine(dx-y, dx+y, dy+x, color);

        if (d <= 0) {
            d += ((y+1)<<1)+1;
        } else {
            d += ((y+1)<<1)-((x-1)<<1)+1;

            x--;
        }

        y++;
    }
}

inline void VideoMemory::copyScanLine(uint8_t *dst, uint8_t *src, size_t bytes) {
    const auto end_src = src+bytes;

    while (src < end_src) {
        auto c = COLMAP1(*src++);

        // TODO: Não checar as cores, apenas mudar o operador?
        if (TRANSPARENT(c)) {
            dst++;
            continue;
        }

        *dst++ = c;
    }
}

inline void VideoMemory::sprite(int16_t sx, int16_t sy,
                                int16_t dx, int16_t dy,
                                int16_t w, int16_t h,
                                uint8_t pal) {
    fixRectBounds(dx, dy, w, h, SCREEN_W, SCREEN_H);
    fixRectBounds(sx, sy, w, h, SPRITESHEET_W, SPRITESHEET_H);

    auto src = spritesheet+sy*SPRITESHEET_W+sx;
    auto ptr = buffer+dy*SCREEN_W+dx;
    const auto ptrF = ptr+SCREEN_W*h;

    for(;ptr < ptrF;ptr+=SCREEN_W,src+=SPRITESHEET_W) {
        copyScanLine(ptr, src, w);
    }
}

inline uint8_t VideoMemory::next8Arg(uint8_t *&arg) {
    return *arg++;
}

inline int16_t VideoMemory::next16Arg(uint8_t *&arg) {
    int16_t value = int16_t(uint16_t(arg[0]&0b01111111)<<8 | uint16_t(arg[1])) * (arg[0]&0x80 ? -1 : 1);
    arg+=sizeof(int16_t);
    return value;
}

string VideoMemory::nextStrArg(uint8_t *&arg) {
    // Lê no máximo n caracteres
    static int limit = 31;
    string value;

    for (int i=0;i<limit;i++,arg++) {
        char c = (char)*arg;

        if (c == 0)
            break;

        value += c;
    }

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
        StartCapture,
        StopCapture
    };

    switch (*cmd++) {
        case Clear: {
            auto color = next8Arg(cmd);

            if (TRANSPARENT(color))
                break;

            memset(buffer, COLMAP1(color), VIDEO_MEMORY_LENGTH);
        } break;
        case FillRect: {
            auto color = next8Arg(cmd);
            auto x = next16Arg(cmd), y = next16Arg(cmd);
            auto w = next16Arg(cmd), h = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            rectFill(x, y, w, h, COLMAP1(color));
        } break;
        case FillQuad: {
            auto color = next8Arg(cmd);
            auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
            auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
            auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);
            auto x4 = next16Arg(cmd), y4 = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            quadFill(x1, y1, x2, y2, x3, y3, x4, y4, COLMAP1(color));
        } break;
        case FillTri: {
            auto color = next8Arg(cmd);
            auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
            auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
            auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            triFill(x1, y1, x2, y2, x3, y3, COLMAP1(color));
        } break;
        case Line: {
            auto color = next8Arg(cmd);
            auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
            auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            line(x1, y1, x2, y2, COLMAP1(color));
        } break;
        case Rect: {
            auto color = next8Arg(cmd);
            auto x = next16Arg(cmd), y = next16Arg(cmd);
            auto w = next16Arg(cmd), h = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            rect(x, y, w, h, COLMAP1(color));
        } break;
        case Quad: {
            auto color = next8Arg(cmd);
            auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
            auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
            auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);
            auto x4 = next16Arg(cmd), y4 = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            quad(x1, y1, x2, y2, x3, y3, x4, y4, COLMAP1(color));
        } break;
        case Tri: {
            auto color = next8Arg(cmd);
            auto x1 = next16Arg(cmd), y1 = next16Arg(cmd);
            auto x2 = next16Arg(cmd), y2 = next16Arg(cmd);
            auto x3 = next16Arg(cmd), y3 = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            tri(x1, y1, x2, y2, x3, y3, COLMAP1(color));
        } break;
        case Circle: {
            auto color = next8Arg(cmd);
            auto x = next16Arg(cmd), y = next16Arg(cmd);
            auto r = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            circle(x, y, r, COLMAP1(color));
        } break;
        case FillCircle: {
            auto color = next8Arg(cmd);
            auto x = next16Arg(cmd), y = next16Arg(cmd);
            auto r = next16Arg(cmd);

            if (TRANSPARENT(color))
                break;

            circleFill(x, y, r, COLMAP1(color));
        } break;
        case Sprite: {
            auto pal = next8Arg(cmd)&0x0F;
            auto sx = next16Arg(cmd), sy = next16Arg(cmd);
            auto x = next16Arg(cmd), y = next16Arg(cmd);
            auto w = next16Arg(cmd), h = next16Arg(cmd);

            sprite(sx, sy, x, y, w, h, pal);
        } break;
        //case StartCapture: {
        //    // TODO: Habilitar novamente
        //    if (colormap == NULL) {
        //        string filename = nextStrArg(cmd);
        //        startCapturing(filename);
        //    }
        //    break;
        //}
        //case StopCapture: {
        //    // TODO: Habilitar novamente
        //    if (colormap != NULL) {
        //        stopCapturing();
        //    }
        //} break;
    }
}

void VideoMemory::draw() {
    // Atualiza resultado do render da CPU
    framebuffer.update(buffer);

    // Grava a frame
    if (colormap != NULL) {
        captureFrame();
    }

    // Só limpa a tela se tivermos barras horizontais ou verticais
    if (screenOffsetX != 0 || screenOffsetY != 0) {
        window.clear();
    }

    // Desenha o framebuffer na tela, usando o shader para converter do
    // formato 1byte por pixel para cores RGBA nos pixels
    window.draw(framebufferSpr, &toRGBAShader);
}

void VideoMemory::resize() {
    // Mantém o aspect ratio
    auto windowSize = window.getSize();
    auto screenRatio = float(SCREEN_W)/float(SCREEN_H);

    if (windowSize.x > windowSize.y*screenRatio) {
        auto ratio = float(SCREEN_W)/float(SCREEN_H)*float(windowSize.y)/float(windowSize.x);
        float spriteWidth = ratio*BYTES_PER_TEXEL;

        screenScale = float(windowSize.y)/float(SCREEN_H);
        screenOffsetX = (float)SCREEN_W*(1-ratio)/2.0;
        screenOffsetY = 0;

        framebufferSpr.setScale(spriteWidth, 1.0);
        framebufferSpr.setPosition(screenOffsetX, 0);
    }
    else {
        auto ratio = (float)windowSize.x/(float)windowSize.y*(float)SCREEN_H/(float)SCREEN_W;
        float spriteHeight = ratio;

        screenScale = float(windowSize.x)/float(SCREEN_W);
        screenOffsetX = 0;
        screenOffsetY = (float)SCREEN_H*(1-ratio)/2.0;

        framebufferSpr.setScale(BYTES_PER_TEXEL, spriteHeight);
        framebufferSpr.setPosition(0, screenOffsetY);
    }
}

void VideoMemory::transformMouse(uint16_t &x, uint16_t &y) {
    auto windowSize = window.getSize();

    x /= screenScale;
    y /= screenScale;
    x -= (windowSize.x/screenScale-SCREEN_W)/2;
    y -= (windowSize.y/screenScale-SCREEN_H)/2;
}

void VideoMemory::updatePalette(const uint8_t* palette) {
    paletteData = palette;
    paletteTex.update(palette, paletteTex.getSize().x, paletteTex.getSize().y, 0, 0);
}

void VideoMemory::updateSpriteSheet(const uint64_t p, const uint8_t* data, const uint64_t size) {
    memcpy(spritesheet+p, data, size);
}

// Escreve data (que tem size bytes) na posição p na memória de vídeo
uint64_t VideoMemory::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
    // Copia dados para RAM
    memcpy(buffer+p, data, size);
    return size;
}

uint64_t VideoMemory::read(const uint64_t p, uint8_t* data, const uint64_t size) {
    // Copia da memória de vídeo para o buffer do cliente
    memcpy(data, buffer+p, size);
	
    return size;
}

uint64_t VideoMemory::size() {
    return VIDEO_MEMORY_LENGTH;
}

uint64_t VideoMemory::addr() {
    return address;
}

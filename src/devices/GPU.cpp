#include <algorithm>
#include <iostream>
#include <cstring>
#include <cmath>

#include <devices/GPU.hpp>

#include <Icon.hpp>

using namespace std;

GPU::GPU(Memory& memory):
    colormap(NULL), screenScale(GPU_DEFAULT_SCALING), screenOffsetX(0), screenOffsetY(0) {

    window = SDL_CreateWindow("Nibble",
                              SDL_WINDOWPOS_CENTERED,
                              SDL_WINDOWPOS_CENTERED,
                              GPU_VIDEO_WIDTH*GPU_DEFAULT_SCALING,
                              GPU_VIDEO_HEIGHT*GPU_DEFAULT_SCALING,
                              SDL_WINDOW_SHOWN);

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    commandMemory = memory.allocate(GPU_COMMAND_MEM_SIZE, "GPU Commands", [&] (Memory::AccessMode mode) {
        if (mode == Memory::ACCESS_WRITE) {
            this->execGpuCommand(this->commandMemory);
        }
    });

    paletteMemory = memory.allocate(GPU_PALETTE_MEM_SIZE, "GPU Palettes");
    videoMemory = memory.allocate(GPU_VIDEO_MEM_SIZE, "GPU Video Memory");

    // TODO
    // FPS Máximo 
    // window.setFramerateLimit(GPU_FRAMERATE);

    // TODO
    // Não gera múltiplos keypresses se a tecla ficar apertada
    // window.setKeyRepeatEnabled(false);

    // Não mostra o cursor
    SDL_ShowCursor(SDL_DISABLE);

    // TODO
    // Coloca o ícone
    // sf::Image Icon;
	// if (Icon.loadFromMemory(icon_png, icon_png_len)) {
    //    window.setIcon(icon_width, icon_height, Icon.getPixelsPtr());
    //}

    framebuffer = SDL_CreateTexture(renderer,
                                    SDL_PIXELFORMAT_ABGR8888,
                                    SDL_TEXTUREACCESS_STREAMING,
                                    GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT);

    framebufferSrc = SDL_Rect {0, 0, GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT};
    framebufferDst = SDL_Rect {0, 0,
                               int(GPU_VIDEO_WIDTH*screenScale),
                               int(GPU_VIDEO_HEIGHT*screenScale)};

    // Inicializa a memória
    for (size_t i=0;i<GPU_VIDEO_MEM_SIZE;i++) {
      //videoMemory[i] = int(0xFF*sin(i/14))%0x10;
      videoMemory[i] = (i%320+rand()%4)%8 == 0 ? (rand()%0x10) : (0);
    }

    // Aspect-ratio correto
    resize();

    //  - target -> video
    target = videoMemory;
    targetW = GPU_VIDEO_WIDTH;
    targetH = GPU_VIDEO_HEIGHT;
}

GPU::~GPU() {
    SDL_DestroyTexture(framebuffer);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
}

void GPU::startup() {
    uint8_t defaultPalette[] = {
        0x14, 0x0c, 0x1c, 0xFF,
        0x44, 0x24, 0x34, 0xFF,
        0x30, 0x34, 0x6d, 0xFF,
        0x4e, 0x4a, 0x4e, 0xFF,
        0x85, 0x4c, 0x30, 0xFF,
        0x34, 0x65, 0x24, 0xFF,
        0xd0, 0x46, 0x48, 0xFF,
        0x75, 0x71, 0x61, 0xFF,
        0x59, 0x7d, 0xce, 0xFF,
        0xd2, 0x7d, 0x2c, 0xFF,
        0x85, 0x95, 0xa1, 0xFF,
        0x6d, 0xaa, 0x2c, 0xFF,
        0xd2, 0xaa, 0x99, 0xFF,
        0x6d, 0xc2, 0xca, 0xFF,
        0xda, 0xd4, 0x5e, 0xFF,
        0xde, 0xee, 0xd6, 0xFF,
    };

    memcpy(paletteMemory, defaultPalette, sizeof(defaultPalette));

    for (size_t i=0;i<GPU_PALETTE_TBL1_SIZE;i++) {
        paletteMemory[i+GPU_PALETTE_SIZE*GPU_PALETTE_DEPTH] = i;
    }

    for (size_t i=0;i<GPU_PALETTE_TBL2_SIZE;i++) {
        paletteMemory[i+GPU_PALETTE_SIZE*GPU_PALETTE_DEPTH+GPU_PALETTE_TBL1_SIZE] = i;
    }
}

void GPU::draw() {
    // Atualiza a memória de vídeo
    void *data;
    int pitch;
    SDL_LockTexture(framebuffer, NULL, &data, &pitch);

    for (size_t i=0;i<GPU_VIDEO_MEM_SIZE;i++) {
        memcpy(((uint8_t*)data)+i*4, paletteMemory+(videoMemory[i]*4), 4);
    }

    SDL_UnlockTexture(framebuffer);

    // Grava a frame
    if (colormap != NULL) {
        captureFrame();
    }

    // Só limpa a tela se tivermos barras horizontais ou verticais
    if (screenOffsetX != 0 || screenOffsetY != 0) {
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
    }

    // Desenha o framebuffer na tela
    SDL_RenderCopy(renderer, framebuffer, &framebufferSrc, &framebufferDst);

    // Mostra o resultado na janela
    SDL_RenderPresent(renderer);
}

void GPU::resize() {
    /*
    TODO

    // Mantém o aspect ratio
    auto windowSize = window.getSize();
    auto screenRatio = float(GPU_VIDEO_WIDTH)/float(GPU_VIDEO_HEIGHT);

    if (windowSize.x > windowSize.y*screenRatio) {
        auto ratio = float(GPU_VIDEO_WIDTH)/float(GPU_VIDEO_HEIGHT)*float(windowSize.y)/float(windowSize.x);
        float spriteWidth = ratio*BYTES_PER_TEXEL;

        screenScale = float(windowSize.y)/float(GPU_VIDEO_HEIGHT);
        screenOffsetX = (float)GPU_VIDEO_WIDTH*(1-ratio)/2.0;
        screenOffsetY = 0;

        framebufferSpr.setScale(spriteWidth, 1.0);
        framebufferSpr.setPosition(screenOffsetX, 0);
    }
    else {
        auto ratio = (float)windowSize.x/(float)windowSize.y*(float)GPU_VIDEO_HEIGHT/(float)GPU_VIDEO_WIDTH;
        float spriteHeight = ratio;

        screenScale = float(windowSize.x)/float(GPU_VIDEO_WIDTH);
        screenOffsetX = 0;
        screenOffsetY = (float)GPU_VIDEO_HEIGHT*(1-ratio)/2.0;

        framebufferSpr.setScale(BYTES_PER_TEXEL, spriteHeight);
        framebufferSpr.setPosition(0, screenOffsetY);
    }
    */
}

void GPU::transformMouse(int16_t &x, int16_t &y) {
    x /= screenScale;
    y /= screenScale;

    // TODO
    //x -= (w/screenScale-GPU_VIDEO_WIDTH)/2;
    //y -= (h/screenScale-GPU_VIDEO_HEIGHT)/2;
}

/*
 * GIF
 */

bool GPU::startCapturing(const string& path) {
    int error;

    // Cria um colormap a partir da paleta
    colormap = getColorMap();

    // Abre um GIF pra salvar a tela
    gif = EGifOpenFileName(path.c_str(), false, &error);
    // Versão nova do GIF
    EGifSetGifVersion(gif, true);
    // Coonfigurações da screen
    error = EGifPutScreenDesc(gif,
                              GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT,
                              GPU_PALETTE_MEM_SIZE,
                              0,
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

bool GPU::stopCapturing() {
    int error;
    EGifCloseFile(gif, &error);
    if (error != GIF_OK) {
        return false;
    }

    gif = NULL;
    colormap = NULL;

    return true;
}

bool GPU::captureFrame() {
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

    error = EGifPutImageDesc(gif, 0, 0, GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT, false, NULL);
    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    error = EGifPutLine(gif, videoMemory, GPU_VIDEO_MEM_SIZE);

    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    return true;
}

ColorMapObject* GPU::getColorMap() {
    /*
    TODO

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
    */
}

// Render de Software
//

void GPU::fixRectBounds(int16_t& x, int16_t& y,
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

void GPU::line(int16_t x1, int16_t y1,
               int16_t x2, int16_t y2,
               uint8_t color) {
    // Bresenham para inteiros
    const int16_t dx = abs(x1-x2);
    const int16_t dy = -abs(y1-y2);
    const int16_t yi = y1>y2 ? -1 : 1; 
    const int16_t xi = x1>x2 ? -1 : 1; 
    register int16_t D2;
    int16_t D = dx + dy;

    while (true) {
        if (!OUT_OF_BOUNDS(x1, y1)) {
            target[x1+y1*targetW] = color;
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

void GPU::rect(int16_t x, int16_t y,
               int16_t w, int16_t h,
               uint8_t color) {
    fixRectBounds(x, y, w, h, targetW, targetH);

    auto ex = max(x+w-1, 0);
    auto ey = max(y+h-1, 0);

    line(x, y, ex, y, color);
    line(x, y, x, ey, color);
    line(ex, y, ex, ey, color);
    line(x, ey, ex, ey, color);
}

void GPU::tri(int16_t x1, int16_t y1,
              int16_t x2, int16_t y2,
              int16_t x3, int16_t y3,
              uint8_t color) {
    line(x1, y1, x2, y2, color);
    line(x2, y2, x3, y3, color);
    line(x3, y3, x1, y1, color);
}

void GPU::quad(int16_t x1, int16_t y1,
               int16_t x2, int16_t y2,
               int16_t x3, int16_t y3,
               int16_t x4, int16_t y4,
               uint8_t color) {
    line(x1, y1, x2, y2, color);
    line(x2, y2, x3, y3, color);
    line(x3, y3, x4, y4, color);
    line(x4, y4, x1, y1, color);
}

void GPU::circle(int16_t dx, int16_t dy, int16_t r, uint8_t color) {
    // Decisão inicial, começamos a desenhar de (r, 0):
    // midpoint(r, 0) => (r-0.5), (0+1)
    // P do midpoint => P(r-0.5, 1) = (r-0.5)²+1²-r² = r²-r+.5²+1-r² = (1+.25)-r = 1.25-r
    // Arredondando:
    int16_t d = 1-abs(r);
    int16_t x = abs(r), y = 0;

    while(x >= y) {
        // Desenha o pixel anterior, replicado em 8
        if (!OUT_OF_BOUNDS(dx+x, dy+y)) {
            target[dx+x+(dy+y)*targetW] = color;
        }
        if (!OUT_OF_BOUNDS(dx-x, dy-y)) {
            target[dx-x+(dy-y)*targetW] = color;
        }
        if (!OUT_OF_BOUNDS(dx+x, dy-y)) {
            target[dx+x+(dy-y)*targetW] = color;
        }
        if (!OUT_OF_BOUNDS(dx-x, dy+y)) {
            target[dx-x+(dy+y)*targetW] = color;
        }
        if (!OUT_OF_BOUNDS(dx+y, dy+x)) {
            target[dx+y+(dy+x)*targetW] = color;
        }
        if (!OUT_OF_BOUNDS(dx-y, dy-x)) {
            target[dx-y+(dy-x)*targetW] = color;
        }
        if (!OUT_OF_BOUNDS(dx+y, dy-x)) {
            target[dx+y+(dy-x)*targetW] = color;
        }
        if (!OUT_OF_BOUNDS(dx-y, dy+x)) {
            target[dx-y+(dy+x)*targetW] = color;
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

void GPU::rectFill(int16_t x, int16_t y,
                   int16_t w, int16_t h,
                   uint8_t color) {
    if (w < 0) {
        x += w;
        w = -w;
    }

    if (h < 0) {
        y += h;
        h = -h;
    }

    const auto fy = y+h;

    for (;y<fy;y++) {
        scanLine(x, x+w-1, y, color);
    }
}

void GPU::orderedTriFill(int16_t x1, int16_t y1,
                         int16_t x2, int16_t y2,
                         int16_t x3, int16_t y3,
                         uint8_t color) {
    // Casos especiais
    if ((x1 == x2 && x2 == x3) ||(y1 == y2 && y2 == y3)) {
        tri(x1, y1, x2, y2, x3, y3, color);
        return;
    }

    // Linha de x1, y1 -> x3, y3    (a)
    // Linha de x1, y1 -> x2, y2    (b)

    const int16_t dxa = abs(x1-x3);
    const int16_t dya = -abs(y1-y3);
    const int16_t yia = y1>y3 ? -1 : 1; 
    const int16_t xia = x1>x3 ? -1 : 1; 
    register int16_t D2a;
    int16_t Da = dxa + dya;

    int16_t dxb = abs(x1-x2);
    int16_t dyb = -abs(y1-y2);
    int16_t yib = y1>y2 ? -1 : 1; 
    int16_t xib = x1>x2 ? -1 : 1; 
    register int16_t D2b;
    int16_t Db = dxb + dyb;

    int16_t x1b = x1, y1b = y1;

    bool firstLine = true;

    while (true) {
start:
        if (x1 < x1b) {
            scanLine(x1, x1b, y1, color);
        } else {
            scanLine(x1b, x1, y1, color);
        }

        do {
            const auto cmpA = y1 <= y1b;

            if (y1 >= y1b) {
                D2b = Db<<1;
                D2a = Da<<1;

                if (D2b >= dyb) {
                    if (x1b == x2 && firstLine) goto prepareSecondLine;

                    Db += dyb;
                    x1b += xib;
                }

                if (D2b <= dxb) {
                    if (y1b == y2 && firstLine) goto prepareSecondLine;

                    Db += dxb;
                    y1b += yib;
                }

            }
            
            if (cmpA) {
                D2a = Da<<1;

                if (D2a >= dya) {
                    if (x1 == x3) return;

                    Da += dya;
                    x1 += xia;
                }

                if (D2a <= dxa) {
                    if (y1 == y3) return;

                    Da += dxa;
                    y1 += yia;
                }
            }
        } while (y1 != y1b);
    }
prepareSecondLine:
    firstLine = false;

    dxb = abs(x2-x3);
    dyb = -abs(y2-y3);
    yib = y2>y3 ? -1 : 1; 
    xib = x2>x3 ? -1 : 1; 
    Db = dxb + dyb;

    x1b = x2; y1b = y2;

    goto start;
}

void GPU::triFill(int16_t x1, int16_t y1,
                  int16_t x2, int16_t y2,
                  int16_t x3, int16_t y3,
                  uint8_t color) {
    if (y1 <= y2 && y2 <= y3) {
        orderedTriFill(x1, y1, x2, y2, x3, y3, color);
    } else if (y1 <= y3 && y3 <= y2) {
        orderedTriFill(x1, y1, x3, y3, x2, y2, color);
    }else if (y3 <= y1 && y1 <= y2) {
        orderedTriFill(x3, y3, x1, y1, x2, y2, color);
    } else if (y3 <= y2 && y2 <= y1) {
        orderedTriFill(x3, y3, x2, y2, x1, y1, color);
    }else if (y2 <= y1 && y1 <= y3) {
        orderedTriFill(x2, y2, x1, y1, x3, y3, color);
    } else if (y2 <= y3 && y3 <= y1) {
        orderedTriFill(x2, y2, x3, y3, x1, y1, color);
    }
}

void GPU::quadFill(int16_t x1, int16_t y1,
                   int16_t x2, int16_t y2,
                   int16_t x3, int16_t y3,
                   int16_t x4, int16_t y4,
                   uint8_t color) {
    const int16_t miny = min<int16_t>({y1, y2, y3, y4});
    const int16_t maxy = max<int16_t>({y1, y2, y3, y4});

    if ((miny == y1 && maxy == y2) || (miny == y2 && maxy == y1)) {
        triFill(x1, y1, x3, y3, x4, y4, color);
        triFill(x2, y2, x3, y3, x4, y4, color);
    } else if ((miny == y1 && maxy == y3) || (miny == y3 && maxy == y1)) {
        triFill(x1, y1, x2, y2, x4, y4, color);
        triFill(x3, y3, x2, y2, x4, y4, color);
    } else if ((miny == y1 && maxy == y4) || (miny == y4 && maxy == y1)) {
        triFill(x1, y1, x2, y2, x3, y3, color);
        triFill(x4, y4, x2, y2, x3, y3, color);
    } else if ((miny == y2 && maxy == y3) || (miny == y3 && maxy == y2)) {
        triFill(x2, y2, x1, y1, x4, y4, color);
        triFill(x3, y3, x1, y1, x4, y4, color);
    } else if ((miny == y2 && maxy == y4) || (miny == y4 && maxy == y2)) {
        triFill(x2, y2, x1, y1, x3, y3, color);
        triFill(x4, y4, x1, y1, x3, y3, color);
    } else if ((miny == y3 && maxy == y4) || (miny == y4 && maxy == y3)) {
        triFill(x3, y3, x1, y1, x2, y2, color);
        triFill(x4, y4, x1, y1, x2, y2, color);
    }
}

void GPU::scanLine(int16_t x1, int16_t x2, int16_t y, uint8_t color) {
    if (x2 >= x1) {
        if (!SCAN_OUT_OF_BOUNDS(x1, x2, y)) {
            x1 = max(x1, (int16_t)0);
            x2 = min(x2, (int16_t)(targetW-1));

            memset(target+x1+y*targetW, color, x2-x1+1);
        }
    }
}

void GPU::circleFill(int16_t dx, int16_t dy, int16_t r, uint8_t color) {
    int16_t d = 1-abs(r);
    int16_t x = abs(r), y = 0;

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

void GPU::copyScanLine(uint8_t *dst, uint8_t *src, size_t bytes, uint8_t pal) {
    const auto end_src = src+bytes;

    while (src < end_src) {
        auto c = COLMAP1(((*src++) + (pal<<4)));

        // TODO: Não checar as cores, apenas mudar o operador?
        if (TRANSPARENT(c)) {
            dst++;
            continue;
        }

        *dst++ = c;
    }
}

void GPU::sprite(int16_t sx, int16_t sy,
                 int16_t dx, int16_t dy,
                 int16_t w, int16_t h,
                 uint8_t pal) {
    if (dy >= targetH || dx >= targetW) {
        return;
    }

    if (dx < 0) {
        w = max(w+dx, 0);
        sx -= dx;
        dx = 0;
    }

    if (dy < 0) {
        h = max(h+dy, 0);
        sy -= dy;
        dy = 0;
    }

    if (dy+h >= targetH) {
        h = targetH-dy;
    }

    if (dx+w >= targetW) {
        w = targetW-dx;
    }

    if (sx < 0) {
        w = max(w+sx, 0);
        sx = 0;
    }

    if (sy < 0) {
        h = max(h+sy, 0);
        dy = 0;
    }

    auto src = source+sy*sourceW+sx;
    auto ptr = target+dy*targetW+dx;
    const auto ptrF = ptr+targetW*h;

    for(;ptr < ptrF;ptr+=targetW,src+=sourceW) {
        copyScanLine(ptr, src, w, pal);
    }
}

uint8_t GPU::next8Arg(uint8_t *&arg) {
    return *arg++;
}

int16_t GPU::next16Arg(uint8_t *&arg) {
    int16_t value = int16_t(uint16_t(arg[0]&0b01111111)<<8 | uint16_t(arg[1])) * (arg[0]&0x80 ? -1 : 1);
    arg+=sizeof(int16_t);
    return value;
}

string GPU::nextStrArg(uint8_t *&arg) {
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

void GPU::execGpuCommand(uint8_t *cmd) {
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

            memset(videoMemory, COLMAP1(color), GPU_VIDEO_MEM_SIZE);
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
        case StartCapture: {
            if (colormap == NULL) {
                string filename = nextStrArg(cmd);
                startCapturing(filename);
            }
            break;
        }
        case StopCapture: {
            if (colormap != NULL) {
                stopCapturing();
            }
        } break;
    }
}

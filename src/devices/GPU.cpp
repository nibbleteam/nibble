#include <algorithm>
#include <iostream>
#include <cstring>
#include <cmath>

#include <png.h>

#include <devices/GPU.hpp>

#include <Icon.hpp>

using namespace std;

GPU::GPU(Memory& memory, const bool fullscreen_startup):
    target_clip_start_x(0), target_clip_start_y(0),
    target_clip_end_x(GPU_VIDEO_WIDTH), target_clip_end_y(GPU_VIDEO_HEIGHT),
    is_fullscreen(fullscreen_startup),
    cycle(0), h264(nullptr),
    colormap(nullptr), screen_scale(GPU_DEFAULT_SCALING), screen_offset_x(0), screen_offset_y(0) {

    window = SDL_CreateWindow("nibble",
                              SDL_WINDOWPOS_CENTERED,
                              SDL_WINDOWPOS_CENTERED,
                              GPU_VIDEO_WIDTH*GPU_DEFAULT_SCALING,
                              GPU_VIDEO_HEIGHT*GPU_DEFAULT_SCALING,
                              SDL_WINDOW_SHOWN | (is_fullscreen? SDL_WINDOW_FULLSCREEN : 0) | SDL_WINDOW_RESIZABLE );

    renderer = SDL_CreateRenderer(window, -1, 0);
    //renderer = SDL_CreateSoftwareRenderer(SDL_GetWindowSurface(window));

    palette_memory = memory.allocate(GPU_PALETTE_MEM_SIZE, "GPU Palettes");
    video_memory = memory.allocate(GPU_VIDEO_MEM_SIZE, "GPU Video Memory");

    // Não mostra o cursor
    SDL_ShowCursor(SDL_DISABLE);

    uint8_t *pixels;
    auto icon_surface = icon_to_surface(pixels);

    SDL_SetWindowIcon(window, icon_surface);

    SDL_FreeSurface(icon_surface);
    delete pixels;

    framebuffer = SDL_CreateTexture(renderer,
                                    SDL_PIXELFORMAT_ABGR8888,
                                    SDL_TEXTUREACCESS_STREAMING,
                                    GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT);

    framebuffer_src = SDL_Rect {0, 0, GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT};
    framebuffer_dst = SDL_Rect {0, 0,
                               int(GPU_VIDEO_WIDTH*screen_scale),
                               int(GPU_VIDEO_HEIGHT*screen_scale)};
}

GPU::~GPU() {
    free_cursors();

    SDL_DestroyTexture(framebuffer);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
}

void GPU::startup() {
    // DB16
    uint8_t default_palette[] = {
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

    memcpy(palette_memory, default_palette, sizeof(default_palette));

    // Inicializa roteamento de paletas
    for (size_t i=0;i<GPU_PALETTE_TBL1_SIZE;i++) {
        palette_memory[i+GPU_PALETTE_SIZE*GPU_PALETTE_DEPTH] = i;
    }

    for (size_t i=0;i<GPU_PALETTE_TBL2_SIZE;i++) {
        palette_memory[i+GPU_PALETTE_SIZE*GPU_PALETTE_DEPTH+GPU_PALETTE_TBL1_SIZE] = i;
    }

    for (size_t i=0;i<GPU_VIDEO_MEM_SIZE;i++) {
        //video_memory[i] = int(0xFF*sin(i/14))%0x10;
        //video_memory[i] = ((i%320+rand()%2)%16 < 15  && i%2 == 0 ? (rand()%0x10) : (0));
        //video_memory[i] = min(((i/17)%0x10*(i/15)%0x08+cycle*2), (size_t)0x11);

        video_memory[i] = (i/20 + i/400/4)%0x10;
    }

    // Aspect-ratio correto
    resize();

    //  - target -> video
    target = video_memory;
    target_w = GPU_VIDEO_WIDTH;
    target_h = GPU_VIDEO_HEIGHT;

    cycle = 0;
}

void GPU::paint_boot_animation() {
    for (size_t i=0;i<GPU_VIDEO_MEM_SIZE/4;i++) {
        if (rand()%3 == 0) {
            video_memory[i*4+0] = 0;
            video_memory[i*4+1] = 0;
            video_memory[i*4+2] = 0;
            video_memory[i*4+3] = 0;
        }
    }
}

void GPU::draw() {
    if (cycle <= BOOT_CYCLES) {
        paint_boot_animation();
    }
    cycle++;

    // Atualiza a memória de vídeo
    void *data;
    int pitch;
    SDL_LockTexture(framebuffer, NULL, &data, &pitch);

    for (size_t i=0;i<GPU_VIDEO_MEM_SIZE;i++) {
        memcpy(((uint8_t*)data)+i*4,
                palette_memory+(COLMAP2(video_memory[i])*4), 4);
    }

    // Grava a frame
    if (h264) {
        h264->capture_frame((const uint8_t*)data);
    }

    SDL_UnlockTexture(framebuffer);


    // Só limpa a tela se tivermos barras horizontais ou verticais
    if (screen_offset_x != 0 || screen_offset_y != 0) {
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
    }

    // Desenha o framebuffer na tela
    SDL_RenderCopy(renderer, framebuffer, &framebuffer_src, &framebuffer_dst);

    // Mostra o resultado na janela
    SDL_RenderPresent(renderer);
}

void GPU::fullscreen(const bool fullscreen) {
    SDL_SetWindowFullscreen(window, fullscreen? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);

    is_fullscreen = fullscreen;
}

void GPU::toggle_fullscreen() {
    fullscreen(!is_fullscreen);
}

void GPU::resize() {
    int w, h;

    SDL_GetWindowSize(window, &w, &h);

    auto window_ratio = float(w)/float(h);
    auto video_ratio = float(GPU_VIDEO_WIDTH)/float(GPU_VIDEO_HEIGHT);

    if (window_ratio > video_ratio) {
        screen_scale = float(h)/float(GPU_VIDEO_HEIGHT);
        screen_offset_x = (w-screen_scale*float(GPU_VIDEO_WIDTH))/2.0;

        screen_offset_y = 0;
    } else {
        screen_scale = float(w)/float(GPU_VIDEO_WIDTH);
        screen_offset_y = (h-screen_scale*float(GPU_VIDEO_HEIGHT))/2.0;

        screen_offset_x = 0;
    }

    framebuffer_dst = SDL_Rect {int(screen_offset_x), int(screen_offset_y),
                               int(GPU_VIDEO_WIDTH*screen_scale),
                               int(GPU_VIDEO_HEIGHT*screen_scale)};

    free_cursors();
}

void GPU::transform_mouse(int16_t &x, int16_t &y) {
    x -= screen_offset_x;
    y -= screen_offset_y;

    x /= screen_scale;
    y /= screen_scale;

    x = max(min(x, int16_t(GPU_VIDEO_WIDTH)), int16_t(0));
    y = max(min(y, int16_t(GPU_VIDEO_HEIGHT)), int16_t(0));
}

/*
 * GIF
 */

bool GPU::start_capturing(const string& path) {
    // int error;

    // // Cria um colormap a partir da paleta
    // colormap = get_color_map();

    // // Abre um GIF pra salvar a tela
    // gif = EGifOpenFileName(path.c_str(), false, &error);
    // // Versão nova do GIF
    // EGifSetGifVersion(gif, true);
    // // Coonfigurações da screen
    // error = EGifPutScreenDesc(gif,
    //                           GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT,
    //                           GPU_PALETTE_MEM_SIZE,
    //                           0,
    //                           colormap);

    // // Limpa a paleta que foi escrita
    // GifFreeMapObject(colormap);

    // if (error != GIF_OK) {
    //     cerr << GifErrorString(error) << endl;
    //     return false;
    // }

    // char loop[] {
    //     0x01, 0x00, 0x00
    // };

    // error = 0;
    // error |= EGifPutExtensionLeader(gif, APPLICATION_EXT_FUNC_CODE);
    // error |= EGifPutExtensionBlock(gif, 0x0b, "NETSCAPE2.0");
    // error |= EGifPutExtensionBlock(gif, 0x03, loop);
    // error |= EGifPutExtensionTrailer(gif);

    // if (error != GIF_OK) {
    //     cerr << GifErrorString(error) << endl;
    //     return false;
    // }

    h264 = new VideoEncoder(Path(path));

    return true;
}

bool GPU::stop_capturing() {
    // int error;

    // EGifCloseFile(gif, &error);

    // gif = nullptr;
    // colormap = nullptr;

    // if (error != GIF_OK) {
    //     return false;
    // }

    delete h264;
    h264 = nullptr;

    return true;
}

bool GPU::capture_frame() {
    //int error;
    //char graphics[] {
    //    0, 4&0xFF, 4>>8, 0
    //};

    //error = EGifPutExtension(
    //    gif,
    //    GRAPHICS_EXT_FUNC_CODE,
    //    sizeof(graphics),
    //    &graphics
    //);

    //if (error != GIF_OK) {
    //    cerr << GifErrorString(error) << endl;
    //    return false;
    //}

    //error = EGifPutImageDesc(gif, 0, 0, GPU_VIDEO_WIDTH, GPU_VIDEO_HEIGHT, false, NULL);
    //if (error != GIF_OK) {
    //    cerr << GifErrorString(error) << endl;
    //    return false;
    //}

    //error = EGifPutLine(gif, video_memory, GPU_VIDEO_MEM_SIZE);

    //if (error != GIF_OK) {
    //    cerr << GifErrorString(error) << endl;
    //    return false;
    //}
    //
    return true;
}

ColorMapObject* GPU::get_color_map() {
    // "Paleta" do GIF
    GifColorType colors[GPU_PALETTE_SIZE];

    // Preenche o color map no formato do GIF
    // a partir do formato de paleta do console
    for (uint64_t i=0;i<GPU_PALETTE_SIZE;i++) {
        // Remove o alpha
        colors[i] = GifColorType {
            palette_memory[i*GPU_PALETTE_DEPTH+0],
            palette_memory[i*GPU_PALETTE_DEPTH+1],
            palette_memory[i*GPU_PALETTE_DEPTH+2]
        };
    }

    colormap = GifMakeMapObject(GPU_PALETTE_SIZE, colors);

    return colormap;
}

//
// Render de Software
//

uint8_t GPU::find_point_region(int16_t x, int16_t y) const {
    return (x < target_clip_start_x) | (x > target_clip_end_x)<<1 | (y < target_clip_start_y)<<2 | (y > target_clip_end_y)<<3;
}

void GPU::fix_line_bounds(int16_t& x1, int16_t& y1, int16_t& x2, int16_t& y2) const {
    uint8_t start = find_point_region(x1, y1);
    uint8_t end = find_point_region(x2, y2);

    uint8_t region;
    int16_t x, y;

    for (;;) {
        // Dentro da tela
        if (!(start + end)) {
            return;
        }

        // Fora da tela
        if (start & end) {
            return;
        }

        region = start? start : end;

        if (region & 1) {
            y = y1+(target_clip_start_x-x1)*(y2-y1)/float(x2-x1);
            x = target_clip_start_x;
        } else if (region & 2) {
            y = y1+(target_clip_end_x-x1)*(y2-y1)/float(x2-x1);
            x = target_clip_end_x;
        } else if (region & 4) {
            x = x1+(target_clip_start_y-y1)*(x2-x1)/float(y2-y1);
            y = target_clip_start_y;
        } else if (region & 8) {
            x = x1+(target_clip_end_y-y1)*(x2-x1)/float(y2-y1);
            y = target_clip_end_y;
        }

        if (region == start) {
            x1 = x; y1 = y;

            start = find_point_region(x1, y1);
        } else {
            x2 = x; y2 = y;

            end = find_point_region(x2, y2);
        }
    }
}

void GPU::fix_rect_bounds(int16_t& x, int16_t& y,
                          int16_t& w, int16_t& h,
                          int16_t bw, int16_t bh) const {
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
    if (TRANSPARENT(color))
        return;

    // Algorítmo Cohen-Sutherland de clipping
    fix_line_bounds(x1, y1, x2, y2);

    // Bresenham para inteiros
    const int16_t dx = abs(x1-x2);
    const int16_t dy = -abs(y1-y2);
    const int16_t yi = y1>y2 ? -1 : 1; 
    const int16_t xi = x1>x2 ? -1 : 1; 
    int16_t D2;
    int16_t D = dx + dy;

    while (true) {
        if (!OUT_OF_BOUNDS(x1, y1)) {
            target[x1+y1*target_w] = color;
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
    if (TRANSPARENT(color))
        return;

    fix_rect_bounds(x, y, w, h, target_w, target_h);

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
    if (TRANSPARENT(color))
        return;

    line(x1, y1, x2, y2, color);
    line(x2, y2, x3, y3, color);
    line(x3, y3, x1, y1, color);
}

void GPU::quad(int16_t x1, int16_t y1,
               int16_t x2, int16_t y2,
               int16_t x3, int16_t y3,
               int16_t x4, int16_t y4,
               uint8_t color) {
    if (TRANSPARENT(color))
        return;

    line(x1, y1, x2, y2, color);
    line(x2, y2, x3, y3, color);
    line(x3, y3, x4, y4, color);
    line(x4, y4, x1, y1, color);
}

void GPU::circle(int16_t dx, int16_t dy, int16_t r, uint8_t color) {
    if (TRANSPARENT(color))
        return;

    // Decisão inicial, começamos a desenhar de (r, 0):
    // midpoint(r, 0) => (r-0.5), (0+1)
    // P do midpoint => P(r-0.5, 1) = (r-0.5)²+1²-r² = r²-r+.5²+1-r² = (1+.25)-r = 1.25-r
    // Arredondando:
    int16_t d = 1-abs(r);
    int16_t x = abs(r), y = 0;

    while(x >= y) {
        // Desenha o pixel anterior, replicado em 8
        if (!OUT_OF_BOUNDS(dx+x, dy+y)) {
            target[dx+x+(dy+y)*target_w] = color;
        }
        if (!OUT_OF_BOUNDS(dx-x, dy-y)) {
            target[dx-x+(dy-y)*target_w] = color;
        }
        if (!OUT_OF_BOUNDS(dx+x, dy-y)) {
            target[dx+x+(dy-y)*target_w] = color;
        }
        if (!OUT_OF_BOUNDS(dx-x, dy+y)) {
            target[dx-x+(dy+y)*target_w] = color;
        }
        if (!OUT_OF_BOUNDS(dx+y, dy+x)) {
            target[dx+y+(dy+x)*target_w] = color;
        }
        if (!OUT_OF_BOUNDS(dx-y, dy-x)) {
            target[dx-y+(dy-x)*target_w] = color;
        }
        if (!OUT_OF_BOUNDS(dx+y, dy-x)) {
            target[dx+y+(dy-x)*target_w] = color;
        }
        if (!OUT_OF_BOUNDS(dx-y, dy+x)) {
            target[dx-y+(dy+x)*target_w] = color;
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

void GPU::rect_fill(int16_t x, int16_t y,
                    int16_t w, int16_t h,
                    uint8_t color) {
    if (TRANSPARENT(color))
        return;

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
        scan_line(x, x+w-1, y, color);
    }
}

void GPU::ordered_tri_fill(int16_t x1, int16_t y1,
                           int16_t x2, int16_t y2,
                           int16_t x3, int16_t y3,
                           uint8_t color) {
    // Casos especiais
    if ((x1 == x2 && x2 == x3) || (y1 == y2 && y2 == y3)) {
        tri(x1, y1, x2, y2, x3, y3, color);
        return;
    }

    // Linha de x1, y1 -> x3, y3    (a)
    // Linha de x1, y1 -> x2, y2    (b)

    const int16_t dxa = abs(x1-x3);
    const int16_t dya = -abs(y1-y3);
    const int16_t yia = y1>y3 ? -1 : 1;
    const int16_t xia = x1>x3 ? -1 : 1;
    int16_t D2a;
    int16_t Da = dxa + dya;

    int16_t dxb = abs(x1-x2);
    int16_t dyb = -abs(y1-y2);
    int16_t yib = y1>y2 ? -1 : 1;
    int16_t xib = x1>x2 ? -1 : 1;
    int16_t D2b;
    int16_t Db = dxb + dyb;

    int16_t x1b = x1, y1b = y1;

    bool first_line = true;

    while (true) {
start:
        if (x1 < x1b) {
            scan_line(x1, x1b, y1, color);
        } else {
            scan_line(x1b, x1, y1, color);
        }

        do {
            const auto cmp_a = y1 <= y1b;

            if (y1 >= y1b) {
                D2b = Db<<1;

                if (D2b >= dyb) {
                    if (x1b == x2 && first_line) goto prepare_second_line;

                    Db += dyb;
                    x1b += xib;
                }

                if (D2b <= dxb) {
                    if (y1 == y1b) {
                    }

                    if (y1b == y2 && first_line) goto prepare_second_line;

                    Db += dxb;
                    y1b += yib;
                }

            }

            if (cmp_a) {
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
prepare_second_line:
    first_line = false;

    dxb = abs(x2-x3);
    dyb = -abs(y2-y3);
    yib = y2>y3 ? -1 : 1;
    xib = x2>x3 ? -1 : 1;
    Db = dxb + dyb;

    x1b = x2; y1b = y2;

    goto start;
}

void GPU::tri_fill(int16_t x1, int16_t y1,
                   int16_t x2, int16_t y2,
                   int16_t x3, int16_t y3,
                   uint8_t color) {
    if (TRANSPARENT(color))
        return;

    if (y1 <= y2 && y2 <= y3) {
        ordered_tri_fill(x1, y1, x2, y2, x3, y3, color);
    } else if (y1 <= y3 && y3 <= y2) {
        ordered_tri_fill(x1, y1, x3, y3, x2, y2, color);
    } else if (y3 <= y1 && y1 <= y2) {
        ordered_tri_fill(x3, y3, x1, y1, x2, y2, color);
    } else if (y3 <= y2 && y2 <= y1) {
        ordered_tri_fill(x3, y3, x2, y2, x1, y1, color);
    } else if (y2 <= y1 && y1 <= y3) {
        ordered_tri_fill(x2, y2, x1, y1, x3, y3, color);
    } else if (y2 <= y3 && y3 <= y1) {
        ordered_tri_fill(x2, y2, x3, y3, x1, y1, color);
    }
}

void GPU::quad_fill(int16_t x1, int16_t y1,
                    int16_t x2, int16_t y2,
                    int16_t x3, int16_t y3,
                    int16_t x4, int16_t y4,
                    uint8_t color) {
    if (TRANSPARENT(color))
        return;

    const int16_t miny = min<int16_t>({y1, y2, y3, y4});
    const int16_t maxy = max<int16_t>({y1, y2, y3, y4});

    if ((miny == y1 && maxy == y2) || (miny == y2 && maxy == y1)) {
        tri_fill(x1, y1, x3, y3, x4, y4, color);
        tri_fill(x2, y2, x3, y3, x4, y4, color);
    } else if ((miny == y1 && maxy == y3) || (miny == y3 && maxy == y1)) {
        tri_fill(x1, y1, x2, y2, x4, y4, color);
        tri_fill(x3, y3, x2, y2, x4, y4, color);
    } else if ((miny == y1 && maxy == y4) || (miny == y4 && maxy == y1)) {
        tri_fill(x1, y1, x2, y2, x3, y3, color);
        tri_fill(x4, y4, x2, y2, x3, y3, color);
    } else if ((miny == y2 && maxy == y3) || (miny == y3 && maxy == y2)) {
        tri_fill(x2, y2, x1, y1, x4, y4, color);
        tri_fill(x3, y3, x1, y1, x4, y4, color);
    } else if ((miny == y2 && maxy == y4) || (miny == y4 && maxy == y2)) {
        tri_fill(x2, y2, x1, y1, x3, y3, color);
        tri_fill(x4, y4, x1, y1, x3, y3, color);
    } else if ((miny == y3 && maxy == y4) || (miny == y4 && maxy == y3)) {
        tri_fill(x3, y3, x1, y1, x2, y2, color);
        tri_fill(x4, y4, x1, y1, x2, y2, color);
    }
}

void GPU::scan_line(int16_t x1, int16_t x2, int16_t y, uint8_t color) const {
    if (TRANSPARENT(color))
        return;

    if (x2 >= x1) {
        if (!SCAN_OUT_OF_BOUNDS(x1, x2, y)) {
            x1 = max(x1, (int16_t)0);
            x2 = min(x2, (int16_t)(target_w-1));

            memset(target+x1+y*target_w, color, x2-x1+1);
        }
    }
}

void GPU::circle_fill(int16_t dx, int16_t dy, int16_t r, uint8_t color) {
    if (TRANSPARENT(color))
        return;

    int16_t d = 1-abs(r);
    int16_t x = abs(r), y = 0;

    while(x >= y) {
        scan_line(dx-x, dx+x, dy+y, color);
        scan_line(dx-x, dx+x, dy-y, color);
        scan_line(dx-y, dx+y, dy-x, color);
        scan_line(dx-y, dx+y, dy+x, color);

        if (d <= 0) {
            d += ((y+1)<<1)+1;
        } else {
            d += ((y+1)<<1)-((x-1)<<1)+1;

            x--;
        }

        y++;
    }
}

void GPU::copy_scan_line(uint8_t *dst, uint8_t *src, size_t bytes, uint8_t pal) const {
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
    pal = pal&0x0F;

    if (dy >= target_clip_end_y || dx >= target_clip_end_x) {
        return;
    }

    if (dx < target_clip_start_x) {
        w = max(w+dx-target_clip_start_x, 0);
        sx -= dx-target_clip_start_x;
        dx = target_clip_start_x;
    }

    if (dy < target_clip_start_y) {
        h = max(h+dy-target_clip_start_y, 0);
        sy -= dy-target_clip_start_y;
        dy = target_clip_start_y;
    }

    if (dy+h >= target_clip_end_y) {
        h = target_clip_end_y-dy;
    }

    if (dx+w >= target_clip_end_x) {
        w = target_clip_end_x-dx;
    }

    if (sx < 0) {
        w = max(w+sx, 0);
        sx = 0;
    }

    if (sy < 0) {
        h = max(h+sy, 0);
        dy = 0;
    }

    auto src = source+sy*source_w+sx;
    auto ptr = target+dy*target_w+dx;
    const auto ptr_f = ptr+target_w*h;

    for(;ptr < ptr_f;ptr+=target_w,src+=source_w) {
        copy_scan_line(ptr, src, w, pal);
    }
}

void GPU::clip(int16_t x, int16_t y,
               int16_t w, int16_t h) {
    if (x >= target_w || y >= target_h) {
        target_clip_start_x = 0; target_clip_start_y = 0;
        target_clip_end_x = 0; target_clip_end_y = 0;
        return;
    }

    auto dx = x+w, dy = y+h;

    if (dx < 0 || dy < 0) {
        target_clip_start_x = 0; target_clip_start_y = 0;
        target_clip_end_x = 0; target_clip_end_y = 0;
        return;
    }

    x = x < 0 ? 0 : x;
    y = y < 0 ? 0 : y;
    dx = dx > target_w ? target_w : dx;
    dy = dy > target_h ? target_h : dy;

    target_clip_start_x = x;
    target_clip_start_y = y;
    target_clip_end_x = dx;
    target_clip_end_y = dy;
}

void GPU::clear(uint8_t color) {
    if (TRANSPARENT(color))
        return;

    memset(video_memory, COLMAP1(color), GPU_VIDEO_MEM_SIZE);
}

SDL_Surface* GPU::icon_to_surface(uint8_t* &pixels) {
    png_image img;
    png_bytep img_data;

    memset(&img, 0, sizeof(png_image));
    img.version = PNG_IMAGE_VERSION;

    if (!png_image_begin_read_from_memory(&img, icon_png, icon_png_len)) {
        cout << "Could not load icon (header)" << endl;
        return nullptr;
    }

    img.format = PNG_FORMAT_RGBA;

    img_data = new uint8_t[PNG_IMAGE_SIZE(img)];

    if (png_image_finish_read(&img, NULL, img_data, 0, NULL) == 0) {
        cout << "Could not load icon (body)" << endl;
        return nullptr;
    }

    pixels = img_data;

    return SDL_CreateRGBSurfaceFrom(img_data,
                                    img.width, img.height, 32, img.width*4,
                                    0x000000ff, 0x0000ff00, 0x00ff0000, 0xff000000);
}

void GPU::set_system_cursor(uint8_t cursor) {
    if (cursor == 0) {
        SDL_ShowCursor(SDL_DISABLE);
    } else {
        // TODO: Create and use system cursors
    }
}

void GPU::set_cursor(int16_t x, int16_t y,
                     int16_t w, int16_t h,
                     int16_t hot_x, int16_t hot_y,
                     uint8_t pal) {
    if (w == 0 || h == 0) {
        SDL_ShowCursor(SDL_DISABLE);
    } else {
        SDL_SetCursor(get_cursor(x, y, w, h, hot_x, hot_y, pal));
        SDL_ShowCursor(SDL_ENABLE);
    }
}

SDL_Cursor* GPU::get_cursor(int16_t x, int16_t y,
                            int16_t w, int16_t h,
                            int16_t hot_x, int16_t hot_y,
                            uint8_t pal) {
    pal = pal&0x0F;

    // Clamp sprite position
    if (x < 0) {
        w = max(w+x, 0);
        x = 0;
    }

    if (y < 0) {
        h = max(h+y, 0);
        y = 0;
    }

    auto ptr = source+y*source_w+x;
    const auto ptr_final = ptr+source_w*h;

    // TODO: zoom to match pixel size in the console
    // FIXME: problem if too big?
    uint8_t *data = new uint8_t[w*h*4];

    // Copia o sprite em RGBA para data
    for (size_t i=0;ptr < ptr_final; ptr+=source_w) {
        uint8_t *src_pixel;
        uint8_t *src_pixel_final;

        src_pixel = ptr;
        src_pixel_final = src_pixel+w;

        while (src_pixel < src_pixel_final) {
            auto c = COLMAP1(((*src_pixel++) + (pal<<4)));

            if (TRANSPARENT(c)) {
                memcpy(data+(i+=4), "\0\0\0\0", 4);
            } else {
                memcpy(data+(i+=4), palette_memory+(COLMAP2(c)*4), 4);
            }
        }
    }

    auto hash = hash_cursor(data, w, h);

    try {
        delete data;
        return cursors.at(hash);
    } catch(out_of_range) {
        auto cursor = make_cursor(data, hash, w, h, hot_x, hot_y);

        cursors[hash] = cursor;

        delete data;
        return cursor;
    }
}

uint32_t GPU::hash_cursor(uint8_t* data, int16_t w, int16_t h) {
    int64_t hash_value = 0;
    const size_t length = uint16_t(w)*uint16_t(h)*4; // *4 por cause que é RGBA

    for (size_t i=0;i<length;i++) {
        hash_value = data[i] + (hash_value << 6) + (hash_value << 16) - hash_value;
    }

    return hash_value;
}

SDL_Cursor* GPU::make_cursor(uint8_t* data, uint32_t hash,
                             int16_t w, int16_t h,
                             int16_t hot_x, int16_t hot_y) {
    auto surface = SDL_CreateRGBSurfaceWithFormatFrom(data,
                                                      w, h,
                                                      32,
                                                      4*w,
                                                      SDL_PIXELFORMAT_RGBA32);
    auto scaled = SDL_CreateRGBSurfaceWithFormat(0,
                                                 w*screen_scale, h*screen_scale,
                                                 32,
                                                 SDL_PIXELFORMAT_RGBA32);

    SDL_BlitScaled(surface, nullptr, scaled, nullptr);

    SDL_FreeSurface(surface);

    cursor_surfaces[hash] = scaled;

    return SDL_CreateColorCursor(scaled, hot_x, hot_y);
}


void GPU::free_cursors() {
    for (auto it=cursors.begin(); it != cursors.end(); it++) {
        SDL_FreeCursor(it->second);
    }

    for (auto it=cursor_surfaces.begin(); it != cursor_surfaces.end(); it++) {
        SDL_FreeSurface(it->second);
    }

    cursors.clear();
    cursor_surfaces.clear();
}

#ifndef GPU_H
#define GPU_H

#include <cstdint>

#include <SDL.h>

#include <gif_lib.h>

#include <kernel/Device.hpp>
#include <kernel/Memory.hpp>
#include <kernel/VideoEncoder.hpp>
#include <Specs.hpp>

// OpenGL
// Referência: https://github.com/AugustoRuiz/sdl2glsl/blob/master/src/main.cpp
#include <SDL_opengl.h>
#include <SDL_opengl_glext.h>

// Número de bytes por pixel em memória na CPU e na GPU
#define BYTES_PER_PIXEL     1

// 4MB offscreen
#define SPRITESHEET_W       4096
#define SPRITESHEET_H       1024
#define SPRITESHEET_LENGTH  SPRITESHEET_W*SPRITESHEET_H*BYTES_PER_PIXEL

#define OUT_OF_BOUNDS(x,y)              ((x)<target_clip_start_x || (y)<target_clip_start_y ||\
                                         (x)>=target_clip_end_x || (y)>=target_clip_end_y) 

#define SCAN_OUT_OF_BOUNDS(x1,x2,y)     ((y)<target_clip_start_y || (y)>=target_clip_end_y ||\
                                         ((x1)<target_clip_start_x && (x2)<target_clip_start_x) ||\
                                         ((x1)>=target_clip_end_x && (x2)>=target_clip_end_x))

#define TRANSPARENT(c)      !palette_memory[(c<<2)+3]
#define COLMAP1(c)          palette_memory[512+((c)&0x7F)]
#define COLMAP2(c)          palette_memory[640+((c)&0x7F)]

class GPU: public Device {
    // Pointeiros para memória
    uint8_t *video_memory;
    uint8_t *palette_memory;

    uint8_t *source;
    int16_t source_w, source_h;
    uint8_t *target;
    int16_t target_w, target_h;
    int16_t target_clip_start_x, target_clip_start_y;
    int16_t target_clip_end_x, target_clip_end_y;

    // Is the window in fullscreen?
    bool is_fullscreen;

    // Quantas frames foram renderizadas
    size_t cycle;

    // Encoder para salvar h264
    VideoEncoder *h264;
    // Arquivo para salvar gifs
    GifFileType *gif;
    // Paleta do gif
    ColorMapObject *colormap;

    // Transformadas da tela (para normalizar mouse)
    double screen_scale;
    double screen_offset_x, screen_offset_y;

    SDL_Renderer *renderer;
    // Representação da memória de vídeo, mas copiada para a GPU
    SDL_Texture *framebuffer;
    SDL_Rect framebuffer_dst, framebuffer_src;

    // Shader para expandir as cores
    GLuint shader;

    // Cursores do mouse
    map<uint32_t, SDL_Cursor*> cursors;
    map<uint32_t, SDL_Surface*> cursor_surfaces;
protected:
    friend class Kernel;

    SDL_Window* window;
public:
    GPU(Memory&, const bool);
    ~GPU();

    void startup();

    // Desenha no framebuffer
    void draw();

    // Atualiza tamanho da janela
    void resize();
    void toggle_fullscreen();
    void fullscreen(const bool);

    // Tela -> tela do nibble
    void transform_mouse(int16_t&, int16_t&);

    // API
    void clear(uint8_t);
    void line(int16_t, int16_t, int16_t, int16_t, uint8_t); void rect(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void tri(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void quad(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void circle(int16_t, int16_t, int16_t, uint8_t);

    void rect_fill(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void ordered_tri_fill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void tri_fill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void tri_textured(int16_t, int16_t, int16_t,
                      int16_t, int16_t, int16_t,
                      int16_t, int16_t, int16_t,
                      int16_t, int16_t,
                      int16_t, int16_t,
                      int16_t, int16_t);
    void quad_fill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void circle_fill(int16_t, int16_t, int16_t, uint8_t);

    void sprite(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

    void clip(int16_t, int16_t, int16_t, int16_t);

    void set_system_cursor(uint8_t);
    void set_cursor(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

    // GIFs
    bool start_capturing(const string&);
    bool stop_capturing();
private:
    void ordered_tri_textured(int16_t, int16_t, int16_t,
                              int16_t, int16_t, int16_t,
                              int16_t, int16_t, int16_t,
                              int16_t, int16_t,
                              int16_t, int16_t,
                              int16_t, int16_t);
    void scan_line_textured(int16_t, int16_t, int16_t,
                            int16_t, int16_t,
                            int16_t, int16_t) const;
    void copy_scan_line(uint8_t *, uint8_t *, size_t, uint8_t) const;
    void scan_line(int16_t, int16_t, int16_t, uint8_t) const;
    void fix_rect_bounds(int16_t&, int16_t&, int16_t&, int16_t&, int16_t, int16_t) const;
    void fix_line_bounds(int16_t&, int16_t&, int16_t&, int16_t&) const;
    uint8_t find_point_region(const int16_t, const int16_t) const;
    bool capture_frame();
    ColorMapObject* get_color_map();

    SDL_Surface* icon_to_surface(uint8_t* &);

    SDL_Cursor* get_cursor(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    uint32_t hash_cursor(uint8_t*, int16_t, int16_t);
    SDL_Cursor* make_cursor(uint8_t*, uint32_t, int16_t, int16_t, int16_t, int16_t);

    void free_cursors();

    void paint_boot_animation();

    // Shaders
    GLuint compile_shader(const string&, const GLuint);
    GLuint compile_program(const string&, const string&);
    void print_shader_errors(GLuint);

    void check_opengl();
};

#endif /* GPU_H */

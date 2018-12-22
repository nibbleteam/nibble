#ifndef GPU_H
#define GPU_H

#include <cstdint>

#include <SDL2/SDL.h>

#include <gif_lib.h>

#include <kernel/Device.hpp>
#include <kernel/Memory.hpp>
#include <Specs.hpp>

// Número de bytes por pixel em memória na CPU e na GPU
#define BYTES_PER_PIXEL     1
#define BYTES_PER_TEXEL     4

// 4MB offscreen
#define SPRITESHEET_W       4096
#define SPRITESHEET_H       1024
#define SPRITESHEET_LENGTH  SPRITESHEET_W*SPRITESHEET_H*BYTES_PER_PIXEL

#define OUT_OF_BOUNDS(x,y)              ((x)<0 || (y)<0 ||\
                                         (x)>=targetW || (y)>=targetH) 

#define SCAN_OUT_OF_BOUNDS(x1,x2,y)     ((y)<0 || (y)>=targetH ||\
                                         ((x1)<0 && (x2)<0) ||\
                                         ((x1)>=targetW && (x2)>=targetW))

#define TRANSPARENT(c)      !paletteMemory[(c<<2)+3]
#define COLMAP1(c)          paletteMemory[512+((c)&0x7F)]

class GPU: public Device {
    // Pointeiros para memória
    uint8_t *commandMemory;
    uint8_t *videoMemory;
    uint8_t *paletteMemory;

    uint8_t *source;
    int16_t sourceW, sourceH;
    uint8_t *target;
    int16_t targetW, targetH;

    // Arquivo para salvar gifs
    GifFileType *gif;
    // Paleta do gif
    ColorMapObject *colormap;

    // Transformadas da tela (para normalizar mouse)
    double screenScale;
    double screenOffsetX, screenOffsetY;

    SDL_Renderer *renderer;
    // Framebuffer da imagem final
    SDL_Texture *framebuffer;
    
    SDL_Rect framebufferDst, framebufferSrc;
protected:
    friend class Kernel;

    SDL_Window* window;
public:
    GPU(Memory&);
    ~GPU();

    void startup();

    // Desenha no framebuffer
    void draw();

    // Atualiza tamanho da janela
    void resize();

    // Tela -> tela do nibble
    void transformMouse(int16_t&, int16_t&);
protected:
    void line(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void rect(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void tri(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void quad(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void circle(int16_t, int16_t, int16_t, uint8_t);

    void rectFill(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void orderedTriFill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void triFill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void quadFill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void circleFill(int16_t, int16_t, int16_t, uint8_t);

    void sprite(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

    void execGpuCommand(uint8_t*);
private:
    // Helpers para extrair argumentos de um comando
    // da GPU
    int16_t next16Arg(uint8_t*&);
    uint8_t next8Arg(uint8_t*&);
    string nextStrArg(uint8_t*&);
    void copyScanLine(uint8_t *, uint8_t *, size_t, uint8_t);
    void scanLine(int16_t, int16_t, int16_t, uint8_t);
    void fixRectBounds(int16_t&, int16_t&, int16_t&, int16_t&, int16_t, int16_t);
    // GIFs
    bool startCapturing(const string&);
    bool captureFrame();
    bool stopCapturing();
    ColorMapObject* getColorMap();
};

#endif /* GPU_H */

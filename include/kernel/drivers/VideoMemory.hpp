#ifndef VIDEO_MEMORY_H
#define VIDEO_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>
#include <kernel/RenderBuffer.hpp>
#include <SFML/Graphics.hpp>
#include <gif_lib.h>

using namespace std;

// Número de bytes por pixel em memória na CPU e na GPU
#define BYTES_PER_PIXEL     1
#define BYTES_PER_TEXEL     4

// 4MB offscreen
#define SPRITESHEET_W       4096
#define SPRITESHEET_H       1024
#define SPRITESHEET_LENGTH  SPRITESHEET_W*SPRITESHEET_H*BYTES_PER_PIXEL

// 75KB onscreen
#define SCREEN_W            320
#define SCREEN_H            240
#define VIDEO_MEMORY_LENGTH SCREEN_W*SCREEN_H*BYTES_PER_PIXEL

#define OUT_OF_BOUNDS(x,y)              (x<0 || y<0 || x>=SCREEN_W || y>=SCREEN_H) 
#define SCAN_OUT_OF_BOUNDS(x1,x2,y)     (y<0 || y>=SCREEN_H || (x1<0 && x2<0) || (x1>=SCREEN_W && x2>=SCREEN_W))

#define TRANSPARENT(c)      !paletteData[(c<<2)+3]
#define COLMAP1(c)          paletteData[512+((c)&0x7F)]

class VideoMemory : public Memory {
    // Permite o acesso as funçõe protected
    friend class GPUCommandMemory;
    // Referência para a janela para que possamos desenhar para ela
    sf::RenderWindow &window;

    // Detalhes da memória
    const uint64_t address;

    // Framebuffer da imagem final
    sf::Texture framebuffer;
    // Textura utilizada como paleta pelo shader
    sf::Texture paletteTex;

    // Áreas para desenho do framebuffer
    sf::Sprite framebufferSpr;

    // Memória de vídeo
    uint8_t buffer[VIDEO_MEMORY_LENGTH];
    // Área de memória para spritesheet
    uint8_t spritesheet[SPRITESHEET_LENGTH];

    // Ponteiro para os dados da textura paletteTex
    const uint8_t *paletteData;

    // Código e o shader utilizado para desenhar mixar texturas
    // e expandir para a tela
    const static string shaderVertex;
    const static string toRGBAShaderFragment;
    sf::Shader toRGBAShader;

    // Arquivo para salvar gifs
    GifFileType *gif;
    // Paleta do gif
    ColorMapObject *colormap;

    // Transformadas da tela (para normalizar mouse)
    double screenScale;
    double screenOffsetX, screenOffsetY;
public:
    VideoMemory(sf::RenderWindow&, const uint64_t);
    ~VideoMemory();

	string name();

    // Ajust escala e aspect ratio para a
    // a janela atual
    void resize();
    void transformMouse(uint16_t&, uint16_t&);

    void draw();

    uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
    uint64_t read(const uint64_t, uint8_t*, const uint64_t);

    uint64_t size();
    uint64_t addr();

    // Chamado por paletteMemory quando o usuário troca a paleta
    void updatePalette(const uint8_t*);
    // Chamado por CartidgeMemory quando algum sprite muda
    void updateSpriteSheet(const uint64_t, const uint8_t*, const uint64_t);
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
    void copyScanLine(uint8_t *, uint8_t *, size_t);
    void scanLine(int16_t, int16_t, int16_t, uint8_t);
    void fixRectBounds(int16_t&, int16_t&, int16_t&, int16_t&, int16_t, int16_t);
    // GIFs
    bool startCapturing(const string&);
    bool captureFrame();
    bool stopCapturing();
    ColorMapObject* getColorMap();
};

#endif /* VIDEO_MEMORY_H */

#ifndef VIDEO_MEMORY_H
#define VIDEO_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>
#include <kernel/RenderBuffer.hpp>
#include <SFML/Graphics.hpp>
#include <gif_lib.h>

using namespace std;

class VideoMemory : public Memory {
    // Memória de vídeo
    uint8_t buffer[VIDEO_MEMORY_LENGTH];
    // Área de memória para spritesheet
    uint8_t spritesheet[SPRITESHEET_LENGTH];

    // Ponteiro para os dados da textura paletteTex
    const uint8_t *paletteData;
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

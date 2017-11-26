#ifndef GPU_H
#define GPU_H

#include <SFML/Graphics.hpp>
#include <kernel/Memory.hpp>
#include <cstdint>

// Define classe para evitar 
// dependência circular
class VideoMemory;
class PaletteMemory;
class GPUCommandMemory;

class GPU {
    // Memórias
    GPUCommandMemory *commandMemory;
    VideoMemory* videoMemory;
    PaletteMemory* paletteMemory;
public:
    // Tamanho tamanho da paleta
    const static uint64_t paletteLength;
    // Quantas paletas
    const static uint64_t paletteAmount;
public:
    GPU(sf::RenderWindow&,
        const unsigned int, const unsigned int,
        uint64_t);
    ~GPU();

    void draw();

    Memory* getVideoMemory();
    Memory* getPaletteMemory();
    Memory* getCommandMemory();
};

#endif /* GPU_H */

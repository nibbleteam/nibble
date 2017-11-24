#include <kernel/drivers/GPU.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/PaletteMemory.hpp>

const uint64_t GPU::paletteLength = 16;
const uint64_t GPU::paletteAmount = 8;

GPU::GPU(sf::RenderWindow& window,
         const unsigned int w, const unsigned int h,
         uint64_t addr) {
    const uint64_t paletteSize = paletteLength*
                                 paletteAmount*
                                 VideoMemory::bytesPerPixel;
    videoMemory = new VideoMemory(window, w, h, addr+paletteSize);
    paletteMemory = new PaletteMemory(videoMemory, addr);
}

GPU::~GPU() {
}

void GPU::draw() {
    videoMemory->draw();
}

VideoMemory* GPU::getVideoMemory() {
    return videoMemory;
}

PaletteMemory* GPU::getPaletteMemory() {
    return paletteMemory;
}

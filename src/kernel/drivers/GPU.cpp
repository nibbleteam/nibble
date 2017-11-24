#include <kernel/drivers/GPU.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/PaletteMemory.hpp>
#include <kernel/drivers/GPUCommandMemory.hpp>

const uint64_t GPU::paletteLength = 16;
const uint64_t GPU::paletteAmount = 8;

GPU::GPU(sf::RenderWindow& window,
         const unsigned int w, const unsigned int h,
         uint64_t addr) {
    const uint64_t paletteSize = paletteLength*
                                 paletteAmount*
                                 VideoMemory::bytesPerPixel;
    videoMemory = new VideoMemory(window, w, h, addr+paletteSize+GPUCommandMemory::length);
    paletteMemory = new PaletteMemory(videoMemory, addr+GPUCommandMemory::length);
    commandMemory = new GPUCommandMemory(videoMemory, addr);
}

GPU::~GPU() {
}

void GPU::draw() {
    videoMemory->draw();
}

Memory* GPU::getVideoMemory() {
    return (Memory*)videoMemory;
}

Memory* GPU::getPaletteMemory() {
    return (Memory*)paletteMemory;
}

Memory* GPU::getCommandMemory() {
    return (Memory*)commandMemory;
}

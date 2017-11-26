#include <kernel/drivers/PaletteMemory.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <iostream>
#include <cstring>

PaletteMemory::PaletteMemory(VideoMemory* video, const uint64_t addr) :
	address(addr),
    length(GPU::paletteLength*GPU::paletteAmount*VideoMemory::bytesPerPixel),
    videoMemory(video) {
	data = new uint8_t[(size_t)length];

    // Atualiza a paleta pra o mesmo lixo que estiver
    // na memória aqui
    videoMemory->updatePalette(this->data);
}

PaletteMemory::~PaletteMemory() {
	delete data;
}

uint64_t PaletteMemory::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
	memcpy(this->data + pos, data, (size_t)amount);

    videoMemory->updatePalette(this->data);

	return amount;
}

uint64_t PaletteMemory::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
	memcpy(data, this->data + pos, (size_t)amount);

	return amount;
}

uint64_t PaletteMemory::size() {
	return length;
}

uint64_t PaletteMemory::addr() {
	return address;
}

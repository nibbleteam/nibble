#include <kernel/drivers/PaletteMemory.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <chrono>
#include <thread>
#include <iostream>
#include <cstring>

PaletteMemory::PaletteMemory(VideoMemory* video, const uint64_t addr) :
	address(addr),
    length(GPU::paletteLength*GPU::paletteAmount*VideoMemory::bytesPerPixel+ // Cores RGBA 
           2*GPU::paletteAmount*GPU::paletteLength),                         // Mapas Índice -> Índice e Índice -> COr 
    videoMemory(video) {
	data = new uint8_t[(size_t)length] {
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

    int start = GPU::paletteLength*GPU::paletteAmount*VideoMemory::bytesPerPixel; 
    int len = GPU::paletteLength*GPU::paletteAmount;

    // Preenche routing tables com mapeamentos 1:1
    // ou seja, sem efeito nenhum
    // Preenche a routing table 1
    for (int i=start;i<start+len;i++) {
        data[i] = i-start;
    }
    // E a 2
    for (int i=start+len;i<start+len*2;i++) {
        data[i] = i-start-len;
    }

    videoMemory->updatePalette(this->data);
}

PaletteMemory::~PaletteMemory() {
	delete[] data;
}

string PaletteMemory::name() {
	return "PAL";
}

uint64_t PaletteMemory::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
    // Acesso direto as cores é lento
    // de forma que não pode ser usado
    // para efeitos intensos
    if (pos < GPU::paletteLength*GPU::paletteAmount*VideoMemory::bytesPerPixel) {
        std::this_thread::sleep_for(std::chrono::milliseconds(LOW_PALETTE_ACCESS_TIME));
    }

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

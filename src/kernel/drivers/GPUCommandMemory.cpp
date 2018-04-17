#include <kernel/drivers/GPUCommandMemory.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <cstring>

const uint64_t GPUCommandMemory::length = 32;

GPUCommandMemory::GPUCommandMemory(VideoMemory* video, const uint64_t addr) :
	address(addr),
    videoMemory(video) {
	data = new uint8_t[(size_t)length];
}

GPUCommandMemory::~GPUCommandMemory() {
	delete[] data;
}

string GPUCommandMemory::name() {
	return "GPU";
}

uint64_t GPUCommandMemory::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
	memcpy(this->data + pos, data, (size_t)amount);

    videoMemory->execGpuCommand(this->data);

	return amount;
}

uint64_t GPUCommandMemory::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
    // Os comandos são write-only
    return 0;
}

uint64_t GPUCommandMemory::size() {
	return length;
}

uint64_t GPUCommandMemory::addr() {
	return address;
}

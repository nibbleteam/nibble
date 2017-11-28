#include <kernel/drivers/RandomMemory.hpp>
#include <iostream>
#include <cstring>
#include <cstdlib>

const uint64_t RandomMemory::length = 320*240;

RandomMemory::RandomMemory(const uint64_t addr) :
	address(addr) {
	data = new uint8_t[(size_t)length];
}

RandomMemory::~RandomMemory() {
	delete[] data;
}

// Apenas leitura
uint64_t RandomMemory::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
    return 0;
}

uint64_t RandomMemory::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
    randomize(amount);

	memcpy(data, this->data, (size_t)amount);

	return amount;
}

void RandomMemory::randomize(const uint64_t amount) {
    uint32_t number;
    for (uint64_t i=0; i<amount; i+=sizeof(number)) {
        number = rand();
        memcpy(data+i, &number, sizeof(number));
    }
}

uint64_t RandomMemory::size() {
	return length;
}

uint64_t RandomMemory::addr() {
	return address;
}

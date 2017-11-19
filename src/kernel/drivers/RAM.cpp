#include <kernel/drivers/RAM.hpp>
#include <iostream>

RAM::RAM(const uint64_t addr, const uint64_t len) :
	address(addr), length(len) {
	data = new uint8_t[(size_t)len];
}

RAM::~RAM() {
	delete data;
}

uint64_t RAM::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
	memcpy(this->data + pos, data, (size_t)amount);

	return amount;
}

uint64_t RAM::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
	memcpy(data, this->data + pos, (size_t)amount);

	return amount;
}

uint64_t RAM::size() {
	return length;
}

uint64_t RAM::addr() {
	return address;
}
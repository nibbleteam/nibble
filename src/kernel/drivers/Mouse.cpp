#include <kernel/drivers/Mouse.hpp>
#include <iostream>
#include <cstring>

Mouse::Mouse(const uint64_t addr) :
	address(addr) {
}

Mouse::~Mouse() {
}

uint64_t Mouse::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
	return amount;
}

uint64_t Mouse::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
	return amount;
}

uint64_t Mouse::size() {
    return 0;
}

uint64_t Mouse::addr() {
	return address;
}

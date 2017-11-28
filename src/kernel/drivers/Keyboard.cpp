#include <kernel/drivers/Keyboard.hpp>
#include <iostream>
#include <cstring>

Keyboard::Keyboard(const uint64_t addr) :
	address(addr) {
}

Keyboard::~Keyboard() {
}

uint64_t Keyboard::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
	return amount;
}

uint64_t Keyboard::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
	return amount;
}

uint64_t Keyboard::size() {
    return 0;
}

uint64_t Keyboard::addr() {
	return address;
}

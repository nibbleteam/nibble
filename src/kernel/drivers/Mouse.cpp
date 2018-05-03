#include <kernel/drivers/Mouse.hpp>
#include <kernel/drivers/Controller.hpp>
#include <iostream>
#include <cstring>

Mouse::Mouse(const uint64_t addr) :
	address(addr) {
}

Mouse::~Mouse() {
}

string Mouse::name() {
    return "MOUSE";
}

uint64_t Mouse::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
	return 0;
}

uint64_t Mouse::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
    memcpy(data, mem+pos, amount);
	return amount;
}

uint64_t Mouse::size() {
    return 6;
}

uint64_t Mouse::addr() {
	return address;
}

void Mouse::moved(uint16_t x, uint16_t y) {
    mem[0] = x>>8;
    mem[1] = (uint8_t)x;
    mem[2] = y>>8;
    mem[3] = (uint8_t)y;
}

void Mouse::pressed(uint8_t bt) {
    if (bt) {
        mem[5] = BUTTON_OFF_ON;
    } else {
        mem[4] = BUTTON_OFF_ON;
    }
}

void Mouse::released(uint8_t bt) {
    if (bt) {
        mem[5] = BUTTON_ON_OFF;
    } else {
        mem[4] = BUTTON_ON_OFF;
    }
}

void Mouse::update() {
    for (int p=4;p<=5;p++) {
        switch(mem[p]) {
            case BUTTON_OFF_ON:
                mem[p] = BUTTON_ON;
                break;
            case BUTTON_ON_OFF:
                mem[p] = BUTTON_OFF;
                break;
            default:
                break;
        }
    }
}

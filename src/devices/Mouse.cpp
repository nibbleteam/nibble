#include <iostream>
#include <cstring>

#include <devices/Mouse.hpp>
#include <devices/Controller.hpp>

Mouse::Mouse(Memory &memory) {
    mem = memory.allocate(MOUSE_MEM_SIZE, "Mouse");
}

void Mouse::scrolled(uint8_t x, uint8_t y) {
    mem[6] = x;
    mem[7] = y;
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
        if (mem[5] == BUTTON_OFF_ON ||
            mem[5] == BUTTON_ON) {
            mem[5] = BUTTON_ON_OFF;
        }
    } else {
        if (mem[4] == BUTTON_OFF_ON ||
            mem[4] == BUTTON_ON) {
            mem[4] = BUTTON_ON_OFF;
        }
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

    mem[6] = 128;
    mem[7] = 128;
}

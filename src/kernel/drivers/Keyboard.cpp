#include <kernel/drivers/Keyboard.hpp>
#include <iostream>
#include <cstring>

const unsigned int Keyboard::queueSize = 32;

Keyboard::Keyboard(const uint64_t addr) :
    address(addr), ptr(0) {
    queue = new uint8_t[queueSize];
}

Keyboard::~Keyboard() {
    delete[] queue;
}

void Keyboard::input(const unsigned int unicode) {
    queue[ptr++] = (char)unicode;
}

uint64_t Keyboard::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
    return 0;
}

uint64_t Keyboard::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
    unsigned int actualAmount = amount > ptr ? ptr : amount;
    ptr -= actualAmount;

    if (ptr) 
        memcpy(queue, queue+ptr, ptr);
    memcpy(data, queue, actualAmount);

    return actualAmount;
}

uint64_t Keyboard::size() {
    return queueSize;
}

uint64_t Keyboard::addr() {
    return address;
}

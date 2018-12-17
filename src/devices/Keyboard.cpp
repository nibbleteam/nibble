#include <iostream>
#include <cstring>

#include <kernel/Memory.hpp>

#include <devices/Keyboard.hpp>

#include <Specs.hpp>

Keyboard::Keyboard(Memory &memory) {
    mem = memory.allocate(KEYBOARD_QUEUE_SIZE, "Keyboard");

    memset(mem, 0, KEYBOARD_QUEUE_SIZE);
}

void Keyboard::input(const unsigned int unicode) {
    charQueue.push((char)unicode);
}

void Keyboard::update() {
    size_t i = 0;

    for (;!charQueue.empty();i++)  {
        mem[i+1] = charQueue.front();
        charQueue.pop();
    }

    mem[0] = i;
}

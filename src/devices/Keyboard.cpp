#include <iostream>
#include <cstring>

#include <kernel/Memory.hpp>

#include <devices/Keyboard.hpp>

#include <Specs.hpp>

Keyboard::Keyboard(Memory &memory) {
    queue = memory.allocate(KEYBOARD_QUEUE_SIZE, "Keyboard", [&] (Memory::AccessMode mode) {
        if (mode == Memory::ACCESS_AFTER_READ) {
            queue[0] = 0;
        }
    });

    memset(queue, 0, KEYBOARD_QUEUE_SIZE);
}

void Keyboard::input(const unsigned int unicode) {
    // Coloca no primeiro espaço encontrado
    for (size_t i=0;i<KEYBOARD_QUEUE_SIZE;i++) {
        if (queue[i] == 0) {
            // TODO: escrever como UTF8
            queue[i] = (char)unicode;
            break;
        }
    }
}

#include <iostream>
#include <cstring>

#include <kernel/Memory.hpp>

#include <devices/Keyboard.hpp>

#include <Specs.hpp>

#define KEYBIT(x) ((event.key.keysym.mod&x)?1:0)

Keyboard::Keyboard(Memory &memory) {
    mem = memory.allocate(KEYBOARD_QUEUE_SIZE, "Keyboard");
    events = memory.allocate(KEYBOARD_QUEUE_SIZE, "Keyboard Events");

    memset(mem, 0, KEYBOARD_QUEUE_SIZE);
    memset(events, 0, KEYBOARD_QUEUE_SIZE);
}

void Keyboard::event(const SDL_Event &event) {
    key_queue.push(event);
}

void Keyboard::input(const char* utf8) {
    char_queue.push(string(utf8));
}

void Keyboard::update() {
    // Escreve para a memória de texto
    size_t i = 1;

    while(!char_queue.empty()) {
        string utf8 = char_queue.front();

        memcpy(mem+i, utf8.c_str(), utf8.size());

        i += utf8.size();

        char_queue.pop();
    }

    mem[0] = i-1;

    size_t k = 0;

    // Escreve para a memória de teclas
    while (!key_queue.empty()) {
        auto event = key_queue.front();

        events[k++] = event.key.type == SDL_KEYDOWN? 1 : 2;
        events[k++] = (uint8_t)event.key.keysym.sym;
        events[k++] =
            KEYBIT(KMOD_SHIFT)    |
            (KEYBIT(KMOD_CTRL)<<1)|
            (KEYBIT(KMOD_ALT) <<2)|
            (KEYBIT(KMOD_GUI) <<3);

        key_queue.pop();
    }

    events[k] = 0;
}

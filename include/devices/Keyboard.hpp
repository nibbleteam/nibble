#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <cstdint>
#include <queue>
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

#include <SDL.h>

using namespace std;

class Keyboard : public Device {
    queue<string> char_queue;
    queue<SDL_Event> key_queue;
    uint8_t *mem;
    uint8_t *events;
public:
    Keyboard(Memory&);

    void event(const SDL_Event&);
    void input(const char*);
    void update();
};

#endif /* KEYBOARD_H */

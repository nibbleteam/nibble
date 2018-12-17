#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <cstdint>
#include <queue>
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

using namespace std;

class Keyboard : public Device {
    queue<char> charQueue;
    uint8_t *mem;
public:
    Keyboard(Memory&);

    void input(const unsigned int);
    void update();
};

#endif /* KEYBOARD_H */

#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <cstdint>
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

using namespace std;

class Keyboard : public Device {
    uint8_t *queue;
public:
    Keyboard(Memory&);

    void input(const unsigned int);
};

#endif /* KEYBOARD_H */

#ifndef MOUSE_H
#define MOUSE_H

#include <cstdint>
#include <kernel/Device.hpp>
#include <kernel/Memory.hpp>

using namespace std;

class Mouse : public Device {
    uint8_t *mem;
public:
	Mouse(Memory&);

    void moved(uint16_t, uint16_t);
    void pressed(uint8_t);
    void released(uint8_t);

    void update();
};

#endif /* MOUSE_H */

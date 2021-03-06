#include <kernel/SquareWave.hpp>

int16_t SquareWave::value_at(uint8_t t) const {
    if (t < 128) {
        return INT16_MIN;
    } else {
        return INT16_MAX;
    }
}

#include <kernel/SquareWave.hpp>

const int16_t SquareWave::valueAt(uint8_t t) const {
    if (t < 128) {
        return INT16_MIN;
    } else {
        return INT16_MAX;
    }
}

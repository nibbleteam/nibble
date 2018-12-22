#include <kernel/TriangleWave.hpp>

const int16_t TriangleWave::valueAt(uint8_t t) const {
    const static auto step = INT16_MAX/64;

    if (t < 128) {
        return t*step+INT16_MIN;
    } else {
        return INT16_MAX-(t-128)*step;
    }
}

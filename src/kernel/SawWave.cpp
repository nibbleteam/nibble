#include <kernel/SawWave.hpp>

const int16_t SawWave::valueAt(uint8_t t) const {
    const static auto step = INT16_MAX/128;

    return t*step+INT16_MIN;
}
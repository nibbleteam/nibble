#ifndef TRIANGLE_WAVE_H
#define TRIANGLE_WAVE_H

#include <kernel/Wave.hpp>

class TriangleWave: public Wave {
public:
private:
    const int16_t value_at(uint8_t) const;
};

#endif /* SAW_WAVE_H */

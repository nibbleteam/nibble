#ifndef SQUARE_WAVE_H
#define SQUARE_WAVE_H

#include <kernel/Wave.hpp>

class SquareWave : public Wave {
public:
    SquareWave(uint8_t*, uint64_t, uint64_t);
    int16_t* fill(const unsigned int);
};

#endif /* SQUARE_WAVE_H */

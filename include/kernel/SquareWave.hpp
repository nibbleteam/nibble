#ifndef SQUARE_WAVE_H
#define SQUARE_WAVE_H

#include <kernel/Wave.hpp>

class SquareWave: public Wave {
public:
private:
    const int16_t valueAt(uint8_t) const;
};

#endif /* SQUARE_WAVE_H */
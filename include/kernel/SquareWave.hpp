#ifndef SQUARE_WAVE_H
#define SQUARE_WAVE_H

#include <kernel/Wave.hpp>

class SquareWave: public Wave {
public:
private:
    int16_t value_at(uint8_t) const;
};

#endif /* SQUARE_WAVE_H */

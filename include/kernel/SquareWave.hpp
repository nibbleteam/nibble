#ifndef SQUARE_WAVE_H
#define SQUARE_WAVE_H

#include <kernel/Wave.hpp>

class SquareWave : public Wave {
    int16_t samples[MAX_WAVE_SAMPLES];
    uint32_t t, clockT;

    int16_t amplitude;
    int16_t adsr;
    double period;
    double beatPeriod;
    double clockPeriod;
    double duty;

    int16_t attack;
    int16_t decay;
    int16_t sustain;
    int16_t release;

    int16_t vAttack;
    int16_t vDecay;

    uint8_t pattern[256];
public:
    SquareWave(uint8_t);
    int16_t* fill(const unsigned int);
private:
    void changeParameters();
};

#endif /* SQUARE_WAVE_H */

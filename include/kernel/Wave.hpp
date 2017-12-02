#ifndef WAVE_H
#define WAVE_H

#include <cstdint>

#define MAX_WAVE_SAMPLES 4096

class Wave {
public:
    int16_t samples[MAX_WAVE_SAMPLES];

    uint32_t t;
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

    uint8_t* memory;
    uint64_t memoryLength;
    uint64_t confPosition;
public:
    Wave(uint8_t*, uint64_t, uint64_t);

    virtual int16_t* fill(const unsigned int) = 0;

    static double fromNote(uint8_t, uint8_t);
    static double fromFrequency(double);
protected:
    void changeParameters();
};

#endif /* WAVE_H */

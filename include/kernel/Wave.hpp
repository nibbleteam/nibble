#ifndef WAVE_H
#define WAVE_H

#include <cstdint>

#define MAX_WAVE_SAMPLES 4096

class Wave {
public:
    Wave() {}

    virtual int16_t* fill(const unsigned int) = 0;

    static double fromNote(uint8_t, uint8_t);
protected:
    double fromFrequency(double);
};

#endif /* WAVE_H */

#ifndef WAVE_H
#define WAVE_H

#include <cstdint>

#define MAX_WAVE_SAMPLES 4096
#define WAVE_LUT_SIZE 128

class Wave {
public:
    int16_t samples[MAX_WAVE_SAMPLES];
    int16_t lut[WAVE_LUT_SIZE];

	double phase;

	const double amplitudeError = 0.05;

    double amplitude, targetAmplitude, previousAmplitude;
    double period;
    double duty;

    enum ChannelType {
        WAVE_CHANNEL,
        SAMPLE_CHANNEL,
        NOISE_CHANNEL
    };
public:
    Wave();
    virtual ~Wave();

    virtual int16_t* fill(const unsigned int);

    virtual ChannelType type() = 0;

    static double fromNote(uint8_t, uint8_t);
    static double fromFrequency(double);
protected:
    void changeParameters();
    double valueAt(double);
};

#endif /* WAVE_H */

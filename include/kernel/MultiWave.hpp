#ifndef MULTI_WAVE_H
#define MULTI_WAVE_H

#include <kernel/Wave.hpp>

class MultiWave : public Wave {
public:
    enum WaveType {
        SQUARE,
        TRIANGLE,
        SAW,
        SIN,
        PSIN
    };
    WaveType waveType;

    MultiWave(WaveType);

    // Muda o tipo da onda
    void setType(WaveType);

    ChannelType type();
private:
    // Gera a lookup table para o tipo atual de onda
    void fillLUT();

    void fillSquare();
    void fillTriangle();
    void fillSaw();
    void fillSin();
    void fillPSin();
};

#endif /* MULTI_WAVE_H */

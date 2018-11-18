#ifndef NIBBLE_FM_SYNTHESIZER
#define NIBBLE_FM_SYNTHESIZER

#include <kernel/Wave.hpp>
#include <kernel/Envelope.hpp>

#define SND_FM_OPERATORS    4

class FMSynthesizer {
    // Oscilador
    static Wave wave;

    // Acumuladores
    uint16_t times[SND_FM_OPERATORS];
    // Freqüências
    uint8_t *freqs;
    // Envelopes
    Envelope* envelopes[SND_FM_OPERATORS];
    // Saídas
    int16_t outputs[SND_FM_OPERATORS+1];
    // Matriz de operadores
    uint8_t *amplitudes;

    uint8_t *mem;

    // Frequência base
    float base;

    // TODO: detune
    // TODO: envelopes
public:
    FMSynthesizer(uint8_t*, uint8_t);
    ~FMSynthesizer();

    void fill(int16_t*, unsigned int);

    bool done();

    // Note On/Off
    void on();
    void off();
private:
    int16_t synthesize();

    uint8_t* argptr8(const size_t);
    float tof(uint8_t);
};

#endif /* NIBBLE_FM_SYNTHESIZER */

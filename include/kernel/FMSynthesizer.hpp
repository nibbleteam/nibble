#ifndef NIBBLE_FM_SYNTHESIZER
#define NIBBLE_FM_SYNTHESIZER

#include <array>
#include <memory>

#include <kernel/Wave.hpp>
#include <kernel/SquareWave.hpp>
#include <kernel/SawWave.hpp>
#include <kernel/TriangleWave.hpp>
#include <kernel/Envelope.hpp>

#include <Specs.hpp>

using namespace std;

/*
 * Formato da matriz FM
 * OPS: operadores
 * OUT: saída (uma só coluna com aplitudes da saída)
 *
 * A amplitude em cada célula representa o operador em y
 * modulando o operador em x.
 *
 * y -> x
 *
 *  OPS + OUT
 * ------|--->
 *  _________
 * |     |   | | OPS
 * |     |   | |
 * |_____|___| v
 */
#define FM_MATRIX(y,x)   (y)*(AUDIO_OPERATOR_AMOUNT+1)+(x)

class FMSynthesizer {
    // Osciladores
    static Wave wave;
    static SquareWave squareWave;
    static SawWave sawWave;
    static TriangleWave triangleWave;
    // Acumuladores
    uint16_t times[AUDIO_OPERATOR_AMOUNT];
    // Envelopes
    array<unique_ptr<Envelope>, AUDIO_OPERATOR_AMOUNT> envelopes;
    // Saídas
    int16_t outputs[AUDIO_OPERATOR_AMOUNT+1];
    // Frequência base
    float base;
public:
    enum WaveType {
        SINE,
        SQUARE,
        SAW,
        TRIANGLE,
    };

#pragma pack(push, 1)
    typedef struct MemoryLayout {
        int16_t frequencies[AUDIO_OPERATOR_AMOUNT];
        Envelope::MemoryLayout envelopes[AUDIO_OPERATOR_AMOUNT];
        int16_t amplitudes[AUDIO_OPERATOR_AMOUNT*AUDIO_OPERATOR_AMOUNT+AUDIO_OPERATOR_AMOUNT];
        uint8_t waveTypes[AUDIO_OPERATOR_AMOUNT];
    }MemoryLayout;
#pragma pack(pop)

    MemoryLayout &memory;
public:
    FMSynthesizer(MemoryLayout&, uint8_t);

    void fill(int16_t*, int16_t*, unsigned int);

    bool done();

    // Note On/Off
    void on(uint8_t);
    void off();
private:
    int16_t synthesize();
};

#endif /* NIBBLE_FM_SYNTHESIZER */

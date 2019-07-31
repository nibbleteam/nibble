#include <kernel/FMSynthesizer.hpp>
#include <devices/Audio.hpp>
#include <cmath>

#include <iostream>
using namespace std;

Wave FMSynthesizer::wave;
SquareWave FMSynthesizer::square_wave;
SawWave FMSynthesizer::saw_wave;
TriangleWave FMSynthesizer::triangle_wave;

FMSynthesizer::FMSynthesizer(MemoryLayout &memory, uint8_t note): memory(memory) {
    base = 440.0*pow(1.059463094359, double(note-69));

    for (size_t op=0;op<AUDIO_OPERATOR_AMOUNT;op++) {
        envelopes[op] = make_unique<Envelope>(memory.envelopes[op]);
    }
}

bool FMSynthesizer::done() {
    for (size_t e=0;e<AUDIO_OPERATOR_AMOUNT;e++) {
        if (!envelopes[e]->done) {
            return false;
        }
    }

    return true;
}

void FMSynthesizer::on(uint8_t intensity) {
    for (size_t e=0;e<AUDIO_OPERATOR_AMOUNT;e++) {
        envelopes[e]->on(intensity);
    }
}

void FMSynthesizer::off() {
    for (size_t e=0;e<AUDIO_OPERATOR_AMOUNT;e++) {
        envelopes[e]->off();
    }
}

void FMSynthesizer::fill(int16_t* samples, int16_t* clean, unsigned int sample_count) {
    for (size_t op=0;op<AUDIO_OPERATOR_AMOUNT;op++) {
        outputs[op] = 0;
        frequencies[op] = Audio::tof16(memory.frequencies[op]) * base * float(UINT16_MAX)/float(44100);
        wave_types[op] = memory.wave_types[op];
    }
    for (size_t o1=0;o1<=AUDIO_OPERATOR_AMOUNT;o1++) {
        for (size_t o2=0;o2<AUDIO_OPERATOR_AMOUNT;o2++) {
           amplitudes[FM_MATRIX(o2, o1)] = Audio::tof16(memory.amplitudes[FM_MATRIX(o2, o1)]);
        }
    }

    for (size_t s=0;s<sample_count;s+=2) {
        int16_t delta = synthesize();
        int out;

        // Mixa o canal anterior e o novo
        out = int(delta) + int(samples[s]);

        if (out < INT16_MIN) {
            samples[s] = INT16_MIN;
        } else if (out > INT16_MAX) {
            samples[s] = INT16_MAX;
        } else {
            samples[s] = out;
        }

        samples[s+1] = samples[s];

        out = int(delta) + int(clean[s]);

        if (out < INT16_MIN) {
            clean[s] = INT16_MIN;
        } else if (out > INT16_MAX) {
            clean[s] = INT16_MAX;
        } else {
            clean[s] = out;
        }

        clean[s+1] = clean[s];
    }
}

inline int16_t FMSynthesizer::synthesize() {
    // Itera sobre a matriz de operadores
    for (size_t o1=0;o1<AUDIO_OPERATOR_AMOUNT;o1++) {
        uint16_t phase = times[o1];

        for (size_t o2=0;o2<AUDIO_OPERATOR_AMOUNT;o2++) {
            phase += outputs[o2]*amplitudes[FM_MATRIX(o2, o1)];
        }

        switch (wave_types[o1]) {
            default:
            case SINE:
                outputs[o1] = wave[phase] * envelopes[o1]->get_amplitude();
                break;
            case SQUARE:
                outputs[o1] = square_wave[phase] * envelopes[o1]->get_amplitude();
                break;
            case SAW:
                outputs[o1] = saw_wave[phase] * envelopes[o1]->get_amplitude();
                break;
            case TRIANGLE:
                outputs[o1] = triangle_wave[phase] * envelopes[o1]->get_amplitude();
                break;
        }
    }

    int16_t output = 0;

    for (size_t o=0;o<AUDIO_OPERATOR_AMOUNT;o++) {
        // Avança os acumuladores de cada operador
        times[o] += frequencies[o];

        int16_t delta = outputs[o] * amplitudes[FM_MATRIX(o, AUDIO_OPERATOR_AMOUNT)];

        // Mixa o operador anterior e o novo
        int out = delta + output;

        if (out < INT16_MIN) {
            output = INT16_MIN;
        } else if (out > INT16_MAX) {
            output = INT16_MAX;
        } else {
            output = out;
        }
    }

    return output;
}

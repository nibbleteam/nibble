#include <SFML/Audio.hpp>
#include <kernel/SquareWave.hpp>
#include <climits>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <map>
using namespace std;

SquareWave::SquareWave(uint8_t octave):
    t(0),
    amplitude(SHRT_MAX),
    period(fromFrequency(fromNote(10, 0))),
    // 120 bpm
    beatPeriod(fromFrequency(15.0/60)),
    clockPeriod(beatPeriod/4.0),
    duty(0.25),
    clockT(0),
    attack(100),
    decay(100),
    sustain(5000),
    release(10000),
    pattern({   0x01, 6, 0x04, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x01, 4, 0x04, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x01, 0, 0x04, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x01, 10, 0x03, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00,
                0x01, 0, 0x04, 0x00,
                0x00, 0x00, 0x00, 0x00,
                }) {
    map<string, uint8_t> n;

    n["A"] = 0;
    n["A#"] = 1;
    n["B"] = 2;
    n["C"] = 3;
    n["C#"] = 4;
    n["D"] = 5;
    n["D#"] = 6;
    n["E"] = 7;
    n["F"] = 8;
    n["F#"] = 9;
    n["G"] = 10;
    n["G#"] = 11;

    srand(time(NULL));
}

void SquareWave::changeParameters() {
    if (fmod(t, clockPeriod) < fmod(t-1, clockPeriod)) {
        auto ptr = (clockT*4)%256;

        pattern[ptr] = 1;

        switch(pattern[ptr]) {
            // No Op
        case 0:
            break;
            // Note
        case 1:
            cerr << ptr << "> note on <" << endl;
            period = fromFrequency(fromNote(0, rand()%12));
            adsr = 0;
            amplitude = SHRT_MAX;
            break;
        default:
            break;
        }

        clockT++;
    }
}

int16_t* SquareWave::fill(const unsigned int sampleCount) {
    for (unsigned int i=0;i<sampleCount;i++) {
        changeParameters();
        auto noisy = amplitude*0.5+amplitude*0.5*double(rand()%SHRT_MAX)/double(SHRT_MAX);
        samples[i] = fmod(t, period) > period*duty ? noisy : -noisy;

        if (adsr > 0 && adsr <= attack) {
            double p = double(adsr)/double(attack);

            amplitude = p*SHRT_MAX;
            vAttack = amplitude;
        } else if (adsr > attack && adsr <= attack+decay && decay != 0) {
            double p = double(adsr-attack)/double(decay);

            amplitude = p*(SHRT_MAX/2-vAttack)+vAttack;
            vDecay = amplitude;
        } else if (adsr > attack+decay+sustain &&
                   adsr <= attack+decay+sustain+release &&
                   release != 0) {
            double p = double(adsr-attack-decay-sustain)/double(release);

            amplitude = p*(-vDecay)+vDecay;
        }

        t++; adsr++;
    }

    return samples;
}

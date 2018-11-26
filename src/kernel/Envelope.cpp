#include <kernel/Envelope.hpp>
#include <kernel/drivers/Audio.hpp>

#include <iostream>
using namespace std;

Envelope::Envelope(int16_t* sustained,
                   int16_t* level,
                   int16_t* attack, int16_t* decay,
                   int16_t* sustain,
                   int16_t* release):
        sustained(sustained),
        status(ATTACK),
        level(level), sustain(sustain), attack(attack), decay(decay), release(release),
        amplitude(0), done(false) {
}

float Envelope::getAmplitude() {
    switch (status) {
        case ATTACK:
            if (*attack == 0) {
                amplitude = Audio::tof16(level);
            } else {
                amplitude += Audio::tof16(level)/Audio::tof16(attack)/44100.0;
            }

            if (amplitude >= Audio::tof16(level)) {
                amplitude = Audio::tof16(level);
                status = DECAY;
            }
            break;
        case DECAY:
            if (*decay == 0) {
                amplitude = Audio::tof16(sustain);
            } else {
                amplitude -= (Audio::tof16(level)-Audio::tof16(sustain))/Audio::tof16(decay)/44100;
            }

            if (amplitude <= Audio::tof16(sustain)) {
                amplitude = Audio::tof16(sustain);
                status = SUSTAIN;
            }
            break;
        case SUSTAIN:
            if (! (*sustained) ) {
                amplitude = Audio::tof16(sustain);
                status = RELEASE;
            }
            break;
        case RELEASE:
            if (*release == 0) {
                amplitude = 0;
            } else {
                amplitude -= Audio::tof16(sustain)/Audio::tof16(release)/44100;
            }

            if (amplitude <= 0) {
                amplitude = 0;
                done = true;
            }
            break;
    }

    return amplitude;
}

void Envelope::on() {
    status = ATTACK;
}

void Envelope::off() {
    status = RELEASE;
}

#include <kernel/Envelope.hpp>

#include <iostream>
using namespace std;

Envelope::Envelope(uint8_t* sustained,
                   uint8_t* level,
                   uint8_t* attack, uint8_t* decay,
                   uint8_t* sustain,
                   uint8_t* release):
        sustained(sustained),
        status(ATTACK),
        level(level), sustain(sustain),
        attack(attack), decay(decay), release(release),
        amplitude(0), done(false) {
}

float Envelope::getAmplitude() {
    switch (status) {
        case ATTACK:
            if (*attack == 0) {
                amplitude = tof(level);
            } else {
                amplitude += tof(level)/tof(attack)/44100.0;
            }

            if (amplitude >= tof(level)) {
                status = DECAY;
            }
            break;
        case DECAY:
            if (*decay == 0) {
                amplitude = tof(sustain);
            } else {
                amplitude -= (tof(level)-tof(sustain))/tof(decay)/44100;
            }

            if (amplitude <= tof(sustain)) {
                status = SUSTAIN;
            }
            break;
        case SUSTAIN:
            if (! (*sustained) ) {
                status = RELEASE;
            }
            break;
        case RELEASE:
            if (*release == 0) {
                amplitude = 0;
            } else {
                amplitude -= tof(sustain)/tof(release)/44100;
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

float Envelope::tof(uint8_t* n) {
    return float(*n)/255.0;
}

#include <kernel/Envelope.hpp>
#include <devices/Audio.hpp>

#include <iostream>
using namespace std;

Envelope::Envelope(MemoryLayout &memory):
    status(ATTACK),
    memory(memory),
    intensity(255),
    amplitude(0),
    done(false) { }

float Envelope::getAmplitude() {
    float level = Audio::tof16(memory.level)*float(intensity)/255.0;
    float sustain = Audio::tof16(memory.sustain);

    float attack = Audio::tof16(memory.attack);
    float decay = Audio::tof16(memory.decay);
    float release = Audio::tof16(memory.release);

    switch (status) {
        case ATTACK:
            if (memory.attack == 0) {
                amplitude = level;
            } else {
                amplitude += level/attack/44100.0;
            }

            if (amplitude >= level) {
                amplitude = level;
                status = DECAY;
            }
            break;
        case DECAY:
            if (memory.decay == 0) {
                amplitude = sustain;
            } else {
                amplitude -= (level-sustain)/decay/44100;
            }

            if (amplitude <= sustain) {
                amplitude = sustain;
                status = SUSTAIN;
            }
            break;
        case SUSTAIN:
            if (!memory.sustained) {
                amplitude = sustain;
                status = RELEASE;
            }
            break;
        case RELEASE:
            if (memory.release == 0) {
                amplitude = 0;
            } else {
                amplitude -= sustain/release/44100;
            }

            if (amplitude <= 0) {
                amplitude = 0;
                done = true;
            }
            break;
    }

    return amplitude;
}

void Envelope::on(uint8_t intensity) {
    status = ATTACK;
}

void Envelope::off() {
    status = RELEASE;
}

#include <kernel/Envelope.hpp>
#include <devices/Audio.hpp>

#include <iostream>
using namespace std;

Envelope::Envelope(MemoryLayout &memory): memory(memory), amplitude(0), done(false) { }

float Envelope::getAmplitude() {
    switch (status) {
        case ATTACK:
            if (memory.attack == 0) {
                amplitude = Audio::tof16(memory.level);
            } else {
                amplitude += Audio::tof16(memory.level)/Audio::tof16(memory.attack)/44100.0;
            }

            if (amplitude >= Audio::tof16(memory.level)) {
                amplitude = Audio::tof16(memory.level);
                status = DECAY;
            }
            break;
        case DECAY:
            if (memory.decay == 0) {
                amplitude = Audio::tof16(memory.sustain);
            } else {
                amplitude -= (Audio::tof16(memory.level)-Audio::tof16(memory.sustain))/Audio::tof16(memory.decay)/44100;
            }

            if (amplitude <= Audio::tof16(memory.sustain)) {
                amplitude = Audio::tof16(memory.sustain);
                status = SUSTAIN;
            }
            break;
        case SUSTAIN:
            if (!memory.sustained) {
                amplitude = Audio::tof16(memory.sustain);
                status = RELEASE;
            }
            break;
        case RELEASE:
            if (memory.release == 0) {
                amplitude = 0;
            } else {
                amplitude -= Audio::tof16(memory.sustain)/Audio::tof16(memory.release)/44100;
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

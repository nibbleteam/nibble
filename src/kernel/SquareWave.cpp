#include <SFML/Audio.hpp>
#include <kernel/SquareWave.hpp>
#include <climits>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <map>
using namespace std;

SquareWave::SquareWave(uint8_t* memory, uint64_t memoryLength, uint64_t memoryPosition):
    Wave(memory, memoryLength, memoryPosition) {
    int16_t v = SHRT_MIN;

    for (unsigned int i=0;i<64;i++) {
        lut[i] = v;
        v += SHRT_MAX/32;
    }
    for (unsigned int i=64;i<128;i++) {
        lut[i] = v;
        v += SHRT_MIN/32;
    }
}

int16_t* SquareWave::fill(const unsigned int sampleCount) {
    //sf::SoundBuffer b;

    for (unsigned int i=0;i<sampleCount;i++) {
        changeParameters();

        //samples[i] = fmod(t, period) > period*duty ? amplitude : -amplitude;
        //samples[i] = (fmod(t, period)/period*2-1)*amplitude;
        //samples[i] = (abs(fmod(t, period)-period/2)-period/4)*4*double(amplitude)/period;

        if (period != 0) {
            auto index = fmod(t+phase, period)/period;
            samples[i] = valueAt(index)*double(amplitude)/SHRT_MAX;
        }

        if (memory[confPosition+4] != 0) {
            t++; adsr++;
        }
    }

    //b.loadFromSamples(samples, sampleCount, 1, 41100);
    //b.saveToFile("audiocap.wav");

    return samples;
}

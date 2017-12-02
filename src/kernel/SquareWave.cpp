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
}

int16_t* SquareWave::fill(const unsigned int sampleCount) {
    for (unsigned int i=0;i<sampleCount;i++) {
        changeParameters();

        samples[i] = fmod(t, period) > period*duty ? amplitude : -amplitude;

        t++; adsr++;
    }

    return samples;
}

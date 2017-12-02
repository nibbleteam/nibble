#include <kernel/drivers/Audio.hpp>
#include <climits>
#include <cstring>
#include <cmath>
#include <iostream>
using namespace std;

const unsigned int Audio::sampleCount = 1024;

Audio::Audio(const uint64_t addr):
    address(addr) {
    samples = new int16_t[sampleCount];

    sndMemory = new uint8_t[SND_MEMORY_LENGTH];
    
	memset(sndMemory, 0, SND_MEMORY_LENGTH);
	
	wSquare = new SquareWave(sndMemory, SND_MEMORY_LENGTH, 0);
    wTriangle = new SquareWave(sndMemory, SND_MEMORY_LENGTH, 8);

    wTriangle->attack = 2000;
    wTriangle->decay = 2000;
    wTriangle->sustain = 3000;
    wTriangle->release = 4000;

    initialize(1, 44100);
}

Audio::~Audio() {
    delete wTriangle;
    delete wSquare;
    delete[] samples;
    delete[] sndMemory;
}

uint64_t Audio::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
	memcpy(sndMemory+p, data, size);
    return size;
}

uint64_t Audio::read(const uint64_t, uint8_t*, const uint64_t) {
    return 0;
}

bool Audio::onGetData(Audio::Chunk& chunk) {
    int16_t *s1 = wSquare->fill(sampleCount);
    int16_t *s2 = wTriangle->fill(sampleCount);

    for (unsigned int i=0;i<sampleCount;i++) {
        samples[i] = s1[i]/2 + s2[i]/2;
    }

    chunk.samples = samples;
    chunk.sampleCount = sampleCount;

    return true;
}

void Audio::onSeek(sf::Time) {
}

uint64_t Audio::addr() {
    return address;
}

uint64_t Audio::size() {
    return SND_MEMORY_LENGTH;
}

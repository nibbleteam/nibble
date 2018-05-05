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

	CA = new Channel(sndMemory, 0);
	CE = new Channel(sndMemory, 1);
	CI = new Channel(sndMemory, 2);
	CO = new Channel(sndMemory, 3);
	CU = new Channel(sndMemory, 4);

	S = new Channel(sndMemory, 5); 
	N = new Channel(sndMemory, 6);

    initialize(1, 44100);
}

Audio::~Audio() {
	delete CA;
	delete CE;
	delete CI;
	delete CO;
	delete CU;
	delete S;
	delete N;

    delete[] samples;
    delete[] sndMemory;
}

string Audio::name() {
	return "AUDIO";
}

uint64_t Audio::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
	memcpy(sndMemory+p, data, size);
    return size;
}

uint64_t Audio::read(const uint64_t, uint8_t*, const uint64_t) {
    return 0;
}

bool Audio::onGetData(Audio::Chunk& chunk) {
	// Generate
    int16_t *w1 = CA->fill(sampleCount);
    int16_t *w2 = CE->fill(sampleCount);
    int16_t *w3 = CI->fill(sampleCount);
    int16_t *w4 = CO->fill(sampleCount);
    int16_t *w5 = CU->fill(sampleCount);
    int16_t *w6 = S->fill(sampleCount);
    int16_t *w7 = N->fill(sampleCount);

	// Mix
    int16_t max = SHRT_MIN;
    int16_t min = SHRT_MAX;
    for (unsigned int i=0;i<sampleCount;i++) {
        samples[i] = w1[i]/7 + w2[i]/7 + w3[i]/7 + w4[i]/7 + w5[i]/7 + w6[i]/7 + w7[i]/7;

        if (samples[i] > max)
            max = samples[i];
        if (samples[i] < min)
            min = samples[i];
    }

    int amplitude = abs(min-max);
    int max_amplitude = SHRT_MAX;
    float mult = float(max_amplitude)/float(amplitude);

    for (unsigned int i=0;i<sampleCount;i++) {
        samples[i] *= mult;
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

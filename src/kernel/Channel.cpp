#include <kernel/Kernel.hpp>
#include <kernel/Channel.hpp>
#include <kernel/SquareWave.hpp>
#include <kernel/TriangleWave.hpp>
#include <kernel/NoiseWave.hpp>
#include <cstring>
#include <iostream>
using namespace std;

const uint16_t Channel::bytesPerChannel = 2;

Channel::Channel(uint8_t *mem, unsigned int channelNumber): nextTick(0), t(0), mem(mem), channelNumber(channelNumber) {
	srand(time(NULL));

	switch(rand()%3) {
		case 0:
			wave = new NoiseWave();
		break;
		case 1:
			wave = new TriangleWave();
		break;
		case 2:
			wave = new SquareWave();
		break;
		default:
		break;
	}

	// Frequência do tick em Hz
	calculateTickPeriod(60);
}

Channel::~Channel() {
	delete wave;
}

int16_t* Channel::fill(const unsigned int givenSampleCount) {
	unsigned int missingSampleCount = givenSampleCount;
	unsigned int initialT = t;
	
	do {
		if (t+missingSampleCount > nextTick) {
			unsigned int finalSampleCount = nextTick-t;

			memcpy(samples+(t-initialT),
				   wave->fill(finalSampleCount),
				   finalSampleCount*sizeof(int16_t));

			t = nextTick;
			missingSampleCount -= finalSampleCount;
			tick();
			calculateNextTick();
		} else {
			memcpy(samples+(t-initialT),
				   wave->fill(missingSampleCount),
				   missingSampleCount*sizeof(int16_t));

			t += missingSampleCount;
			missingSampleCount = 0;
		}
	} while (missingSampleCount > 0);
	
	return samples;
}

void Channel::calculateTickPeriod(const double frequency) {
	// Período em segundos
	const double period = 1/frequency;
	
	// Período em samples
	tickPeriod = (unsigned int) (period*44100);
}

void Channel::calculateNextTick() {
	nextTick += tickPeriod;
}

void Channel::tick() {
    KernelSingleton->audio_tick(channelNumber);

    uint8_t octave = read8(channelNumber*bytesPerChannel);
    uint8_t note = read8(channelNumber*bytesPerChannel+1);

    wave->period = wave->fromFrequency(wave->fromNote(octave, note));
}

uint8_t Channel::read8(uint16_t position) {
	return mem[position];
}

void Channel::write8(uint16_t position, uint8_t value) {
	mem[position] = value;
}

uint16_t Channel::read16(uint16_t position) {
	uint16_t value = mem[position];
	value = value<<8;
	value |= mem[position+1];

	return value;
}

void Channel::write16(uint16_t position, uint16_t value) {
	mem[position] = value >> 8;
	mem[position+1] = value&0xFF;
}

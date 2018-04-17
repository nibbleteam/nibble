#include <kernel/Channel.hpp>
#include <kernel/SquareWave.hpp>
#include <kernel/TriangleWave.hpp>
#include <kernel/NoiseWave.hpp>
#include <cstring>
#include <iostream>
using namespace std;

Channel::Channel(uint8_t *mem, unsigned int pc): nextTick(0), t(0), mem(mem), pcPosition(pc) {
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
	calculateTickPeriod(2);
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
	// Lê o program counter
	uint16_t PC = readPC();
	uint8_t cmd = mem[PC];
	uint8_t arg = mem[PC+1];

	switch (cmd) {
		case 0:
			wave->period = wave->fromFrequency(wave->fromNote(arg>>4, arg&0xF));
			break;
		default:
			break;
	}

	PC+=2;

	writePC(PC);
}

uint16_t Channel::readPC() {
	uint16_t PC = mem[pcPosition];
	PC = PC<<8;
	PC |= mem[pcPosition+1];

	return PC;
}

void Channel::writePC(uint16_t PC) {
	mem[pcPosition+0] = PC >> 8;
	mem[pcPosition+1] = PC&0xFF;
}

#include <kernel/Kernel.hpp>
#include <kernel/Channel.hpp>
#include <kernel/MultiWave.hpp>
#include <kernel/NoiseWave.hpp>
#include <cstring>
#include <iostream>
using namespace std;

const uint16_t Channel::bytesPerChannel = 4;

Channel::Channel(uint8_t *mem, unsigned int channelNumber): nextTick(0), t(0), mem(mem), channelNumber(channelNumber) {
	srand(time(NULL));

    if (channelNumber >= 0 && channelNumber <= 4) {
        wave = new MultiWave(MultiWave::SIN);
    } else if (channelNumber == 5) {
        // TODO: SampleWave aqui
        wave = new MultiWave(MultiWave::SIN);
    } else {
        wave = new NoiseWave();
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

    uint8_t waveTypeRaw = read8(channelNumber*bytesPerChannel);
    MultiWave::WaveType waveType = (MultiWave::WaveType)(waveTypeRaw%(MultiWave::PSIN+1));
    uint8_t volume = read8(channelNumber*bytesPerChannel+1);
    uint8_t octave = read8(channelNumber*bytesPerChannel+2);
    uint8_t note = read8(channelNumber*bytesPerChannel+3);

    if (uint8_t(wave->targetAmplitude*255) != volume) {
        wave->previousAmplitude = wave->amplitude;
        wave->targetAmplitude = double(volume)/255.0;
    }
    wave->period = wave->fromFrequency(wave->fromNote(octave, note));

    if (wave->type() == Wave::WAVE_CHANNEL) {
        MultiWave *multi = (MultiWave*)wave;

        if (waveType != multi->waveType)
            multi->setType(waveType);
    }
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

#include <kernel/drivers/Audio.hpp>
#include <kernel/Channel.hpp>
#include <cstring>
#include <cmath>
#include <iostream>
using namespace std;

// Envelope por operador + matriz de operadores + frequências + note samples memory + extra padding
const uint16_t Channel::bytesPerChannel = 256;

Channel::Channel(uint8_t *mem, unsigned int channelNumber):
    mem(mem),
    channelNumber(channelNumber),
    reverbPosition(0) {
    buffer = new int16_t[Audio::sampleCount*SND_POSTPROCESS_LENGTH];
    samples = new int16_t[Audio::sampleCount];

    memset(buffer, 0, Audio::sampleCount*SND_POSTPROCESS_LENGTH*sizeof(int16_t));
}

Channel::~Channel() {
    delete buffer;
    delete samples;
}

void Channel::fill(int16_t* output, const unsigned int sampleCount) {
    // Toca notas, máximo de 16 notas on/off
    for (size_t i=0;i<16*sizeof(int16_t);i+=sizeof(int16_t)) {
        switch (mem[96+i]) {
            case 1:
                press(mem[96+i+1]);
                mem[96+i] = 0;
                break;
            case 2:
                release(mem[96+i+1]);
                mem[96+i] = 0;
                break;
        }
    }

    memset(samples, 0, sampleCount*sizeof(int16_t));

    for (auto it=synthesizers.cbegin(); it != synthesizers.cend();) {
        if (it->second->done()) {
            delete it->second;
            synthesizers.erase(it++);
        } else {
            it->second->fill(output, samples, sampleCount);
            it++;
        }
    }

    reverb(output, samples, sampleCount);
}

void Channel::reverb(int16_t *output, int16_t *in, const unsigned int length) {
    int reverbDistance = max(min(SND_POSTPROCESS_LENGTH, int(mem[128])), 1)*1024;

    for (int i=0;i<int(length);i++) {
        int reverbSample = reverbPosition-reverbDistance;

        if (reverbSample < 0) {
            reverbSample += SND_POSTPROCESS_LENGTH*Audio::sampleCount;
        }

        int delta = buffer[reverbSample]*Audio::tof16(mem+129);

#ifdef _WIN32
        // TODO: Apenas usar um tipo maior para checar overflow nesse caso
        bool overflow;
        int16_t result = delta + output[i];

        if (delta < 0 && output[i] < 0) {
            overflow = result >= 0;
        } else if (delta > 0 && output[i] > 0) {
            overflow = result <= 0;
        }

        output[i] = result;
#else
        bool overflow = __builtin_add_overflow(delta, output[i], &output[i]);
#endif

        // Corta overflow
        if (overflow) {
            output[i] = (delta < 0) ? INT16_MIN : INT16_MAX;
        }

        int out = in[i]+delta;

        if (out < INT16_MIN) {
            out = INT16_MIN;
        } else if (out > INT16_MAX) {
            out = INT16_MAX;
        }

        buffer[reverbPosition] = out;

        reverbPosition += 1;

        if (reverbPosition >= int(SND_POSTPROCESS_LENGTH*Audio::sampleCount)) {
            reverbPosition = 0;
        }
    }
}

void Channel::press(uint8_t note) {
    if (synthesizers.find(note) == synthesizers.end()) {
        synthesizers.emplace(note, new FMSynthesizer(mem, note));
    } else {
        synthesizers[note]->on();
    }
}

void Channel::release(uint8_t note) {
    if (synthesizers.find(note) != synthesizers.end()) {
        synthesizers[note]->off();
    }
}

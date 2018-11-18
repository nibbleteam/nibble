#include <kernel/Channel.hpp>
#include <cstring>
#include <iostream>
using namespace std;

// Envelope por operador + matriz de operadores + frequências + note stream memory + extra padding
const uint16_t Channel::bytesPerChannel = 64;

Channel::Channel(uint8_t *mem, unsigned int channelNumber):
    mem(mem),
    channelNumber(channelNumber) {
}

Channel::~Channel() {
}

void Channel::fill(int16_t* samples, const unsigned int sampleCount) {
    if (mem[48] == 1) {
        press(mem[49]);
        mem[48] = 0;
    } else if (mem[48] == 2) {
        release(mem[49]);
        mem[48] = 0;
    }

    for (auto it=synthesizers.cbegin(); it != synthesizers.cend();) {
        if (it->second->done()) {
            delete it->second;
            synthesizers.erase(it++);
        } else {
            it->second->fill(samples, sampleCount);
            it++;
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

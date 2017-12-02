#include <kernel/Wave.hpp>
#include <cmath>
#include <climits>
#include <iostream>
using namespace std;

double Wave::fromFrequency(double f) {
    return 44100.0/f;
}

double Wave::fromNote(uint8_t o, uint8_t n) {
    uint16_t p = uint16_t(o)*12+uint16_t(n);
    // Distância para A4
    int16_t d = p - 48;

    return 440.0*pow(1.059463094359, double(d));
}

Wave::Wave(uint8_t *mem, uint64_t len, uint64_t pos):
    t(0), amplitude(SHRT_MAX), period(0), beatPeriod(fromFrequency(120.0/60.0)),
    clockPeriod(beatPeriod/4.0), duty(0.5),
    attack(0), decay(0), sustain(0), release(0),
    memory(mem), memoryLength(len), confPosition(pos) {
}

void Wave::changeParameters() {
    if (!memory[confPosition+4])
        return;
	
    if (fmod(t, clockPeriod) < fmod(t-1, clockPeriod)) {
		uint32_t base =
            memory[confPosition+0]<<24 |
            memory[confPosition+1]<<16 |
            memory[confPosition+2]<<8  |
            memory[confPosition+3];
        auto ptr = base%memoryLength;

        switch(memory[ptr]) {
            // No Op
        case 0:
            break;
            // Note
        case 1:
            period = fromFrequency(fromNote(memory[ptr+2], memory[ptr+1]));
            //period = fromFrequency(fromNote(4, rand()%12));
			adsr = 0;
            amplitude = SHRT_MAX;
            break;
            // Jump
        case 2:
            memory[ptr] = 0;
            ptr =
                memory[ptr+1]<<16 |
                memory[ptr+2]<<8  |
                memory[ptr+3];
            break;
        case 3:
            memory[confPosition+4] = 0;
            amplitude = 0;
        case 4:
            ptr =
                memory[ptr+1]<<16 |
                memory[ptr+2]<<8  |
                memory[ptr+3];
        default:
            break;
        }

        ptr+=4;
        memory[confPosition+0] = (ptr>>24)&0xFF;
        memory[confPosition+1] = (ptr>>16)&0xFF;
        memory[confPosition+2] = (ptr>>8)&0xFF;
        memory[confPosition+3] = (ptr)&0xFF;
    }

    if (adsr > 0 && adsr <= attack && attack != 0) {
        double p = double(adsr)/double(attack);

        amplitude = p*SHRT_MAX;
        vAttack = amplitude;
    } else if (adsr > attack && adsr <= attack+decay && decay != 0) {
        double p = double(adsr-attack)/double(decay);

        amplitude = p*(SHRT_MAX/2-vAttack)+vAttack;
        vDecay = amplitude;
    } else if (adsr > attack+decay+sustain &&
               adsr <= attack+decay+sustain+release &&
               release != 0) {
        double p = double(adsr-attack-decay-sustain)/double(release);

        amplitude = p*(-vDecay)+vDecay;
    }
}

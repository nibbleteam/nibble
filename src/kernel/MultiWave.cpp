#include <kernel/MultiWave.hpp>
#define _USE_MATH_DEFINES
#include <math.h>
#include <climits>
#include <cstdlib>
#include <iostream>
using namespace std;

MultiWave::MultiWave(WaveType waveType):
    Wave(), waveType(waveType) {
	amplitude = 0;

    fillLUT();
}

Wave::ChannelType MultiWave::type() {
    return WAVE_CHANNEL;
}

void MultiWave::setType(WaveType waveType) {
    this->waveType = waveType;

    fillLUT();
}

void MultiWave::fillLUT() {
    switch (waveType) {
        case SQUARE:
            fillSquare();
            break;
        case TRIANGLE:
            fillTriangle();
            break;
        case SAW:
            fillSaw();
            break;
        case SIN:
            fillSin();
            break;
        case PSIN:
            fillPSin();
            break;
    }
}

void MultiWave::fillSquare() {
    for (unsigned int i=0;i<WAVE_LUT_SIZE/2;i++) {
        lut[i] = SHRT_MIN;
    }
    for (unsigned int i=WAVE_LUT_SIZE/2;i<WAVE_LUT_SIZE;i++) {
        lut[i] = SHRT_MAX;
    }
}

void MultiWave::fillTriangle() {
	int16_t v = SHRT_MIN;

    for (unsigned int i=0;i<WAVE_LUT_SIZE/2;i++) {
        lut[i] = v;
		v += SHRT_MAX/WAVE_LUT_SIZE*4;
    }
    for (unsigned int i=WAVE_LUT_SIZE/2;i<WAVE_LUT_SIZE;i++) {
        lut[i] = v;
		v -= SHRT_MAX/WAVE_LUT_SIZE*4;
    }
}

void MultiWave::fillSaw() {
    int16_t v = SHRT_MAX;

    for (unsigned int i=0;i<WAVE_LUT_SIZE;i++) {
        lut[i] = v;

        v -= SHRT_MAX/WAVE_LUT_SIZE*2;
    }
}

void MultiWave::fillSin() {
   for (unsigned int i=0;i<WAVE_LUT_SIZE;i++) {
        lut[i] = sin(double(i)/double(WAVE_LUT_SIZE)*M_PI*2)*SHRT_MAX;
   }
}

void MultiWave::fillPSin() {
   for (unsigned int i=0;i<WAVE_LUT_SIZE;i++) {
        lut[i] = abs(sin(double(i)/double(WAVE_LUT_SIZE)*M_PI*2))*SHRT_MAX;
   }
}

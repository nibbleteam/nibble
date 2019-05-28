#define _USE_MATH_DEFINES
#include <cmath>
#include <kernel/Wave.hpp>
#include <algorithm>
#include <numeric>

#include <iostream>
using namespace std;

Wave::Wave() {
    // Fill a quarter sine wave
    for (size_t i=0;i<NIBBLE_WAVETABLE_SIZE;i++) {
        float t = float(i)/float(NIBBLE_WAVETABLE_SIZE)*M_PI/2;
        table[i] = sin(t) * INT16_MAX;
    }
}

const int16_t Wave::value_at(uint8_t t) const {
    const static uint16_t f = 4*NIBBLE_WAVETABLE_SIZE;
    const static uint8_t h = 2*NIBBLE_WAVETABLE_SIZE;
    const static uint8_t q = 1*NIBBLE_WAVETABLE_SIZE;

    if (t < q) {
        return table[t];
    } else if (t < h) {
        return table[h-t-1];
    } else if (t < 3*q) {
        return -table[t-h-1];
    } else {
        return -table[f-t-1];
    }
}

const int16_t Wave::operator[](uint16_t t) const {
    uint8_t t0 = t >> 8;
    uint8_t t1 = t0+1;

    int16_t a = value_at(t0);
    int16_t b = value_at(t1);

    float d0 = float(t-(t0<<8))/256.0;

    return b*d0+a*(1-d0);
}

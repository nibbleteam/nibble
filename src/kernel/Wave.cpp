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

const int16_t Wave::valueAt(uint8_t t) const {
    int it = t;
    int f = 256;
    int h = 128;
    int q = 64;

    if (it < q) {
        return table[it];
    } else if (it < h) {
        return table[h-it-1];
    } else if (it < 3*q) {
        return -table[it-h-1];
    } else {
        return -table[f-it-1];
    }
}

const int16_t Wave::operator[](uint16_t t) const {
    uint8_t t0 = t >> 8;
    uint8_t t1 = t0+1;

    int16_t a = valueAt(t0);
    int16_t b = valueAt(t1);

    float d0 = float(t-(t0<<8))/256.0;

    return b*d0+a*(1-d0);
}

//const int16_t Wave::operator[](float t) const {
//    float t0 = floor(t);
//    float t1 = t0+1;
//
//    float d0 = t-t0;
//
//    float ya = _at(t0-1);
//    float yb = _at(t0);
//    float yc = _at(t1);
//    float yd = _at(t1+1);
//    // Linear
//    return yc*d0+yb*(1.0-d0);
//    // Hermite
//    //float c0 = yb;
//    //float c1 = .5F * (yc - ya);
//    //float c2 = ya - (2.5F * yb) + (2 * yc) - (.5F * yd);
//    //float c3 = (.5F * (yd - ya)) + (1.5F * (yb - yc));
//    //return (((((c3 * d0) + c2) * d0) + c1) * d0) + c0;
//}

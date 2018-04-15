#include <SFML/Audio.hpp>
#include <kernel/SquareWave.hpp>
#include <climits>
#include <cmath>
#include <cstdlib>
#include <iostream>
#include <map>
using namespace std;

SquareWave::SquareWave():
    Wave() {
	// Preenche a look up table
    for (unsigned int i=0;i<WAVE_LUT_SIZE/2;i++) {
        lut[i] = SHRT_MIN;
    }
    for (unsigned int i=WAVE_LUT_SIZE/2;i<WAVE_LUT_SIZE;i++) {
        lut[i] = SHRT_MAX;
    }
}

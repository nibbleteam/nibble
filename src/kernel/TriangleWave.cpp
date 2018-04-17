#include <kernel/TriangleWave.hpp>
#include <cmath>
#include <climits>
#include <cstdlib>
using namespace std;

TriangleWave::TriangleWave():
    Wave() {
	int16_t v = SHRT_MIN;

	// Preenche a look up table
    for (unsigned int i=0;i<WAVE_LUT_SIZE/2;i++) {
        lut[i] = v;
		v += SHRT_MAX/WAVE_LUT_SIZE*2;
    }
    for (unsigned int i=WAVE_LUT_SIZE/2;i<WAVE_LUT_SIZE;i++) {
        lut[i] = v;
		v -= SHRT_MAX/WAVE_LUT_SIZE*2;
    }
}

#include <kernel/Wave.hpp>

class NoiseWave: public Wave {
public:
	NoiseWave();

	int16_t* fill(const unsigned int);
};

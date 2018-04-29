#include <kernel/Wave.hpp>

class NoiseWave: public Wave {
public:
	NoiseWave();
    ChannelType type();

	int16_t* fill(const unsigned int);
};

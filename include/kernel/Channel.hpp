#ifndef CHANNEL_H
#define CHANNEL_H

#include <kernel/Wave.hpp>

class Channel {
    int16_t samples[MAX_WAVE_SAMPLES];
	unsigned int nextTick, tickPeriod;
	unsigned int t;

	uint8_t *mem;
	unsigned int pcPosition;

	Wave *wave;
public:
	Channel(uint8_t*, unsigned int);
	~Channel();

	int16_t *fill(const unsigned int); 
private:
	// Sinal de clock para mudar os parâmetros da onda
	void tick();
	void calculateTickPeriod(const double);
	void calculateNextTick();

	uint16_t readPC();
	void writePC(uint16_t);
};

#endif /* CHANNEL_H */

#ifndef CHANNEL_H
#define CHANNEL_H

#include <kernel/Wave.hpp>

class Channel {
    const static uint16_t bytesPerChannel;

    int16_t samples[MAX_WAVE_SAMPLES];
	unsigned int nextTick, tickPeriod;
	unsigned int t;

	uint8_t *mem;
	unsigned int channelNumber;

	Wave *wave;
public:
	Channel(uint8_t*, unsigned int);
	~Channel();

	int16_t *fill(const unsigned int); 
private:
	// Sinal de clock para mudar os parâmetros da onda
    // chama uma callback no cart atual
	void tick();
	void calculateTickPeriod(const double);
	void calculateNextTick();

    uint8_t read8(uint16_t);
    void write8(uint16_t, uint8_t);
    
    uint16_t read16(uint16_t);
    void write16(uint16_t, uint16_t);
};

#endif /* CHANNEL_H */

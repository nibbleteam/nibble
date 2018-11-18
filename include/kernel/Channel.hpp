#ifndef CHANNEL_H
#define CHANNEL_H

#include <kernel/FMSynthesizer.hpp>
#include <kernel/Wave.hpp>
#include <map>
using namespace std;

class Channel {
	uint8_t *mem;
	unsigned int channelNumber;

    map<uint8_t, FMSynthesizer*> synthesizers;
public:
    const static uint16_t bytesPerChannel;

	Channel(uint8_t*, unsigned int);
	~Channel();

	void fill(int16_t*, const unsigned int); 

    void press(uint8_t);
    void release(uint8_t);
};

#endif /* CHANNEL_H */

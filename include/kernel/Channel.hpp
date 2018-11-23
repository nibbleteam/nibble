#ifndef CHANNEL_H
#define CHANNEL_H

#include <kernel/FMSynthesizer.hpp>
#include <kernel/Wave.hpp>
#include <map>
using namespace std;

// Número de "frames" de áudio completas a serem
// guardadas
#define SND_POSTPROCESS_LENGTH   64

class Channel {
	uint8_t *mem;
	unsigned int channelNumber;

    // Sintetizadores (para permitir polifonia)
    map<uint8_t, FMSynthesizer*> synthesizers;

    // Para efeitos de pós processamento
    int16_t *samples;
    int16_t *buffer;

    // Reverb
    int reverbPosition;
public:
    const static uint16_t bytesPerChannel;

	Channel(uint8_t*, unsigned int);
	~Channel();

	void fill(int16_t*, const unsigned int); 

    void press(uint8_t);
    void release(uint8_t);
private:
    void reverb(int16_t*, int16_t*, const unsigned int);
};

#endif /* CHANNEL_H */

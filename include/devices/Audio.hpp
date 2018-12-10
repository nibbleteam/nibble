#ifndef AUDIO_H
#define AUDIO_H

#include <array>

#include <SFML/Audio.hpp>

#include <Specs.hpp>

#include <kernel/Channel.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

using namespace std;

class Audio : public Device, public sf::SoundStream {
    // Samples
    int16_t* samples;

	// Canais FM
	array<unique_ptr<Channel>, AUDIO_CHANNEL_AMOUNT> channels;

    // Tick
	unsigned long nextTick, tickPeriod;
	unsigned long t;
public:
    Audio(Memory&);

    void startup();
    void shutdown();
private:
	// Sinal de clock para mudar os parâmetros da onda
    // chama uma callback no cart atual
	void calculateTickPeriod(const double);
	void calculateNextTick();

    // Prepara samples mixados
    void mix(int16_t*, unsigned int);

    bool onGetData(Chunk&);
    void onSeek(sf::Time);
public:
    static float tof(uint8_t);
    static float tof16(const uint8_t*);
    static float tof16(const int16_t*);
    static float tof16(const int16_t&);
};

#endif /* AUDIO_H */

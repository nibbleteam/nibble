#ifndef AUDIO_H
#define AUDIO_H

#include <array>

#include <SDL.h>

#include <Specs.hpp>

#include <kernel/Channel.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

using namespace std;

class Audio : public Device {
	// Canais FM
	array<unique_ptr<Channel>, AUDIO_CHANNEL_AMOUNT> channels;

    // Tick
	unsigned long nextTick, tickPeriod;
	unsigned long t;

    // ID da placa de áudio
    SDL_AudioDeviceID device;
public:
    Audio(Memory&);
    ~Audio();

    void startup();
    void shutdown();
private:
    // Inicializa placa de áudio
    SDL_AudioDeviceID initialize();

	// Sinal de clock para mudar os parâmetros da onda
    // chama uma callback no cart atual
	void calculateTickPeriod(const double);
	void calculateNextTick();

    // Prepara samples mixados
    void mix(int16_t*, unsigned int);

    // TODO
    void fill(int16_t*, int);
public:
    static float tof(uint8_t);
    static float tof16(const uint8_t*);
    static float tof16(const int16_t*);
    static float tof16(const int16_t&);
};

#endif /* AUDIO_H */

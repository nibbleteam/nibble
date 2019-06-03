#ifndef AUDIO_H
#define AUDIO_H

#include <array>

#include <SDL.h>

#include <Specs.hpp>

#include <kernel/Channel.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

using namespace std;

class Audio: public Device {
    // Canais FM
    array<unique_ptr<Channel>, AUDIO_CHANNEL_AMOUNT> channels;

    // Tick
    uint64_t next_tick, tick_period;
    uint64_t *t;

    // ID da placa de áudio
    SDL_AudioDeviceID device;
public:
    Audio(Memory&);
    ~Audio();

    void startup();
    void shutdown();

    // Preenche buffer com samples e chama o tick de áudio para
    // mudar parâmetros, se necessário (usando as funções calc_*)
    void fill(int16_t*, int);
private:
    // Inicializa placa de áudio
    SDL_AudioDeviceID initialize();

    // Sinal de clock para mudar os parâmetros da onda
    // chama uma callback no cart atual
    void calc_tick_period(const double);
    void calc_next_tick();

    // Prepara samples mixados
    void mix(int16_t*, unsigned int);

    // Checa timestamps dos comandos nas filas
    // de cada canal e os executa se >= ao tempo atual
    void execute_commands(const uint64_t);
public:
    // Adiciona comando a um canal
    void enqueue_command(const uint64_t,
                         const uint8_t,
                         const uint8_t,
                         const uint8_t,
                         const uint8_t);
    static float tof(uint8_t);
    static float tof16(const uint8_t*);
    static float tof16(const int16_t*);
    static float tof16(const int16_t&);
};

#endif /* AUDIO_H */

#include <kernel/Kernel.hpp>
#include <devices/Audio.hpp>
#include <climits>
#include <cstring>
#include <cmath>
#include <iostream>
using namespace std;

Audio::Audio(Memory &memory): next_tick(0) {
    // Cria canais
    for (size_t ch=0;ch<AUDIO_CHANNEL_AMOUNT;ch++) {
        channels[ch] = make_unique<Channel>(memory);
    }

    t = (uint64_t*)memory.allocate(sizeof(uint64_t), "Audio Sample Register");
    *t = 0;

    // Calcula velocidade da sincronização
    calc_tick_period(AUDIO_UPDATE_RATE);

    device = initialize();
}

Audio::~Audio() {
    SDL_CloseAudioDevice(device);
}

SDL_AudioDeviceID Audio::initialize() {
    SDL_AudioDeviceID device;
    // Especifificações que queremos, especificações que conseguimos
    SDL_AudioSpec spec_in, spec_out;
    // Limpa os specs
    SDL_zero(spec_in);
    // Escolhe nosso spec
    spec_in.freq     = AUDIO_SAMPLE_RATE;
    spec_in.format   = AUDIO_S16SYS;
    spec_in.channels = 2;
    spec_in.samples  = AUDIO_SAMPLE_AMOUNT;

    spec_in.callback = [] (void *udata, Uint8 *stream, int len) {
        ((Audio*)udata)->fill((int16_t*)stream, len/2);
    };

    spec_in.userdata = (void*)this;

#ifdef WIN32
    SDL_setenv("SDL_AUDIODRIVER", "dsound", true);
#elif __APPLE__
#else
    SDL_setenv("SDL_AUDIODRIVER", "alsa", true);
#endif

    // Open the device
    device = SDL_OpenAudioDevice(nullptr, 0, &spec_in, &spec_out, SDL_AUDIO_ALLOW_ANY_CHANGE);
    //device = SDL_OpenAudioDevice(nullptr, 0, &spec_in, &spec_out, SDL_AUDIO_ALLOW_ANY_CHANGE);

    cout << "[nibble] audio: freq: " << spec_out.freq << endl;
    cout << "[nibble] audio: ch: " << (int)spec_out.channels << endl;
    cout << "[nibble] audio: format: " << (int)spec_out.format << ", " << (int)spec_in.format << endl;
    cout << "[nibble] audio: samples: " << spec_out.samples << endl;

    if (!device) {
        /* TODO: Error!! */
    }

    return device;
}

void Audio::startup() {
    SDL_PauseAudioDevice(device, 0);
}

void Audio::shutdown() {
    SDL_PauseAudioDevice(device, 1);
}

void Audio::fill(int16_t *samples, int missing_sample_count) {
    unsigned int initial_t = *t;

    memset(samples, 0, AUDIO_SAMPLE_MEM_SIZE*2);

    // Preenche o buffer "samples"
    do {
        // Caso o tick precise ser rodado antes
        // de completar todos os samples
        if (*t+missing_sample_count > next_tick) {
            unsigned int final_sample_count = ((next_tick-*t)/2)*2;

            mix(samples+(*t-initial_t), final_sample_count);

            *t += final_sample_count;
            missing_sample_count -= final_sample_count;

            // Roda o tick
            execute_commands(*t);

            calc_next_tick();
        } else {
            mix(samples+(*t-initial_t), missing_sample_count);

            *t += missing_sample_count;
            missing_sample_count = 0;
            break;
        }
    } while (missing_sample_count > 0);
}

void Audio::mix(int16_t* samples, unsigned int sample_count) {
    // Preenche samples de cada canal
    for (unsigned int c=0;c<AUDIO_CHANNEL_AMOUNT;c++) {
        channels[c]->fill(samples, sample_count);
    }
}

void Audio::calc_tick_period(const double frequency) {
    // Período em segundos
    const double period = 1/frequency;

    // Período em samples
    tick_period = (unsigned int) (period*44100);
}

void Audio::calc_next_tick() {
    next_tick += tick_period;
}

void Audio::execute_commands(const uint64_t t) {
    for (size_t ch=0;ch<AUDIO_CHANNEL_AMOUNT;ch++) {
        channels[ch]->execute_commands(t);
    }
}

void Audio::enqueue_command(const uint64_t timestamp,
                            const uint8_t ch,
                            const uint8_t cmd,
                            const uint8_t note,
                            const uint8_t intensity) {
    channels[ch%AUDIO_CHANNEL_AMOUNT]->enqueue_command(timestamp, cmd, note, intensity);
}

float Audio::tof(uint8_t n) {
    return float(n)/255.0;
}

float Audio::tof16(const uint8_t *buffer) {
    return float(*(int16_t*)buffer)/float(0xFF);
}

float Audio::tof16(const int16_t *buffer) {
    return tof16((uint8_t*)buffer);
}

float Audio::tof16(const int16_t &buffer) {
    return tof16(&buffer);
}

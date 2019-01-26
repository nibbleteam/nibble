#include <kernel/Kernel.hpp>
#include <devices/Audio.hpp>
#include <climits>
#include <cstring>
#include <cmath>
#include <iostream>
using namespace std;

Audio::Audio(Memory &memory): nextTick(0), t(0) {
    // Cria canais
    for (size_t ch=0;ch<AUDIO_CHANNEL_AMOUNT;ch++) {
        channels[ch] = make_unique<Channel>(memory);
    }

    // Calcula velocidade da sincronização
    calculateTickPeriod(AUDIO_UPDATE_RATE);

    device = initialize();
}

Audio::~Audio() {
    SDL_CloseAudioDevice(device);
}

SDL_AudioDeviceID Audio::initialize() {
  SDL_AudioDeviceID device;
  // Especifificações que queremos, especificações que conseguimos
  SDL_AudioSpec specIn, specOut;
  // Limpa os specs
  SDL_zero(specIn);
  // Escolhe nosso spec
  specIn.freq     = AUDIO_SAMPLE_RATE;
  specIn.format   = AUDIO_S16;
  specIn.channels = 2;
  specIn.samples  = AUDIO_SAMPLE_AMOUNT;

  specIn.callback = [] (void *udata, Uint8 *stream, int len) {
    ((Audio*)udata)->fill((int16_t*)stream, len/2);
  };
  specIn.userdata = (void*)this;

  // Open the device
  device = SDL_OpenAudioDevice(nullptr, 0, &specIn, &specOut, SDL_AUDIO_ALLOW_ANY_CHANGE);

  cout << "[nibble] audio: freq: " << specOut.freq << endl;
  cout << "[nibble] audio: ch: " << (int)specOut.channels << endl;
  cout << "[nibble] audio: samples: " << specOut.samples << endl;

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

void Audio::fill(int16_t *samples, int missingSampleCount) {
    return;

    unsigned int initialT = t;

    memset(samples, 0, AUDIO_SAMPLE_MEM_SIZE);

    // Preenche o buffer "samples"
    do {
        // Caso o tick precise ser rodado antes
        // de completar todos os samples
        if (t+missingSampleCount > nextTick) {
            unsigned int finalSampleCount = ((nextTick-t)/2)*2;

            mix(samples+(t-initialT), finalSampleCount);

            t += finalSampleCount;
            missingSampleCount -= finalSampleCount;

            auto kernel = KernelSingleton.lock();

            if (kernel) {
                kernel->audioTick();
            }

            calculateNextTick();
        } else {
            mix(samples+(t-initialT), missingSampleCount);

            t += missingSampleCount;
            missingSampleCount = 0;
            break;
        }
    } while (missingSampleCount > 0);
}

void Audio::mix(int16_t* samples, unsigned int sampleCount) {
    // Preenche samples de cada canal
    for (unsigned int c=0;c<AUDIO_CHANNEL_AMOUNT;c++) {
        channels[c]->fill(samples, sampleCount);
    }
}

void Audio::calculateTickPeriod(const double frequency) {
    // Período em segundos
    const double period = 1/frequency;
    
    // Período em samples
    tickPeriod = (unsigned int) (period*44100);
}

void Audio::calculateNextTick() {
    nextTick += tickPeriod;
}

float Audio::tof(uint8_t n) {
    return float(n)/255.0;
}

float Audio::tof16(const uint8_t *buffer) {
    return float(
                int16_t(
                    uint16_t(buffer[0]&0b01111111)<<8 | uint16_t(buffer[1])
                ) * (buffer[0]&0x80 ? -1 : 1)
           )/float(0xFF);
}

float Audio::tof16(const int16_t *buffer) {
    return tof16((uint8_t*)buffer);
}

float Audio::tof16(const int16_t &buffer) {
    return tof16(&buffer);
}

#include <kernel/Kernel.hpp>
#include <devices/Audio.hpp>
#include <climits>
#include <cstring>
#include <cmath>
#include <iostream>
using namespace std;

Audio::Audio(Memory &memory): nextTick(0), t(0) {
    // Aloca memória
    samples = (int16_t*)memory.allocate(AUDIO_SAMPLE_MEM_SIZE, "Audio Samples Buffer");

    // Cria canais
    for (size_t ch=0;ch<AUDIO_CHANNEL_AMOUNT;ch++) {
        channels[ch] = make_unique<Channel>(memory);
    }

    // Calcula velocidade da sincronização
    calculateTickPeriod(AUDIO_UPDATE_RATE);

    // Inicializa a placa de áudio
    initialize(1, AUDIO_SAMPLE_RATE);
}

void Audio::startup() {
    play();
}

void Audio::shutdown() {
    stop();
}

bool Audio::onGetData(Audio::Chunk& chunk) {
    unsigned int missingSampleCount = AUDIO_SAMPLE_AMOUNT;
    unsigned int initialT = t;

    memset(samples, 0, AUDIO_SAMPLE_MEM_SIZE);

    // Preenche o buffer "samples"
    do {
        // Caso o tick precise ser rodado antes
        // de completar todos os samples
        if (t+missingSampleCount > nextTick) {
            unsigned int finalSampleCount = nextTick-t;

            mix(samples+(t-initialT), finalSampleCount);

            t = nextTick;
            missingSampleCount -= finalSampleCount;

            //auto kernel = KernelSingleton.lock();

            //if (kernel) {
            //    kernel->audioTick();
            //}

            calculateNextTick();
        } else {
            mix(samples+(t-initialT), missingSampleCount);

            t += missingSampleCount;
            missingSampleCount = 0;
            break;
        }
    } while (missingSampleCount > 0);

    // Passa informações sobre os samples para a placa de áudio
    chunk.samples = samples;
    chunk.sampleCount = AUDIO_SAMPLE_AMOUNT;

    return true;
}

void Audio::mix(int16_t* samples, unsigned int sampleCount) {
    // Preenche samples de cada canal
    for (unsigned int c=0;c<AUDIO_CHANNEL_AMOUNT;c++) {
        channels[c]->fill(samples, sampleCount);
    }
}

void Audio::onSeek(sf::Time) { }

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

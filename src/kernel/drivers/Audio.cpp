#include <kernel/Kernel.hpp>
#include <kernel/drivers/Audio.hpp>
#include <climits>
#include <cstring>
#include <cmath>
#include <iostream>
using namespace std;

const unsigned int Audio::sampleCount = 2048;

Audio::Audio(const uint64_t addr):
    address(addr), nextTick(0), t(0), playing(true) {
    samples = new int16_t[sampleCount];

    // Área de memória acessável para programas Lua
    const auto sndMemorySize = SND_CHANNELS*Channel::bytesPerChannel;
    sndMemory = new uint8_t[sndMemorySize];
    memset(sndMemory, 0, sndMemorySize);

    // Cria canais
    for (unsigned int i=0;i<SND_CHANNELS;i++) {
        channels[i] = new Channel(sndMemory+i*Channel::bytesPerChannel, i);
    }

    // Inicializa a placa de áudio
    initialize(1, 44100);

    calculateTickPeriod(60.0);
}

Audio::~Audio() {
    delete samples;

    // Libera memória dos canais
    for (unsigned int i=0;i<SND_CHANNELS;i++) {
        delete channels[i];
    }

    // Libera memória dos registradores/mapa de memória
    delete[] sndMemory;
}

string Audio::name() {
	return "AUDIO";
}

uint64_t Audio::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
	memcpy(sndMemory+p, data, size);
    return size;
}

uint64_t Audio::read(const uint64_t p, uint8_t* data, const uint64_t size) {
    memcpy(data, sndMemory+p, size);
    return 0;
}

bool Audio::onGetData(Audio::Chunk& chunk) {
	unsigned int missingSampleCount = sampleCount;
	unsigned int initialT = t;

    memset(samples, 0, sizeof(int16_t)*sampleCount);

    // Preenche o buffer "samples"
	do {
        // Caso o tick precise ser rodado antes
        // de completar todos os samples
		if (t+missingSampleCount > nextTick) {
			unsigned int finalSampleCount = nextTick-t;

            mix(samples+(t-initialT), finalSampleCount);

			t = nextTick;
			missingSampleCount -= finalSampleCount;

			tick();
			calculateNextTick();
		} else {
            mix(samples+(t-initialT), missingSampleCount);

			t += missingSampleCount;
			missingSampleCount = 0;
            break;
		}
	} while (missingSampleCount > 0);
    
    // TODO: Slides

    // TODO: Arppegiator
    
    // TODO: Efeitos

    // Passa informações sobre os samples para a placa de áudio
    chunk.samples = samples;
    chunk.sampleCount = sampleCount;

    return playing;
}

void Audio::exit() {
    playing = false;
}

void Audio::mix(int16_t* samples, unsigned int sampleCount) {
    // Preenche samples de cada canal
    for (unsigned int c=0;c<SND_CHANNELS;c++) {
        channels[c]->fill(samples, sampleCount);
    }
}

void Audio::onSeek(sf::Time) {
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

void Audio::tick() {
    KernelSingleton->audio_tick();
}

uint64_t Audio::addr() {
    return address;
}

uint64_t Audio::size() {
    return SND_MEMORY_LENGTH;
}

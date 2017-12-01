#include <kernel/drivers/Audio.hpp>
#include <climits>
#include <cmath>

const unsigned int Audio::sampleCount = 1024;

Audio::Audio(const uint64_t addr):
    address(addr),
    wSquare(4),
    wSquare2(3) {
    samples = new int16_t[sampleCount];

    initialize(1, 44100);
}

Audio::~Audio() {
    delete[] samples;
}

uint64_t Audio::write(const uint64_t, const uint8_t* cmd, const uint64_t size) {
    return 0;
}

uint64_t Audio::read(const uint64_t, uint8_t*, const uint64_t) {
    return 0;
}

bool Audio::onGetData(Audio::Chunk& chunk) {
    int16_t *s1 = wSquare2.fill(sampleCount);
    //int16_t *s2 = wSquare.fill(sampleCount);

    for (unsigned int i=0;i<sampleCount;i++) {
        samples[i] = s1[i];
    }

    chunk.samples = samples;
    chunk.sampleCount = sampleCount;

    return true;
}

void Audio::onSeek(sf::Time) {
}

uint64_t Audio::addr() {
    return address;
}

uint64_t Audio::size() {
    return 32;
}

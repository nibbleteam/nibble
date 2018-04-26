#ifndef AUDIO_H
#define AUDIO_H

#include <kernel/Channel.hpp>
#include <kernel/Memory.hpp>
#include <kernel/SquareWave.hpp>
#include <kernel/TriangleWave.hpp>
#include <SFML/Audio.hpp>

#define SND_MEMORY_LENGTH 14

class Audio : public Memory, public sf::SoundStream {
    const static unsigned int sampleCount;
    const uint64_t address;
    int16_t *samples;

	// Multiuso
	Channel *CA, *CE, *CI, *CO, *CU;
	// Samples
	Channel *S;
	// Noise
	Channel *N;

    uint8_t *sndMemory;
public:
    Audio(const uint64_t);
    ~Audio();

	string name();
    
    uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
    uint64_t read(const uint64_t, uint8_t*, const uint64_t);

    uint64_t size();
    uint64_t addr();
private:
    bool onGetData(Chunk&);
    void onSeek(sf::Time);
};

#endif /* AUDIO_H */

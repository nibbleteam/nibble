#ifndef AUDIO_H
#define AUDIO_H

#include <kernel/Memory.hpp>
#include <kernel/SquareWave.hpp>
#include <SFML/Audio.hpp>

class Audio : public Memory, public sf::SoundStream {
    const static unsigned int sampleCount;
    const uint64_t address;
    int16_t *samples;

    SquareWave wSquare;
    SquareWave wSquare2;
public:
    Audio(const uint64_t);
    ~Audio();
    
    uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
    uint64_t read(const uint64_t, uint8_t*, const uint64_t);

    uint64_t size();
    uint64_t addr();
private:
    bool onGetData(Chunk&);
    void onSeek(sf::Time);
};

#endif /* AUDIO_H */

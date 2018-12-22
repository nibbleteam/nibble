#ifndef CHANNEL_H
#define CHANNEL_H

#include <kernel/FMSynthesizer.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Wave.hpp>
#include <map>
using namespace std;

class Channel {
    // Sintetizadores (para permitir polifonia)
    map<uint8_t, unique_ptr<FMSynthesizer>> synthesizers;

    // Para efeitos de pós processamento
    int16_t *samples;
    int16_t *buffer;

    // Reverb
    int reverbPosition;
public:
    enum Cmd {
        NoteOn = 1,
        NoteOff = 2
    };

#pragma pack(push, 1)
    typedef struct CmdLayout {
        uint8_t cmd;
        uint8_t note;
        uint8_t intensity;
    }CmdLayout;
#pragma pack(pop)

#pragma pack(push, 1)
    typedef struct DelayLayout {
        int16_t delay;
        int16_t feedback;
    }DelayLayout;
#pragma pack(pop)

#pragma pack(push, 1)
    typedef struct MemoryLayout {
        FMSynthesizer::MemoryLayout synthesizer;
        CmdLayout commands[AUDIO_CMD_AMOUNT];
        DelayLayout delay;
    }MemoryLayout;
#pragma pack(pop)

    MemoryLayout &memory;
public:
	Channel(Memory&);
	~Channel();

	void fill(int16_t*, const unsigned int); 

    void press(uint8_t, uint8_t);
    void release(uint8_t);
private:
    void reverb(int16_t*, int16_t*, const unsigned int);
};

#endif /* CHANNEL_H */

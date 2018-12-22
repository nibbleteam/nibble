#ifndef NIBBLE_ENVELOPE
#define NIBBLE_ENVELOPE

#include <cstdint>

using namespace std;

class Envelope {
    enum Status {
        ATTACK,
        DECAY,
        SUSTAIN,
        RELEASE
    };

    Status status;
public:
#pragma pack(push, 1)
    struct MemoryLayout {
        int16_t sustained;
        int16_t level;
        int16_t sustain;
        int16_t attack;
        int16_t decay;
        int16_t release;
    };
#pragma pack(pop)

    MemoryLayout &memory;

    uint8_t intensity;
public:
    float amplitude;
    bool done;

    Envelope(MemoryLayout&);

    void on(uint8_t);
    void off();

    float getAmplitude();
};

#endif /* NIBBLE_ENVELOPE */

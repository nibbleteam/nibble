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

    uint8_t *sustained;
    Status status;
    uint8_t *level, *sustain;
    uint8_t *attack, *decay, *release;
public:
    float amplitude;
    bool done;

    Envelope(uint8_t*, uint8_t*, uint8_t*, uint8_t*, uint8_t*, uint8_t*);

    void on();
    void off();

    float getAmplitude();
private:
    float tof(uint8_t*);
};

#endif /* NIBBLE_ENVELOPE */

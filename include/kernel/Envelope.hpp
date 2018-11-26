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

    int16_t *sustained;
    Status status;
    int16_t *level, *sustain;
    int16_t *attack, *decay, *release;
public:
    float amplitude;
    bool done;

    Envelope(int16_t*, int16_t*, int16_t*, int16_t*, int16_t*, int16_t*);

    void on();
    void off();

    float getAmplitude();
};

#endif /* NIBBLE_ENVELOPE */

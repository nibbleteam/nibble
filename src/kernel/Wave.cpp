#include <kernel/Wave.hpp>
#include <cmath>

double Wave::fromFrequency(double f) {
    return 44100.0/f;
}

double Wave::fromNote(uint8_t o, uint8_t n) {
    uint16_t p = uint16_t(o)*12+uint16_t(n);
    // Distância para A4
    int16_t d = p - 48;

    return 440.0*pow(1.059463094359, double(d));
}

#include <kernel/Wave.hpp>
#include <cmath>
#include <climits>
#include <iostream>
using namespace std;

// Encontra o período para uma frequência dada
double Wave::fromFrequency(double f) {
    return 44100.0/f;
}

// Encontra a frequência para uma nota dada
// Argumentos: oitava, nota
double Wave::fromNote(uint8_t o, uint8_t n) {
    uint16_t p = uint16_t(o)*12+uint16_t(n);
    // Distância para A4
    int16_t d = p - 48;

    return 440.0*pow(1.059463094359, double(d));
}

Wave::Wave():
    phase(0), amplitude(0), period(fromFrequency(fromNote(3, 0))), duty(0.5) {
	previousAmplitude = 0;
	targetAmplitude = 1;
}

void Wave::changeParameters() {
}

int16_t* Wave::fill(const unsigned int sampleCount) {
	//previousAmplitude = amplitude;
	//targetAmplitude = double(rand()%100)/100.0;

    for (unsigned int i=0;i<sampleCount;i++) {
		// Gera ponto da onda
        if (period != 0) {
            auto index = fmod(phase, 1);
            samples[i] = valueAt(index)*amplitude;
        }

		// Avança tempo
		phase += 1.0/period;

		// Ajusta amplitude
		double deltaAmplitude = (targetAmplitude-previousAmplitude)/period;
		double amplitudeDistance = abs(targetAmplitude-amplitude);

		if (amplitudeDistance > abs(deltaAmplitude) &&
			amplitudeDistance > amplitudeError) {
			amplitude += deltaAmplitude;
		} else {
			amplitude = targetAmplitude;
		}
    }

    return samples;
}

double Wave::valueAt(double i) {
    auto a = lut[(int)ceil(i*WAVE_LUT_SIZE)%WAVE_LUT_SIZE];
    auto b = lut[(int)floor(i*WAVE_LUT_SIZE)];

    auto p = i*WAVE_LUT_SIZE-floor(i*WAVE_LUT_SIZE);

    return (a*p+b*(1.0-p));
}

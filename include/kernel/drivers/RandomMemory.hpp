#ifndef RANDOM_MEMORY_H
#define RANDOM_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>

using namespace std;

class RandomMemory : public Memory {
	uint8_t *data;
	const uint64_t address;
	static const uint64_t length;
public:
	RandomMemory(const uint64_t);
	~RandomMemory();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();
private:
    // Randomiza os dados n primeiro bytes
    // da memória (leituras são sempre feitas em 0x00 na prática)
    void randomize(const uint64_t);
};

#endif /* RANDOM_MEMORY_H */

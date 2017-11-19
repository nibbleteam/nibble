#ifndef RAM_MEMORY_H
#define RAM_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>

using namespace std;

class RAM : public Memory {
	uint8_t *data;
	const uint64_t address;
	const uint64_t length;
public:
	RAM(const uint64_t, const uint64_t);
	~RAM();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();
};

#endif /* RAM_MEMORY_H */

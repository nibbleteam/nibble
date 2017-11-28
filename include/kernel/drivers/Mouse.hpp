#ifndef MOUSE_H
#define MOUSE_H

#include <cstdint>
#include <kernel/Memory.hpp>

using namespace std;

class Mouse : public Memory {
	const uint64_t address;
public:
	Mouse(const uint64_t);
	~Mouse();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();
};

#endif /* MOUSE_H */

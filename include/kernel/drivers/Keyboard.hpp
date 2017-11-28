#ifndef KEYBOARD_H
#define KEYBOARD_H

#include <cstdint>
#include <kernel/Memory.hpp>

using namespace std;

class Keyboard : public Memory {
	const uint64_t address;
public:
	Keyboard(const uint64_t);
	~Keyboard();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();
};

#endif /* KEYBOARD_H */

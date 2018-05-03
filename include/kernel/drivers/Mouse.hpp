#ifndef MOUSE_H
#define MOUSE_H

#include <cstdint>
#include <kernel/Memory.hpp>

using namespace std;

#define MOUSE_MEM_SIZE 6

class Mouse : public Memory {
    uint8_t mem[MOUSE_MEM_SIZE];
	const uint64_t address;
public:
	Mouse(const uint64_t);
	~Mouse();

    string name();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();

    void moved(uint16_t, uint16_t);
    void pressed(uint8_t);
    void released(uint8_t);

    void update();
};

#endif /* MOUSE_H */

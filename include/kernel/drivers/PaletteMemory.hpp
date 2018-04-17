#ifndef PALETTE_MEMORY_H
#define PALETTE_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>

class VideoMemory;

class PaletteMemory : public Memory {
	uint8_t *data;
	const uint64_t address;
	const uint64_t length;
    VideoMemory *videoMemory;
public:
	PaletteMemory(VideoMemory*, const uint64_t);
	~PaletteMemory();

	string name();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();
};

#endif /* PALETTE_MEMORY_H */

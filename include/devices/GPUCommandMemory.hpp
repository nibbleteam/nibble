#ifndef GPUCOMMAND_MEMORY_H
#define GPUCOMMAND_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>

class VideoMemory;

class GPUCommandMemory : public Memory {
	uint8_t *data;
	const uint64_t address;
    VideoMemory *videoMemory;
public:
	const static uint64_t length;
public:
	GPUCommandMemory(VideoMemory*, const uint64_t);
	~GPUCommandMemory();

	string name();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();
};

#endif /* GPUCOMMAND_MEMORY_H */

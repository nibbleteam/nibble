#ifndef CARTRIDGE_MEMORY_H
#define CARTRIDGE_MEMORY_H

#include <cstdint>
#include <string>
#include <filesystem>
#include <kernel/Memory.hpp>

using namespace std;

class CartridgeMemory: public Memory {
	const uint64_t address;
public:
    CartridgeMemory(const experimental::filesystem::path&, const uint64_t);
    ~CartridgeMemory();

    uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
    uint64_t read(const uint64_t, uint8_t*, const uint64_t);
 
    uint64_t size();
    uint64_t addr();
};

#endif /* CARTRIDGE_MEMORY_H */

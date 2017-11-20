#ifndef CARTRIDGE_MEMORY_H
#define CARTRIDGE_MEMORY_H

#include <cstdint>
#include <string>
#include <kernel/Memory.hpp>
#include <cppfs/FilePath.h>

using namespace std;
using namespace cppfs;

class CartridgeMemory: public Memory {
	const uint64_t address;
public:
    CartridgeMemory(const FilePath&, const uint64_t);
    ~CartridgeMemory();

    uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
    uint64_t read(const uint64_t, uint8_t*, const uint64_t);
 
    uint64_t size();
    uint64_t addr();
};

#endif /* CARTRIDGE_MEMORY_H */

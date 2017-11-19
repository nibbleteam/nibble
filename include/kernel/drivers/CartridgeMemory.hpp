#ifndef CARTRIDGE_MEMORY_H
#define CARTRIDGE_MEMORY_H

#include <cstdint>
#include <string>

using namespace std;

class CartridgeMemory {
public:
    CartridgeMemory(string&, uint64_t);
    ~CartridgeMemory();

    uint64_t write(uint64_t, uint8_t*, uint64_t);
    uint64_t read(uint64_t, uint8_t*, uint64_t);
    uint64_t copy(uint64_t, uint64_t, uint64_t);

    uint64_t size();
    uint64_t addr();
};

#endif /* CARTRIDGE_MEMORY_H */

#ifndef MEMORY_H
#define MEMORY_H

#include <cstdint>

class Memory {
public:
    virtual uint64_t write(uint64_t, uint8_t*, uint64_t) = 0;
    virtual uint64_t read(uint64_t, uint8_t*, uint64_t) = 0;
    virtual uint64_t copy(uint64_t, uint64_t, uint64_t) = 0;

    // Tamanho do espaço que é endereçado e 
    // endereço de início, em bytes
    virtual uint64_t size();
    virtual uint64_t addr();
};

#endif /* MEMORY_H */

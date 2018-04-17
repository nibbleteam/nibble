#ifndef MEMORY_H
#define MEMORY_H

#include <cstdint>
#include <string>

using namespace std;

class Memory {
public:
    virtual ~Memory() {};

	virtual string name() = 0;

    virtual uint64_t write(const uint64_t, const uint8_t*, const uint64_t) = 0;
    virtual uint64_t read(const uint64_t, uint8_t*, const uint64_t) = 0;

    // Tamanho do espaço que é endereçado e 
    // endereço de início, em bytes
    virtual uint64_t size() = 0;
    virtual uint64_t addr() = 0;
};

#endif /* MEMORY_H */

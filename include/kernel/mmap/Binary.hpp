#ifndef MMAP_BINARY_H
#define MMAP_BINARY_H

namespace mmap {
#pragma pack(push, 1)
    struct BinaryMetadata {
        size_t length;
    };
#pragma pack(pop)

    size_t read_binary(Memory&, Path&);
    void write_binary(Memory&, size_t, Path&);
}

#endif /* MMAP_BINARY_H */

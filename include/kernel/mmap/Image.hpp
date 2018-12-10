#ifndef MMAP_IMAGE_H
#define MMAP_IMAGE_H

namespace mmap {
#pragma pack(push, 1)
    struct ImageMetadata {
        int16_t w, h;
    };
#pragma pack(pop)

    size_t read_image(Memory&, Path&);
    void write_image(Memory&, size_t, Path&);
}

#endif /* MMAP_IMAGE_H */

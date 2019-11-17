#ifndef MMAP_IMAGE_H
#define MMAP_IMAGE_H

#include <tuple>

namespace mmap {
    tuple<size_t, int16_t, int16_t> read_image(Memory&, Path&);
    void write_image(Memory&, size_t, int16_t, int16_t, Path&);

    void cleanup_palettes();
}

#endif /* MMAP_IMAGE_H */

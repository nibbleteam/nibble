/*
 * Carrega e salva arquivos binários 
 */

#include <cstdint>

#include <kernel/Memory.hpp>
#include <kernel/filesystem.hpp>

#include <kernel/mmap/Binary.hpp>

namespace mmap {

size_t read_binary(Memory &memory, Path &path) {
    if (fs::file_exists(path) && !fs::is_dir(path)) {
        cout << "mapping binary to memory" << path.get_path() << endl;

        auto length = fs::get_file_size(path);

        auto area = memory.allocate_with_position(sizeof(BinaryMetadata)+length, "Memory Mapped Binary");
        auto *meta = (BinaryMetadata*)get<0>(area);

        meta->length = length;

        char* file_data = fs::get_file_data(path);

        if (file_data) {
            memcpy(get<0>(area)+sizeof(BinaryMetadata), file_data, length);

            delete[] file_data;

            return get<1>(area);
        } else {
            return -1;
        }
    }

    return -1;
}

void write_binary(Memory &memory, size_t pos, Path &path) {
    auto ptr = memory.to_ptr(pos);
    auto size = memory.get_size(ptr)-sizeof(BinaryMetadata);
    auto data_ptr = ptr+sizeof(BinaryMetadata);

    fs::set_file_data(path, (const char*)data_ptr, size);
}

}

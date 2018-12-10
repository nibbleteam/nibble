/*
 * Carrega e salva arquivos binários 
 */

#include <cstdint>

#include <kernel/Memory.hpp>
#include <kernel/filesystem.hpp>

#include <kernel/mmap/Binary.hpp>

namespace mmap {

size_t read_binary(Memory &memory, Path &path) {
    if (fs::fileExists(path) && !fs::isDir(path)) {
        cout << "mapping binary to memory" << path.getPath() << endl;

        auto length = fs::getFileSize(path);

        auto area = memory.allocateWithPosition(sizeof(BinaryMetadata)+length, "Memory Mapped Binary");
        auto *meta = (BinaryMetadata*)get<0>(area);

        meta->length = length;

        char* fileData = fs::getFileData(path);

        if (fileData) {
            memcpy(get<0>(area)+sizeof(BinaryMetadata), fileData, length);

            delete[] fileData;

            return get<1>(area);
        } else {
            return -1;
        }
    }

    return -1;
}

void write_binary(Memory &memory, size_t pos, Path &path) {
    auto ptr = memory.toPtr(pos);
    auto size = memory.getSize(ptr)-sizeof(BinaryMetadata);
    auto dataPtr = ptr+sizeof(BinaryMetadata);

    fs::setFileData(path, (const char*)dataPtr, size);
}

}

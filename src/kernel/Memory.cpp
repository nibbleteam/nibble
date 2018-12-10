#include <iostream>

#include <kernel/Memory.hpp>

#include <Specs.hpp>

using namespace std;

Memory::Area::Area(size_t pos, size_t size, function<void(AccessMode)> fn): pos(pos), size(size), trigger(fn) { }

bool Memory::Area::operator < (Area &other) {
    return size < other.size;
}

Memory::Memory() {
    raw = new uint8_t[NIBBLE_MEM_SIZE];
    cout << "[nibble] " << "compiled with "<< NIBBLE_MEM_SIZE/1024 << "kB of memory." << endl;

    // Iniciamos apenas com uma área livre e nenhuma usada
    freeAreas.insert(make_pair(raw, Area { 0, NIBBLE_MEM_SIZE, nullptr }));
}

Memory::~Memory() {
    delete raw;
}

tuple<uint8_t*, size_t> Memory::allocateWithPosition(const size_t bytes, const string use, function<void(AccessMode)> fn) {
    for (auto &area: freeAreas) {
        if (area.second.size >= bytes) {
            // Cria as informações da nova área
            size_t pos = area.second.pos;
            uint8_t* ptr = raw+pos;

            // Reduz o tamanho da área livre
            area.second.size -= bytes;
            area.second.pos += bytes;

            // Move a área livre
            freeAreas.insert(make_pair(area.first+bytes, area.second));
            freeAreas.erase(area.first);

            usedAreas.insert(make_pair(ptr, Area { pos, bytes, fn }));

            cout << "[nibble] mmap: " << use << " " << pos << "-" << pos+bytes << endl;
            cout << "[nibble] free: " << free() << endl;

            return tuple<uint8_t*, size_t> (ptr, pos);
        }
    }

    cout << "[nibble] out of memory!" << endl;
    exit(-1);
}

uint8_t* Memory::allocate(const size_t bytes, const string use, function<void(AccessMode)> fn) {
    return get<0>(allocateWithPosition(bytes, use, fn));
}

void Memory::deallocate(uint8_t *ptr) {
    try {
        auto area = usedAreas.at((uint8_t*)ptr);

        cout << "[nibble] deallocate: " << area.pos << endl;

        freeAreas.insert(make_pair(ptr, area));
        usedAreas.erase(ptr);
    } catch (out_of_range &o) {
        // Invalid deallocation
    }
}

void Memory::deallocate(const size_t pos) {
    try {
        auto area = usedAreas.at(raw+pos);

        cout << "[nibble] deallocate: " << area.pos << endl;

        freeAreas.insert(make_pair(raw+pos, area));
        usedAreas.erase(raw+pos);
    } catch (out_of_range &o) {
        // Invalid deallocation
    }
}

size_t Memory::resize(const size_t pos, const size_t size) {
    try {
        auto oldArea = usedAreas.at(raw+pos);
        auto newArea = allocateWithPosition(size, "Area Resize");

        memcpy(get<0>(newArea), raw+pos, min(oldArea.size, size));

        deallocate(pos);

        return get<1>(newArea);
    } catch (out_of_range &o) {
        cout << "[nibble] invalid resize!" << endl;
        return -1;
    }
}

uint8_t* Memory::toPtr(const size_t pos) {
    return raw+pos;
}

size_t Memory::getSize(uint8_t *ptr) {
    try {
        return usedAreas.at(ptr).size;
    } catch (out_of_range &o) {
        return -1;
    }
}

size_t Memory::free() {
    size_t bytes = 0;

    for (auto &area: freeAreas) {
        bytes += area.second.size;
    }

    return bytes;
}

size_t Memory::used() {
    size_t bytes = 0;

    for (auto &area: usedAreas) {
        bytes += area.second.size;
    }

    return bytes;
}

void Memory::triggers(size_t start, size_t end, AccessMode mode) {
    for (auto &area: usedAreas) {
        if ((start >= area.second.pos && start <= area.second.pos+area.second.size) ||
            (end>= area.second.pos && end <= area.second.pos+area.second.size)) {
            if (area.second.trigger) {
                area.second.trigger(mode);
            }
        }
    }
}

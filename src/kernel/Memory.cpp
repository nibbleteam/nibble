#include <iostream>
#include <iomanip>
#include <algorithm>
#include <sstream>
#include <vector>

#include <kernel/Memory.hpp>

#include <Specs.hpp>

using namespace std;

Memory::Area::Area(size_t pos, size_t size, function<void(AccessMode)> fn): pos(pos), size(size), trigger(fn){ }

bool Memory::Area::operator < (Area &other) {
    return size < other.size;
}

Memory::Memory(): log_memory_allocation(false) {
    raw = new uint8_t[NIBBLE_MEM_SIZE];
    cout << "Compiled with "<< NIBBLE_MEM_SIZE/1024 << "kB of memory." << endl;

    // Iniciamos apenas com uma área livre e nenhuma usada
    free_areas.insert(make_pair(raw, Area { 0, NIBBLE_MEM_SIZE, nullptr }));
}

Memory::~Memory() {
    delete raw;
}

tuple<uint8_t*, size_t> Memory::allocate_with_position(const size_t bytes, const string use, function<void(AccessMode)> fn) {
    for (auto &area: free_areas) {
        if (area.second.size >= bytes) {
            // Cria as informações da nova área
            size_t pos = area.second.pos;
            uint8_t* ptr = raw+pos;

            // Reduz o tamanho da área livre
            area.second.size -= bytes;
            area.second.pos += bytes;

            // Move a área livre
            free_areas.insert(make_pair(area.first+bytes, area.second));
            free_areas.erase(area.first);

            used_areas.insert(make_pair(ptr, Area { pos, bytes, fn }));

            if (log_memory_allocation) {
                stringstream position;
                position << pos << "-" << pos+bytes;

                cout << setiosflags(cout.left)  << setw(24) << use << resetiosflags(cout.left);
                cout << setiosflags(cout.right) << " [" << setw(15) << position.str() << "]";
                cout << resetiosflags(cout.right) << endl;
            }

            return tuple<uint8_t*, size_t> (ptr, pos);
        }
    }

    cout << "EXITING: OUT OF MEMORY!" << endl;
    exit(-1);
}

uint8_t* Memory::allocate(const size_t bytes, const string use, function<void(AccessMode)> fn) {
    return get<0>(allocate_with_position(bytes, use, fn));
}

void Memory::deallocate_after(size_t minimum_used) {
    uint8_t *ptr = raw+minimum_used;

    vector <uint8_t*>tmp;

    for (auto area: used_areas) {
        if (area.first >= ptr) {
            tmp.push_back(area.first);
        }
    }

    for (auto area_ptr: tmp) {
        deallocate(area_ptr);
    }
}

void Memory::deallocate(uint8_t *ptr) {
    try {
        auto area = used_areas.at((uint8_t*)ptr);

        cout << "deallocate: " << area.pos << endl;

        free_areas.insert(make_pair(ptr, area));
        used_areas.erase(ptr);
    } catch (out_of_range &o) {
        // Invalid deallocation
    }
}

void Memory::deallocate(const size_t pos) {
    try {
        auto area = used_areas.at(raw+pos);

        cout << "deallocate: " << area.pos << endl;

        free_areas.insert(make_pair(raw+pos, area));
        used_areas.erase(raw+pos);
    } catch (out_of_range &o) {
        // Invalid deallocation
    }
}

size_t Memory::resize(const size_t pos, const size_t size) {
    try {
        auto old_area = used_areas.at(raw+pos);
        auto new_area = allocate_with_position(size, "Area Resize");

        memcpy(get<0>(new_area), raw+pos, min(old_area.size, size));

        deallocate(pos);

        return get<1>(new_area);
    } catch (out_of_range &o) {
        cout << "invalid resize!" << endl;
        return -1;
    }
}

uint8_t* Memory::to_ptr(const size_t pos) {
    return raw+pos;
}

size_t Memory::get_size(uint8_t *ptr) {
    try {
        return used_areas.at(ptr).size;
    } catch (out_of_range &o) {
        return -1;
    }
}

size_t Memory::free() {
    size_t bytes = 0;

    for (auto &area: free_areas) {
        bytes += area.second.size;
    }

    return bytes;
}

size_t Memory::used() {
    size_t bytes = 0;

    for (auto &area: used_areas) {
        bytes += area.second.size;
    }

    return bytes;
}

void Memory::triggers(size_t start, size_t end, AccessMode mode) {
    for (auto &area: used_areas) {
        if ((start >= area.second.pos && start <= area.second.pos+area.second.size) ||
            (end>= area.second.pos && end <= area.second.pos+area.second.size) ||
            (start <= area.second.pos && end >= area.second.pos+area.second.size)) {
            if (area.second.trigger) {
                area.second.trigger(mode);
            }
        }
    }
}

void Memory::set_log(bool log) {
    log_memory_allocation = log;
}

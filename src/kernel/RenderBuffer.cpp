#include <kernel/RenderBuffer.hpp>
#include <cassert>
#include <iostream>

const uint64_t RenderBuffer::arrayLength = 1000;

RenderBuffer::RenderBuffer(sf::PrimitiveType primitive, uint8_t size) :
    primitive(primitive), primitiveSize(size) {
    pos = 0;
}

void RenderBuffer::draw(sf::RenderTarget& target) {
    trim();

    for (auto &array : arrays) {
        target.draw(array, sf::BlendNone);
    }
}

void RenderBuffer::add(vector<sf::Vertex> vertices) {
    assert(vertices.size() == primitiveSize);

    uint32_t array = pos / (arrayLength/primitiveSize);
    uint32_t position = (pos % (arrayLength/primitiveSize))*primitiveSize;

    if (arrays.size() <= array) {
        arrays.push_back(
            sf::VertexArray(primitive, arrayLength)
        );
    }

    for (uint64_t i=0;i<vertices.size();i++) {
        arrays[array][position+i].position = vertices[i].position;
        arrays[array][position+i].color = vertices[i].color;
    }

    pos++;
}

void RenderBuffer::clear() {
    pos = 0;
}

void RenderBuffer::trim() {
    if (arrays.size() > 0) {
        // Corta parte que não foi redesenhada fora do buffer
        uint32_t trimPos = pos/(arrayLength/primitiveSize);
        arrays[trimPos].resize(
            (pos % (arrayLength/primitiveSize))*primitiveSize
        );
        for (trimPos++;trimPos<arrays.size();trimPos++) {
            arrays[trimPos].resize(0);
        }
    }
}

#include <kernel/RenderBuffer.hpp>
#include <cassert>
#include <iostream>

const uint64_t RenderBuffer::arrayLength = 1000;

RenderBuffer::RenderBuffer(sf::PrimitiveType primitive, uint8_t size, sf::Shader *shader) :
    primitive(primitive), primitiveSize(size), shader(shader) {
    pos = 0;
}

RenderBuffer::~RenderBuffer() {
    for (auto &array : arrays) {
        delete[] array;
    }
}

void RenderBuffer::setShader(sf::Shader* shader) {
    this->shader = shader;
}

void RenderBuffer::draw(sf::RenderTarget& target) {
    uint64_t remaining = pos;

    for (auto &array : arrays) {
        uint64_t size = remaining>arrayLength ? arrayLength : remaining;
        if (shader == NULL) {
            target.draw(array, size*primitiveSize, primitive, sf::BlendNone);
        } else {
            target.draw(array, size*primitiveSize, primitive,
                        sf::RenderStates(sf::BlendNone,
                                         sf::Transform::Identity,
                                         NULL,
                                         shader));
        }
        remaining -= size;
    }
}

void RenderBuffer::add(vector<sf::Vertex> vertices) {
    assert(vertices.size() == primitiveSize);

    uint32_t array = pos / arrayLength;
    uint32_t position = (pos % arrayLength)*primitiveSize;

    if (arrays.size() <= array) {
        arrays.push_back(
            new sf::Vertex[arrayLength*primitiveSize]
            );
    }

    for (uint64_t i=0;i<vertices.size();i++) {
        arrays[array][position+i] = vertices[i];
    }

    pos++;
}

void RenderBuffer::clear() {
    pos = 0;
}

bool RenderBuffer::hasContent() {
    return pos != 0;
}

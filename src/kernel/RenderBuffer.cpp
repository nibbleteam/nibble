#include <kernel/RenderBuffer.hpp>
#include <cassert>
#include <iostream>

const uint64_t RenderBuffer::arrayLength = 1000;

RenderBuffer::RenderBuffer(sf::PrimitiveType primitive, uint8_t size, sf::Shader *shader) :
    primitive(primitive), primitiveSize(size), shader(shader) {
    pos = 0;
}

void RenderBuffer::setShader(sf::Shader* shader) {
    this->shader = shader;
}

void RenderBuffer::draw(sf::RenderTarget& target) {
    trim();

    for (auto &array : arrays) {
        if (shader == NULL) {
            target.draw(array, sf::BlendNone);
        } else {
            target.draw(array,
                        sf::RenderStates(sf::BlendNone,
                                         sf::Transform::Identity,
                                         NULL,
                                         shader));
        }
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
        arrays[array][position+i] = vertices[i];
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

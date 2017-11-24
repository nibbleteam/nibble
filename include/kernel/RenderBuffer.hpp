#ifndef RENDER_BUFFER_H
#define RENDER_BUFFER_H

#include <SFML/Graphics.hpp>
#include <vector>
#include <cstdint>

using namespace std;

class RenderBuffer {
    const static uint64_t arrayLength;
    const sf::PrimitiveType primitive;
    const uint8_t primitiveSize;
    vector<sf::VertexArray> arrays;
    uint64_t pos;
public:
    RenderBuffer(const sf::PrimitiveType, const uint8_t);
    
    void clear();
    void draw(sf::RenderTarget&);
    void add(vector<sf::Vertex>);
private:
    void trim();
};

#endif /* RENDER_BUFFER_H */

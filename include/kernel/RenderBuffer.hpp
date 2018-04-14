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
    vector<sf::Vertex*> arrays;
    sf::Shader *shader;
    uint64_t pos;
public:
    RenderBuffer(const sf::PrimitiveType, const uint8_t, sf::Shader* = NULL);
    ~RenderBuffer();
    
    void clear();
    void draw(sf::RenderTarget&);
    void add(vector<sf::Vertex>);

    void setShader(sf::Shader*);

    bool hasContent();
};

#endif /* RENDER_BUFFER_H */

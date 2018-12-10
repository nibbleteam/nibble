#define _USE_MATH_DEFINES
#include <cmath>
#include <SFML/OpenGL.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <iostream>
#include <cstring>

VideoMemory::VideoMemory(sf::RenderWindow &window, const uint64_t addr):
    window(window), address(addr), colormap(NULL),
    screenScale(2), screenOffsetX(0), screenOffsetY(0) {
    // Tamanho da textura é 1/4 do tamanho da tela
    // uma vez que um pixel no sfml são quatro bytes
    // e no console é apenas um
    framebuffer.create(SCREEN_W/BYTES_PER_TEXEL, SCREEN_H);

    // Sprite para desenhar o framebuffer na tela
    framebufferSpr = sf::Sprite(framebuffer);
    framebufferSpr.setScale(BYTES_PER_TEXEL, 1);
    
    // Cria a textura da palleta
    paletteTex.create(GPU::paletteLength*GPU::paletteAmount+
                      (2*GPU::paletteLength*GPU::paletteAmount)/BYTES_PER_TEXEL, 1);
    
    // Shader de final de pipeline
    if (!toRGBAShader.loadFromMemory(shaderVertex, toRGBAShaderFragment)) {
        cout << "video " << "error loading toRGBA shader" << endl;
        exit(1);
    }
    else {
        // Passa textura do framebuffer e paleta
        toRGBAShader.setUniform("source", framebuffer);
        toRGBAShader.setUniform("palette", paletteTex);
    }

    // Inicializa a memória
    for (size_t i=0;i<VIDEO_MEMORY_LENGTH;i++) {
      buffer[i] = int(0xFF*sin(i/14))%0x10;
      //buffer[i] = (i%320+rand()%4)%8 == 0 ? (rand()%0x10) : (0);
    }

    // Inicializa com bytes não inicializados
    framebuffer.update(buffer);

    paletteData = nullptr;

    // Aspect-ratio correto
    resize();
}

VideoMemory::~VideoMemory() {
    if (colormap != NULL) {
        stopCapturing();
    }
}

string VideoMemory::name() {
    return "VIDEO";
}

void VideoMemory::updatePalette(const uint8_t* palette) {
    paletteData = palette;
    paletteTex.update(palette, paletteTex.getSize().x, paletteTex.getSize().y, 0, 0);
}

void VideoMemory::updateSpriteSheet(const uint64_t p, const uint8_t* data, const uint64_t size) {
    memcpy(spritesheet+p, data, size);
}

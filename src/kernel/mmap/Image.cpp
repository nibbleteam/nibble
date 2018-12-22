/*
 * Carrega e salva imagens
 */

#include <cstdint>

#include <SDL2/SDL.h>
#include <IL/il.h>

#include <kernel/Memory.hpp>
#include <kernel/filesystem.hpp>

#include <kernel/mmap/Image.hpp>

namespace mmap {

// TODO: Usar um tamanho dinâmico
#define SPRITESHEET_W 4096
#define SPRITESHEET_H 1024

uint8_t color2index(const SDL_Color& color) {
    return (color.r/16+color.g/16+color.b/16)/3;
}

SDL_Color index2color(const uint8_t index) {
    uint8_t gray = index*16;

    return {gray, gray, gray, 255};
}

size_t read_image(Memory &memory, Path &path) {
    if (fs::fileExists(path) && !fs::isDir(path)) {
        cout << "mapping image to memory " << path.getPath() << endl;

        // Carrega a imagem
        if (!ilLoadImage(path.getPath().c_str())) {
            cout << "could not load image!" << endl;
            return -1;
        }

        size_t w = ilGetInteger(IL_IMAGE_WIDTH);
        size_t h = ilGetInteger(IL_IMAGE_HEIGHT);

        // Verifica o tamanho
        if (w > SPRITESHEET_W || h > SPRITESHEET_H) {
            cout << "spritesheet is too big" << endl;   
            return -1;
        }

        auto info = memory.allocateWithPosition(sizeof(ImageMetadata)+w*h, "Memory Mapped Image");
        ImageMetadata *meta = (ImageMetadata*)get<0>(info);

        meta->w = w;
        meta->h = h;

        auto imgData = ilGetData();

        // Converte a imagem e escreve array data
        for (size_t y=0;y<h;y++) {
            for (size_t x=0;x<w;x++) {
                uint8_t pix = imgData[y*w+x+0];

                get<0>(info)[sizeof(ImageMetadata)+y*w+x] = pix&0x0F;
            }
        }

        return get<1>(info);
    }

    return -1;
}

void write_image(Memory &memory, size_t pos, Path &path) {
    /*
    TODO

    sf::Image img;
    auto *ptr = memory.toPtr(pos);
    auto *meta = (ImageMetadata*)ptr;
    auto *imgPtr = ptr+sizeof(ImageMetadata);

    img.create(meta->w, meta->h);

    for (int16_t y=0;y<meta->h;y++) {
        for (int16_t x=0;x<meta->w;x++) {
            img.setPixel(x, y, index2color(imgPtr[y*meta->w+x]));
        }
    }

    img.saveToFile(path.getPath());
    */
}

}

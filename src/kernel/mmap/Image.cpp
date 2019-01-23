/*
 * Carrega e salva imagens
 */

#include <cstdint>

#include <SDL.h>
#include <png.h>

#include <kernel/Memory.hpp>
#include <kernel/filesystem.hpp>

#include <kernel/mmap/Image.hpp>

namespace mmap {

// TODO: Usar um tamanho dinâmico
#define SPRITESHEET_W 4096
#define SPRITESHEET_H 1024

uint8_t color2index(const SDL_Color color) {
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
        png_image img;
        png_bytep imgData;

        memset(&img, 0, sizeof(png_image));
        img.version = PNG_IMAGE_VERSION;

        if (!png_image_begin_read_from_file(&img, path.getPath().c_str())) {
            cout << "Could not load image (header): " << path.getPath() << endl;
            return -1;
        }

        img.format = PNG_FORMAT_RGBA;

        imgData = new uint8_t[PNG_IMAGE_SIZE(img)];

        if (png_image_finish_read(&img, NULL, imgData, 0, NULL) == 0) {
            cout << "Could not load image: " << path.getPath() << endl;
            return -1;
        }

        // Verifica o tamanho
        if (img.width > SPRITESHEET_W || img.height > SPRITESHEET_H) {
            cout << "spritesheet is too big" << endl;   
            delete imgData;
            return -1;
        }

        auto info = memory.allocateWithPosition(sizeof(ImageMetadata)+img.width*img.height, "Memory Mapped Image");
        ImageMetadata *meta = (ImageMetadata*)get<0>(info);

        meta->w = img.width;
        meta->h = img.height;

        // Converte a imagem e escreve array data
        for (size_t y=0;y<img.height;y++) {
            for (size_t x=0;x<img.width;x++) {
                auto p = (y*img.width+x)*4;
                uint8_t pix = color2index(SDL_Color {
                                            imgData[p+0],
                                            imgData[p+1],
                                            imgData[p+2],
                                            imgData[p+3]
                                          });

                get<0>(info)[sizeof(ImageMetadata)+y*img.width+x] = pix&0x0F;
            }
        }

        delete imgData;
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

/*
 * Carrega e salva imagens
 */

#include <cstdint>

#include <SDL.h>
#include <png.h>

#include <devices/GPU.hpp>
#include <kernel/Memory.hpp>
#include <kernel/filesystem.hpp>

#include <kernel/mmap/Image.hpp>

namespace mmap {
    uint8_t color2index(const SDL_Color color) {
        return (color.r/16+color.g/16+color.b/16)/3;
    }

    SDL_Color index2color(const uint8_t index) {
        uint8_t gray = index*16;

        return {gray, gray, gray, 255};
    }

    tuple<size_t, int16_t, int16_t> read_image(Memory &memory, Path &path) {
        if (fs::file_exists(path) && !fs::is_dir(path)) {
            // Carrega a imagem
            png_image img;
            png_bytep img_data;

            memset(&img, 0, sizeof(png_image));
            img.version = PNG_IMAGE_VERSION;

            if (!png_image_begin_read_from_file(&img, path.get_path().c_str())) {
                cout << "Could not load image (header): " << path.get_path() << endl;
                return {0, 0, 0};
            }

            // A imagem tem uma paleta
            if (img.format & PNG_FORMAT_FLAG_COLORMAP) {
                img.format = PNG_FORMAT_RGBA_COLORMAP;

                png_bytep palette = new uint8_t[PNG_IMAGE_COLORMAP_SIZE(img)];
                img_data = new uint8_t[PNG_IMAGE_SIZE(img)];

                if (png_image_finish_read(&img, NULL, img_data, 0, palette) == 0) {
                    cout << "Could not load image: " << path.get_path() << endl;
                    return {0, 0, 0};
                }

                // Verifica o tamanho
                if (img.width > SPRITESHEET_W || img.height > SPRITESHEET_H) {
                    cout << "spritesheet is too big" << endl;
                    delete img_data;
                    delete palette;
                    png_image_free(&img);
                    return {0, 0, 0};
                }

                auto img_mem = memory.allocate_with_position(img.width*img.height, "Memory Mapped Image");
                auto img_mem_data = get<0>(img_mem);
                auto img_mem_pos = get<1>(img_mem);

                // Converte a imagem e escreve array data
                for (size_t y=0;y<img.height;y++) {
                    for (size_t x=0;x<img.width;x++) {
                        auto p = (y*img.width+x);
                        img_mem_data[p] = img_data[p]%16;
                    }
                }

                delete img_data;
                delete palette;
                png_image_free(&img);

                return {img_mem_pos, img.width, img.height};
            } else {
                img.format = PNG_FORMAT_RGBA;

                img_data = new uint8_t[PNG_IMAGE_SIZE(img)];

                if (png_image_finish_read(&img, NULL, img_data, 0, NULL) == 0) {
                    cout << "Could not load image: " << path.get_path() << endl;
                    return {0, 0, 0};
                }

                // Verifica o tamanho
                if (img.width > SPRITESHEET_W || img.height > SPRITESHEET_H) {
                    cout << "spritesheet is too big" << endl;
                    delete img_data;
                    png_image_free(&img);
                    return {0, 0, 0};
                }

                auto img_mem = memory.allocate_with_position(img.width*img.height, "Memory Mapped Image");
                auto img_mem_data = get<0>(img_mem);
                auto img_mem_pos = get<1>(img_mem);

                // Converte a imagem e escreve array data
                for (size_t y=0;y<img.height;y++) {
                    for (size_t x=0;x<img.width;x++) {
                        auto p = (y*img.width+x)*4;
                        uint8_t pix = color2index(SDL_Color {
                                                    img_data[p+0],
                                                    img_data[p+1],
                                                    img_data[p+2],
                                                    img_data[p+3]
                                                });

                        img_mem_data[y*img.width+x] = pix&0x0F;
                    }
                }

                delete img_data;
                png_image_free(&img);

                return {img_mem_pos, img.width, img.height};
            }
        }

        return {0, 0, 0};
    }

    /*
    TODO
    void write_image(Memory &memory, size_t pos, Path &path) {

        sf::Image img;
        auto *ptr = memory.to_ptr(pos);
        auto *meta = (ImageMetadata*)ptr;
        auto *img_ptr = ptr+sizeof(ImageMetadata);

        img.create(meta->w, meta->h);

        for (int16_t y=0;y<meta->h;y++) {
            for (int16_t x=0;x<meta->w;x++) {
                img.set_pixel(x, y, index2color(img_ptr[y*meta->w+x]));
            }
        }

        img.save_to_file(path.get_path());
    }
    */
}

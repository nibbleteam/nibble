#ifndef CARTRIDGE_MEMORY_H
#define CARTRIDGE_MEMORY_H

#include <cstdint>
#include <string>
#include <kernel/Memory.hpp>
#include <kernel/filesystem.hpp>
#include <kernel/drivers/VideoMemory.hpp>

using namespace std;

class CartridgeMemory: public Memory {
	const uint64_t address;
    static const uint16_t width;
    static const uint16_t height;
    static const uint64_t length;
    // De onde carregar a spritesheet
    static const string spriteSheetLocation;
    // Dados da memória
    uint8_t *data;
    // Acesso a memória de vídeo
    VideoMemory* video;
public:
    CartridgeMemory(Path&, const uint64_t, VideoMemory*);
    ~CartridgeMemory();

    uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
    uint64_t read(const uint64_t, uint8_t*, const uint64_t);
 
    uint64_t size();
    uint64_t addr();

    // Quando for carregada em memória, esse método atualiza
    // a video memory
    void load();
private:
    // Atualiza a VideoMemory
    void updateSpriteSheet(const uint64_t, const uint64_t);
    // Carrega a spritesheet de um arquivo
    bool loadFromFile(Path&);
    uint8_t color2Index(const sf::Color&);
};

#endif /* CARTRIDGE_MEMORY_H */

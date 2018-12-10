#include <kernel/drivers/CartridgeMemory.hpp>

const string CartridgeMemory::spriteSheetLocation = "/sheet.png";
const uint16_t CartridgeMemory::width = SPRITESHEET_W;
const uint16_t CartridgeMemory::height = SPRITESHEET_H;
const uint64_t CartridgeMemory::length = CartridgeMemory::width*CartridgeMemory::height;

CartridgeMemory::CartridgeMemory(Path& assets, const uint64_t addr, VideoMemory* video) :
	address(addr),
    video(video) {
    Path spriteSheet = assets.resolve(spriteSheetLocation);

    data = new uint8_t[size_t(length)];

    if (fs::fileExists(spriteSheet) && !fs::isDir(spriteSheet)) {
        cout << "loading spritesheet from " << spriteSheet.getPath() << endl;

        // Tenta carregar a spritesheet, se não conseguir sai
        if (!loadFromFile(spriteSheet)) {
            exit(1);
        }
    } else {
        cout << "cartridge has no spritesheet in " << spriteSheet.getPath() << endl;
    }
}

CartridgeMemory::~CartridgeMemory() {
    delete[] data;
}

string CartridgeMemory::name() {
	return "CART";
}

void CartridgeMemory::updateSpriteSheet(uint64_t p, uint64_t size) {
    video->updateSpriteSheet(p, data+p, size);
}

bool CartridgeMemory::loadFromFile(Path& path) {
    // Imagem para carregar os dados do arquivo
    sf::Image sheet;
    if (!sheet.loadFromFile(path.getPath())) {
        cout << "could not load spritesheet" << endl;
        return false;
    }

    // Verifica o tamanho da imagem
    auto size = sheet.getSize();
    if (size.x > width || size.y > height) {
        cout << "spritesheet is too big" << endl;   
        return false;
    }

    // Converte a imagem e escreve array data
    for (size_t y=0;y<size.y;y++) {
        for (size_t x=0;x<size.x;x++) {
            uint8_t pix = color2Index(sheet.getPixel(x, y));

            data[y*width+x] = pix&0x0F;
        }
    }

    return true;
}

uint8_t CartridgeMemory::color2Index(const sf::Color& color) {
    return (color.r/16+color.g/16+color.b/16)/3;
}

void CartridgeMemory::load() {
    // Atualiza toda a spritesheet na VideoMemory
    updateSpriteSheet(0, length);
}

uint64_t CartridgeMemory::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
    memcpy(this->data+p, data, size);
    updateSpriteSheet(0, length);
	return size;
}

uint64_t CartridgeMemory::read(uint64_t p, uint8_t* data, uint64_t size) {
    memcpy(data, this->data+p, size);
	return size;
}

uint64_t CartridgeMemory::size() {
	return length;
}

uint64_t CartridgeMemory::addr() {
	return address;
}

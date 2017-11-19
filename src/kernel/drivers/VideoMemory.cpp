#include <kernel/drivers/VideoMemory.hpp>

VideoMemory::VideoMemory(sf::RenderWindow &window, const unsigned int w, const unsigned int h, const uint64_t addr):
	w(w), h(h), address(addr), length(w*h), window(window), dirty(false) {
	renderTex.create(w, h);
	tex = &renderTex.getTexture();
	gpuSpr = sf::Sprite(*tex);
	img = tex->copyToImage();
	rwTex = sf::Texture();
	rwTex.create(w, h);
	cpuSpr = sf::Sprite(rwTex);
}

VideoMemory::~VideoMemory() {

}

void VideoMemory::draw() {
	rwTex.update(img);
	renderTex.draw(cpuSpr);

	window.draw(gpuSpr);
}

uint64_t VideoMemory::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
	static sf::Color pallete[] = {
		sf::Color(0, 0, 0),
		sf::Color(255, 255, 255),
		sf::Color(255, 200, 255),
		sf::Color(30, 128, 43),
		sf::Color(24, 25, 32),
		sf::Color(8, 145, 223),
		sf::Color(211, 231, 45),
		sf::Color(53, 23, 23),
		sf::Color(64, 255, 255),
		sf::Color(223, 232, 245),
		sf::Color(255, 255, 255),
		sf::Color(252, 25, 225),
		sf::Color(124, 255, 255),
		sf::Color(223, 123, 255),
		sf::Color(12, 54, 128),
		sf::Color(12, 54, 3),
	};

	unsigned int x, y;

	x = (unsigned int)p % w;
	y = (unsigned int)p / w;
	
	for (int i=0;i<size;i++) {
		auto color = data[i + p]/16;

		img.setPixel(x, h-y-1, pallete[color]);
		x++;
		if (x >= w) {
			x = 0; y++;
		}
	}

	return 0;
}

uint64_t VideoMemory::read(const uint64_t, uint8_t*, const uint64_t) {
	if (dirty) {
		// Carrega da GPU para a RAM
		img = tex->copyToImage();
		dirty = false;
	}
	
	return 0;
}

uint64_t VideoMemory::size() {
	return length;
}

uint64_t VideoMemory::addr() {
	return address;
}
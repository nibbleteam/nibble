#ifndef VIDEO_MEMORY_H
#define VIDEO_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>
#include <SFML/Graphics.hpp>

using namespace std;

class VideoMemory : public Memory {
	const uint64_t length;
	const uint64_t address;
	const unsigned int w, h;
	// Textura contendo a imagem que é visível na tela,
	// funciona como memória de vídeo
	sf::RenderTexture renderTex;
	// Apenas para facilitar o desenho (sprite) e o acesso (tex)
	// a rendertexture
	const sf::Texture *tex;
	sf::Texture rwTex;
	sf::Sprite gpuSpr, cpuSpr;
	// Versão do framebuffer na RAM da CPU. O booleano dirty indica
	// quando a versão da GPU precisa ser carregada, mas ela só é carregada
	// para essa image quando alguma operação de read precisa ser feita.
	sf::Image img;
	bool dirty;

	sf::RenderWindow &window;
public:
	VideoMemory(sf::RenderWindow&, unsigned int, const unsigned int, const uint64_t);
	~VideoMemory();

	void draw();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();
};

#endif /* VIDEO_MEMORY_H */

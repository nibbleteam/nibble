#ifndef VIDEO_MEMORY_H
#define VIDEO_MEMORY_H

#include <cstdint>
#include <kernel/Memory.hpp>
#include <SFML/Graphics.hpp>
#include <gif_lib.h>

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
	sf::Sprite gpuSpr, cpuSpr;
	const sf::Texture *tex;
    // Textura que permite a leitura e escrita.
    // Memória de vídeo para operações não aceleradas em hardware
	sf::Texture rwTex;
	// Versão do framebuffer na RAM da CPU. O booleano dirty indica
	// quando a versão da GPU precisa ser carregada, mas ela só é carregada
	// para essa image quando alguma operação de read precisa ser feita.
	sf::Image img;
	bool dirty;
    uint8_t *buffer;
	// Referência para a janela para que possamos desenhar para ela
	sf::RenderWindow &window;
    // Código e o shader utilizado para desenhar em write()s
    const static string writeShaderVertex;
    const static string writeShaderFragment;
    sf::Shader writeShader;
    // Textura utilizada como paleta pelo shader
    sf::Texture paletteTex;
    // Arquivo para salvar gifs
    GifFileType *gif;
    // Paleta do gif
    ColorMapObject *colormap;
public:
    const static uint64_t nibblesPerPixel;
    const static uint64_t bytesPerPixel;
public:
	VideoMemory(sf::RenderWindow&,
                const unsigned int,
                const unsigned int,
                const uint64_t);
	~VideoMemory();

    // Fecha arquivos abertos
    void close();

	void draw();

	uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
	uint64_t read(const uint64_t, uint8_t*, const uint64_t);

	uint64_t size();
	uint64_t addr();

    // Chamado por paletteMemory quando o usuário troca a paleta
    void updatePalette(const uint8_t*);
private:
    uint64_t nextTransferAmount(uint64_t, uint64_t, uint64_t);
    uint64_t bytesToTransferPixels(uint64_t);
    uint64_t bytesToPixels(uint64_t);
    uint64_t transferWidth(uint64_t);
    uint64_t transferHeight(uint64_t);
    // GIFs
    bool startCapturing(const string&);
    bool captureFrame();
    bool stopCapturing();
    ColorMapObject* getColorMap();
};

#endif /* VIDEO_MEMORY_H */

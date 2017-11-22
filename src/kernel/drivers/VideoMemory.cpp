#include <SFML/OpenGL.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <iostream>

const string VideoMemory::writeShaderVertex = R"(
// Shader padrão do SFML sem alterações
void main()
{
    // transform the vertex position
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    // transform the texture coordinates
    gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;

    // forward the vertex color
    gl_FrontColor = gl_Color;
}
)";

const string VideoMemory::writeShaderFragment = R"(
uniform sampler2D texture;

void main()
{
    // lookup the pixel in the texture
    vec4 pixel = texture2D(texture, gl_TexCoord[0].xy);

    // multiply it by the color
    gl_FragColor = gl_Color * pixel;
}
)";

VideoMemory::VideoMemory(sf::RenderWindow &window, const unsigned int w, const unsigned int h, const uint64_t addr):
	w(w), h(h), address(addr), length(w*h), window(window), dirty(false) {
	renderTex.create(w, h);
	tex = &renderTex.getTexture();
	gpuSpr = sf::Sprite(*tex);
	img = tex->copyToImage();
	rwTex = sf::Texture();
	rwTex.create(w, h);
	cpuSpr = sf::Sprite(rwTex);

    // Tenta carregar o shader, em caso de erro termina
    // uma vez que não será possível mostrar nada
    if (!writeShader.loadFromMemory(writeShaderVertex, writeShaderFragment)) {
        cout << "video " << "error loading write shader" << endl;
        exit(1);
    }
}

VideoMemory::~VideoMemory() {

}

void VideoMemory::draw() {
	renderTex.draw(cpuSpr, &writeShader);

	window.draw(gpuSpr);
}

uint64_t VideoMemory::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
	unsigned int x, y;

	x = (unsigned int)p % w;
	y = (unsigned int)p / w;

    if (x > w || y > h) {
        return 0;
    }
	
    sf::Texture::bind(&rwTex);
    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, data);

	return size;
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

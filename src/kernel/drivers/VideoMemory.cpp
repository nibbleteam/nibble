#include <SFML/OpenGL.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <iostream>
#include <cstring>

const uint64_t VideoMemory::nibblesPerPixel = 8;
const uint64_t VideoMemory::bytesPerPixel = 4;

// Vertex shader padrão do SFML sem alterações
const string VideoMemory::writeShaderVertex = R"(
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

// Recebe uma textura com 1/8 do comprimento da tela
// esticada para o tamanho da tela e endereça cada 
// pixel na imagem como 8 pixels na tela.
// Para fazer isso considera cada canal como
// dois números de 4 bits
const string VideoMemory::writeShaderFragment = R"(
// Converte um float [0-1] para o byte menos
// significativo de um inteiro
#define BYTE(x) int(x*255.0)
// Acessa o low nibble do byte menos significativo
// de um inteiro
#define LOW(x) (x-x/16*16)
// Acessa o high nibble
#define HIGH(x) (x/16)
// Nibble para float
#define NIB2F(x) (float(x)/16.0)

const float screen_w = 320.0;
// 4 canais na textura (RGBA)
const float bytes_per_pixel = 4.0;
// 2 nibbles por byte
const float nibbles_per_pixel = 2.0*bytes_per_pixel;

// Textura "esticada"
uniform sampler2D texture;
// Textura 1xN da paleta
uniform sampler2D palette;

void main()
{
    // Coordenadas no espaço da textura
    vec2 coord = gl_TexCoord[0].xy;
    // Em qual nibble do pixel estamos
    int nibble = int(mod(coord.x*screen_w, nibbles_per_pixel));
    // Em qual byte do pixel estamos
    int byte = nibble/2; 
    // Em qual nibble deste byte (high são os pares)
    bool high_nibble = mod(float(nibble), 2.0) == 0.0;

    // Cor do pixel na textura
    vec4 pixel = texture2D(texture, coord);

    // Qual canal do pixel da textura vamos
    // usar para o pixel na tela
    int source;
    // Primeiro byte, segundo byte etc
    if (byte == 0)
        source = BYTE(pixel.r);
    else if (byte == 1)
        source = BYTE(pixel.g); 
    else if (byte == 2)
        source = BYTE(pixel.b);
    else if (byte == 3)
        source = BYTE(pixel.a);

    // Usamos o high_nibble de source
    if (high_nibble) {
        float palette_index = NIB2F(HIGH(source));
        vec4 color = texture2D(palette, vec2(palette_index, 0));
 
        // Não desenha pixels transparentes
        if (color.a != 1.0)
            discard;

        gl_FragColor = vec4(color.rgb, 1.0);
    }
    // Usamos o low_nibble de source
    else {
        float palette_index = NIB2F(LOW(source));
        vec4 color = texture2D(palette, vec2(palette_index, 0));
    
        // Não desenha pixels transparentes
        if (color.a != 1.0)
            discard;

        gl_FragColor = vec4(color.rgb, 1.0);
    }
}
)";

VideoMemory::VideoMemory(sf::RenderWindow &window,
                         const unsigned int w,
                         const unsigned int h,
                         const uint64_t addr):
	w(w), h(h), address(addr), length(w*h/2), window(window), dirty(false) {
	renderTex.create(w, h);
	tex = &renderTex.getTexture();
	gpuSpr = sf::Sprite(*tex);
	img = tex->copyToImage();
	rwTex = sf::Texture();
    // Tamanho da textura é 1/8 do tamanho da tela
    // uma vez que cada pixel no oort é um nibble
    // e no sfml são quatro bytes
	rwTex.create(w/nibblesPerPixel, h);
    rwTex.setRepeated(false);

	cpuSpr = sf::Sprite(rwTex);
    // Faz preencher toda a tela
    // e inverte o y
    cpuSpr.setScale(nibblesPerPixel, -1);
    cpuSpr.setPosition(0, h);

    // Cria a textura da palleta
    paletteTex.create(GPU::paletteLength*GPU::paletteAmount, 1);

    // Tenta carregar o shader, em caso de erro termina
    // uma vez que não será possível mostrar nada
    if (!writeShader.loadFromMemory(writeShaderVertex, writeShaderFragment)) {
        cout << "video " << "error loading write shader" << endl;
        exit(1);
    }
    // Adiciona paleta e textura ao shader
    else {
        writeShader.setUniform("texture", rwTex);
        writeShader.setUniform("palette", paletteTex);
    }

    const uint64_t videoRamSize = w*h/2;

    // Limpa a memória de vídeo em RAM para 
    // deixar sincronizado com as texturas que estão limpas
    buffer = new uint8_t[videoRamSize];
    for (unsigned int i=0;i<videoRamSize;i++) {
            buffer[i] = 0;
    }

    // Inicializa com bytes não inicializados
    rwTex.update(buffer, rwTex.getSize().x, rwTex.getSize().y, 0, 0);
    
    // Abre um GIF pra salvar a tela
    int error;
    gif = EGifOpenFileName("screencast.gif", false, &error);
    EGifSetGifVersion(gif, true);
    GifColorType colors[256];
    colors[0] = GifColorType{0, 0, 0};
    for (int i=1;i<256;i++) {
        colors[i] = GifColorType{rand(), rand(), rand()};
    }
    colormap = GifMakeMapObject(256, colors);
    if (error != GIF_OK)
        cout << GifErrorString(error) << endl;
    error = EGifPutScreenDesc(gif, 320/2, 240,
                      3*256, 0,
                      colormap);
    GifFreeMapObject(colormap);
    if (error != GIF_OK)
        cout << GifErrorString(error) << endl;
}

VideoMemory::~VideoMemory() {
    int error;
    EGifCloseFile(gif, &error);
    if (error != GIF_OK)
        cout << GifErrorString(error) << endl;
    delete buffer;
}

void VideoMemory::draw() {
    int error;
	renderTex.draw(cpuSpr, &writeShader);
	window.draw(gpuSpr);

    char graphics[] {
        0, 2&0xFF, 2>>8, 0
    };
    error = EGifPutExtension(
        gif,
        GRAPHICS_EXT_FUNC_CODE,
        sizeof(graphics),
        &graphics);
    if (error != GIF_OK)
        cout << GifErrorString(error) << endl;

    error = EGifPutImageDesc(gif, 0, 0, 320/2, 240,
                     false, NULL);
    if (error != GIF_OK)
        cout << GifErrorString(error) << endl;
    error = EGifPutLine(gif, buffer, 320*240/2);
    if (error != GIF_OK)
        cout << GifErrorString(error) << endl;
}

void VideoMemory::updatePalette(const uint8_t* palette) {
    paletteTex.update(palette, paletteTex.getSize().x, paletteTex.getSize().y, 0, 0);
}

// Quantos bytes podemos transferir a partir do byte atual
uint64_t VideoMemory::nextTransferAmount(uint64_t current, uint64_t initial, uint64_t size) {
    // Terminamos
    if (current-initial >= size) {
        return 0;
    }

    // Se estamos no início de uma linha
    if (!(current%(w/2))) {
        // e temos uma ou mais linhas para transferir, podemos transferi-las de uma vez
        uint64_t pixels = (size-(current-initial))*2;
        if (pixels >= w) {
            return ((pixels/w)*w)/2;
        }
        // se não, podemos transferir até o final dos dados
        else {
            return (size-(current-initial));
        }
    }
    // senão só podemos transferir até o final desta linha ou dos dados
    else {
        if (size > 4) {
            uint64_t pixels = (size-(current-initial))*2;
            if (pixels >= w) {
                return w/2-(current%(w/2));
            } else {
                return (size-(current-initial));
            }
        }
        else {
            return size;
        }
    }
}

uint64_t VideoMemory::bytesToTransferPixels(uint64_t bytes) {
    return bytes%bytesPerPixel == 0 ?
            bytes/bytesPerPixel : bytes/bytesPerPixel + 1;
}

uint64_t VideoMemory::bytesToPixels(uint64_t bytes) {
    return bytes/bytesPerPixel;
}

uint64_t VideoMemory::transferWidth(uint64_t pixels) {
    if (pixels > w/nibblesPerPixel) {
        return w/nibblesPerPixel;
    } else {
        return pixels;
    }
}

uint64_t VideoMemory::transferHeight(uint64_t pixels) {
    if (pixels/(w/nibblesPerPixel) > 0) {
        return pixels/(w/nibblesPerPixel);
    } else {
        return 1;
    }
}

// Escreve data (que tem size bytes) na posição p na memória de vídeo
uint64_t VideoMemory::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
    // Copia dados para RAM
    memcpy(buffer+p, data, size);

    // Transfere para a GPU
    uint64_t transfered = 0;
    uint64_t toTransfer = 0;
    // Quantos bytes transferir
    while (toTransfer = nextTransferAmount(p+transfered, p, size)) {
        uint8_t *pixels;
        unsigned int x, y, offset;

        // Onde colocar
        x = bytesToPixels(p+transfered) % (w/nibblesPerPixel);
        y = bytesToPixels(p+transfered) / (w/nibblesPerPixel);
        // Inicia em qual byte dentro do pixel?
        offset = (p+transfered)%bytesPerPixel;

        // Alinha o ponteiro a margem do pixel,
        // Fazemos isso porque o OpenGL não
        // consegue atualizar apenas um byte.
        switch (offset) {
            case 0:
                pixels = buffer+p+transfered;
                break;
            case 1:
                pixels = buffer+p+transfered-1;
                break;
            case 2:
                pixels = buffer+p+transfered-2;
                break;
            case 3:
                pixels = buffer+p+transfered-3;
                break;
        }

        // Upload
        // Quantos pixels
        uint64_t transferPixels = bytesToTransferPixels(toTransfer);
        // Que equivalem a uma área de...
        unsigned int tw = transferWidth(transferPixels);
        unsigned int th = transferHeight(transferPixels);
        // Qual textura
        sf::Texture::bind(&rwTex);
        // Go go go
        glTexSubImage2D(GL_TEXTURE_2D, 0,
                        x, y,
                        tw, th,
                        GL_RGBA, GL_UNSIGNED_BYTE,
                        pixels);
        // Remove a textura
        sf::Texture::bind(NULL);
        
        transfered += toTransfer;
    }

	return transfered;
}

uint64_t VideoMemory::read(const uint64_t p, uint8_t* data, const uint64_t size) {
    // Será necessário quando estivermos usando a GPU para desenhar
	//if (dirty) {
	//	// Carrega da GPU para a RAM
	//	img = tex->copyToImage();
	//	dirty = false;
	//}

    // Copia da memória de vídeo para o buffer do cliente
    memcpy(data, buffer+p, size);
	
	return size;
}

uint64_t VideoMemory::size() {
	return length;
}

uint64_t VideoMemory::addr() {
	return address;
}

#include <SFML/OpenGL.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <iostream>
#include <cstring>

const uint64_t VideoMemory::nibblesPerPixel = 8;
const uint64_t VideoMemory::bytesPerPixel = 4;
const uint32_t VideoMemory::vertexArrayLength = 4096;

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

// Recebe duas texturas com 1/4 do comprimento da tela
// esticada para o tamanho da tela e endereça cada 
// pixel na imagem como 4 pixels na tela.
// Para fazer isso considera cada canal como
// um pixel
// Além disso, utiliza duas texturas adicionais com as
// informações de timing das duas texturas utilizadas para desenhar
// de forma que pode escolher apenas desenhar cada pixel
// daquela atualizada mais recentemente
const string VideoMemory::writeShaderFragment = R"(
// Converte um vetor de float pra um int de 4bytes
#define INT4BYTES(x) int(x.r*255.0)*256*256*256+int(x.g*255.0)*256*256+int(x.b*255.0)*256+int(x.a*255.0)

const float screen_w = 320.0;
// 4 canais na textura (RGBA)
const float bytes_per_pixel = 4.0;

// Primeira textura "esticada", desenhos da CPU
uniform sampler2D cpuTexture;
// Segunda textura, desenhos da GPU 
uniform sampler2D gpuTexture;
// Timing
uniform sampler2D cpuTiming;
uniform sampler2D gpuTiming;
// Textura 1xN da paleta
uniform sampler2D palette;

void main()
{
    // Coordenadas no espaço da textura
    vec2 coord = gl_TexCoord[0].xy;
    // Em qual byte do pixel estamos
    int byte = int(mod(coord.x*screen_w, bytes_per_pixel));

    vec4 cpuTimeV = texture2D(cpuTiming, coord);
    vec4 gpuTimeV = texture2D(gpuTiming, coord);

    int cpuTime = INT4BYTES(cpuTimeV);
    int gpuTime = INT4BYTES(gpuTimeV);

    // Não altera o buffer se nem a CPU nem a GPU
    // desenharam esse pixel
    // Se esse shader for utiliazado para desenhar
    // diretamente no framebuffer pode causar problemas
    //if (cpuTime == 0 && gpuTime == 0)
    //    discard;

    // Cor do pixel na textura
    vec4 pixel;
    
    // Utiliza o buffer mais atualizado
    if (cpuTime >= gpuTime) {
        pixel = texture2D(cpuTexture, coord);
    } else {
        pixel = texture2D(gpuTexture, coord);
    }

    // Qual canal do pixel da textura vamos
    // usar para o pixel na tela
    float source;
    // Primeiro byte, segundo byte etc
    // Os módulos limitam a 8 paletas
    if (byte == 0)
        source = mod(pixel.r, 0.5);
    else if (byte == 1)
        source = mod(pixel.g, 0.5); 
    else if (byte == 2)
        source = mod(pixel.b, 0.5);
    else if (byte == 3)
        source = mod(pixel.a, 0.5);

    vec4 color = texture2D(palette, vec2(source, 0));

    // Não desenha pixels transparentes
    if (color.a == 0.0)
        discard;

    gl_FragColor = vec4(color.rgb, 1.0);
}
)";

VideoMemory::VideoMemory(sf::RenderWindow &window,
                         const unsigned int w,
                         const unsigned int h,
                         const uint64_t addr):
	w(w), h(h), address(addr), length(w*h), window(window), dirty(false),
    colormap(NULL), cpuTimingCount(0), gpuTimingCount(0), currentDraw(0) {
    // Tamanho da textura é 1/4 do tamanho da tela
    // uma vez que um pixel no sfml são quatro bytes
    // e no console é apenas um
	cpuTexture.create(w/bytesPerPixel, h);
	gpuRenderTexture.create(w/bytesPerPixel, h);
    // Timings das operações de desenho
    cpuTiming.create(w, h);
    gpuRenderTiming.create(w, h);

    // Texturas para ler as RenderTextures
	auto &gpuTexture = gpuRenderTexture.getTexture();
    auto &gpuTiming = gpuRenderTiming.getTexture();

    // Sprites para desenhar as RenderTextures
	gpuSpr = sf::Sprite(gpuTexture);
	cpuSpr = sf::Sprite(cpuTexture);

    // Faz preencher toda a tela (uma vez que ela tem 1/4 do tamanho)
    gpuSpr.setScale(bytesPerPixel, 1);

    // Cria a textura da palleta
    paletteTex.create(GPU::paletteLength*GPU::paletteAmount, 1);

    // Tenta carregar o shader, em caso de erro termina
    // uma vez que não será possível mostrar nada
    if (!writeShader.loadFromMemory(writeShaderVertex, writeShaderFragment)) {
        cout << "video " << "error loading write shader" << endl;
        exit(1);
    }
    else {
        // Passa texuras de entrada
        writeShader.setUniform("cpuTexture", cpuTexture);
        writeShader.setUniform("gpuTexture", gpuTexture);

        // Passa texturas de timing
        writeShader.setUniform("cpuTiming", cpuTiming);
        writeShader.setUniform("gpuTiming", gpuTiming);

        // Passa paleta para o shader
        writeShader.setUniform("palette", paletteTex);
    }

    const uint64_t videoRamSize = w*h;

    // Inicializa a memória
    buffer = new uint8_t[videoRamSize];
    for (unsigned int i=0;i<videoRamSize;i++) {
        //buffer[i] = (i>>8)%3;
        buffer[i] = 0;
    }
    timingBuffer = new uint8_t[bytesPerPixel*videoRamSize];

    // Inicializa com bytes não inicializados
    cpuTexture.update(buffer);
}

VideoMemory::~VideoMemory() {
    if (colormap != NULL) {
        stopCapturing();
    }

    delete timingBuffer;
    delete buffer;
}

bool VideoMemory::startCapturing(const string& path) {
    int error;

    // Cria um colormap a partir da paleta
    colormap = getColorMap();

    // Abre um GIF pra salvar a tela
    gif = EGifOpenFileName(path.c_str(), false, &error);
    // Versão nova do GIF
    EGifSetGifVersion(gif, true);
    // Coonfigurações da screen
    error = EGifPutScreenDesc(gif, w, h,
                      GPU::paletteLength*GPU::paletteAmount, 0,
                      colormap);
    // Limpa a paleta que foi escrita
    GifFreeMapObject(colormap);

    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    char loop[] {
        0x01, 0x00, 0x00
    };
    error = 0;
    error |= EGifPutExtensionLeader(gif, APPLICATION_EXT_FUNC_CODE);
    error |= EGifPutExtensionBlock(gif, 0x0b, "NETSCAPE2.0");
    error |= EGifPutExtensionBlock(gif, 0x03, loop);
    error |= EGifPutExtensionTrailer(gif);

    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    return true;
}

bool VideoMemory::stopCapturing() {
    int error;
    EGifCloseFile(gif, &error);
    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    gif = NULL;
    colormap = NULL;

    return true;
}

bool VideoMemory::captureFrame() {
    int error;
    char graphics[] {
        0, 2&0xFF, 2>>8, 0
    };
    error = EGifPutExtension(
        gif,
        GRAPHICS_EXT_FUNC_CODE,
        sizeof(graphics),
        &graphics);

    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }

    error = EGifPutImageDesc(gif, 0, 0, w, h,
                             false, NULL);
    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }
    error = EGifPutLine(gif, buffer, w*h);
    if (error != GIF_OK) {
        cerr << GifErrorString(error) << endl;
        return false;
    }
}

ColorMapObject* VideoMemory::getColorMap() {
    // Tamanho da paleta do console
    uint64_t paletteSize = GPU::paletteLength*GPU::paletteAmount;
    // "Paleta" do GIF
    GifColorType colors[paletteSize];
    auto image = paletteTex.copyToImage();

    // Preenche o color map no formato do GIF
    // a partir do formato de paleta do console
    for (uint64_t i=0;i<paletteSize;i++) {
        sf::Color color = image.getPixel(i, 0);
        // Remove o alpha
        colors[i] = GifColorType {
            color.r, color.g, color.b
        };
    }

    colormap = GifMakeMapObject(paletteSize, colors);

    return colormap;
}

void VideoMemory::clearCpuTiming() {
    memset(timingBuffer, 0, w*h*4);
    cpuTiming.update(timingBuffer, w, h, 0, 0);
}

void VideoMemory::drawCpuTiming(uint32_t time, uint64_t p, uint64_t size) {
    // A textura de timing tem 4 bytes por pixel
    p = p*sizeof(time);
    // Escreve os primeiros 4 bytes
    memmove(timingBuffer+p, (uint8_t*)&time, sizeof(time));

    uint64_t end = p+size*sizeof(time);

    // Copia os outros
    while (p+sizeof(time) < end) {
        memmove(timingBuffer+p+sizeof(time), timingBuffer+p, sizeof(time));

        p += sizeof(time);
    }

    cpuTimingCount++;
}

void VideoMemory::drawGpuTiming(uint64_t time,
                                const uint32_t x, const uint32_t y,
                                const uint32_t w, const uint32_t h) {
    // Dividido por quatro porque usamos quads
    uint32_t array = gpuTimingCount / (vertexArrayLength/4);
    uint32_t position = gpuTimingCount % (vertexArrayLength/4);

    if (gpuTimingArrays.size() <= array) {
        gpuTimingArrays.push_back(
            sf::VertexArray(sf::Quads, vertexArrayLength)
        );
    }

    // Time não pode ser zero (zero = não desenhado)
    time ++;

    // Converte o timing para uma cor
    sf::Color color = *(sf::Color*)&time;
    //sf::Color color {time>>8, time, 255, 255};

    // Índiced dos vertices
    auto a = position*4,
         b = position*4+1,
         c = position*4+2,
         d = position*4+3;

    gpuTimingArrays[array][a].position = sf::Vector2f(x, y);
    gpuTimingArrays[array][b].position = sf::Vector2f(x+w, y);
    gpuTimingArrays[array][c].position = sf::Vector2f(x+w, y+h);
    gpuTimingArrays[array][d].position = sf::Vector2f(x, y+h);

    gpuTimingArrays[array][a].color = color;
    gpuTimingArrays[array][b].color = color;
    gpuTimingArrays[array][c].color = color;
    gpuTimingArrays[array][d].color = color;

    gpuTimingCount++;
}

void VideoMemory::draw() {
    if (colormap == NULL) {
        startCapturing("screencap.gif");
    } else {
        captureFrame();
    }

    if (gpuTimingArrays.size() > 0) {
        // Corta parte que nãp foi redesenhada fora do buffer
        uint32_t cutStart = gpuTimingCount/(vertexArrayLength/4);
        gpuTimingArrays[cutStart].resize(
            (gpuTimingCount % (vertexArrayLength/4))*4
        );
        for (cutStart++;cutStart<gpuTimingArrays.size();cutStart++) {
            gpuTimingArrays[cutStart].resize(0);
        }
    }

    // Calcula o timing que cada pixel foi escrito
    // pela GPU
    for (auto &array : gpuTimingArrays) {
        gpuRenderTiming.draw(array, sf::BlendNone);
    }

    cpuTiming.update(timingBuffer, w, h, 0, 0);
    cpuTexture.update(buffer, w/4, h, 0, 0);

    // Copia da nossa textura rw da cpu 
    // para a textura read-only da gpu
    // Utiliza BlendNone para copiar o alpha também
	//gpuRenderTexture.draw(cpuSpr, sf::BlendNone);
	// Desenha o framebuffer na tela, usando o shader para converter do
    // formato 1byte por pixel para cores RGBA nos pixels
    window.draw(gpuSpr, &writeShader);

    // Atualiza a RAM
    auto img = gpuSpr.getTexture()->copyToImage();

    // Zera o timing dos draws
    currentDraw = 0;
    cpuTimingCount = 0;
    gpuTimingCount = 0;
    gpuRenderTiming.clear(sf::Color::Transparent);
    clearCpuTiming();
}

void VideoMemory::updatePalette(const uint8_t* palette) {
    paletteTex.update(palette, paletteTex.getSize().x, paletteTex.getSize().y, 0, 0);
}

// Escreve data (que tem size bytes) na posição p na memória de vídeo
uint64_t VideoMemory::write(const uint64_t p, const uint8_t* data, const uint64_t size) {
    // Copia dados para RAM
    memcpy(buffer+p, data, size);
    drawCpuTiming(currentDraw, p, size);
    currentDraw++;
	return size;
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

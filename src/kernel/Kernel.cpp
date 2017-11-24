#include <kernel/Kernel.hpp>
#include <kernel/drivers/RAM.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <algorithm>
#include <iostream>

using namespace std;

Kernel *KernelSingleton;

Kernel::Kernel():
	window(sf::VideoMode(320, 240), "PongBoy"),
	lastPid(1),
	lastUsedMemByte(0) {
    window.setFramerateLimit(60);

	createMemoryMap();

	// TODO: Erro quando não conseguir lançar o processo,
	// talvez um pequeno processo codificado em C++ diretamente
	// apenas para mostrar mensagens de erro e coisas parecidas?
	// e.g.: um processo "system"
	exec("apps/shell", vector<string>());
}

Kernel::~Kernel() {
	destroyMemoryMap();
	for (auto process : processes) {
		delete process;
	}
    delete gpu;
}

void Kernel::addMemoryDevice(Memory* device) {
	ram.push_back(device);
	lastUsedMemByte += device->size();
}

// Mapeia os dispositivos (placa de vídeo, placa de áudio, controles, leds etc)
// para a RAM
void Kernel::createMemoryMap() {
    gpu = new GPU(window, 320, 240, lastUsedMemByte);
    addMemoryDevice(gpu->getCommandMemory());
	addMemoryDevice(gpu->getPaletteMemory());
	addMemoryDevice(gpu->getVideoMemory());
	//addMemoryDevice(new RAM(lastUsedMemByte, 32*1024));
}

void Kernel::destroyMemoryMap() {
	// Deleta todos os dispositivos mapeados em memória
	// exceto aqueles que são processos, que são deletados
	// pelos respectivos processos
	for (auto memory: ram) {
		bool rm = true;

		for (auto process : processes) {
			if (process->getMemory() == memory) {
				rm = false;
			}
		}

		if (rm) delete memory;
	}
}

void Kernel::loop() {
    sf::Clock clock;
    float lastTime = 0;
    
	while (window.isOpen()) {
        float currentTime = clock.getElapsedTime().asSeconds();
        float fps = 1.f / (currentTime - lastTime);
        lastTime = currentTime;
        cerr << fps << "\r";

		sf::Event event;

		// Event handling
		while (window.pollEvent(event)) {
			if (event.type == sf::Event::Closed) {
				window.close();
			} else
            if (event.type == sf::Event::Resized) {
                window.setSize(sf::Vector2u(event.size.width, event.size.height));
            }
		}

		// Roda o processo no topo da lista de processos
		if (processes.size() > 0) {
			Process *p = processes.back();

			// Traz o cart do processo pra RAM se já não estiver
			if (!p->isMapped()) {
				// TODO: unmap o processo que estava mapeado
				// anteriormente se existir
				ram.push_back(p->getMemory());

                p->init();
			}

			// Chama as callbacks do processo
			p->update();
			p->draw();
		}

		gpu->draw();
		window.display();
	}
}

// API de gerenciamento de processos

// Executa "executable" passando "environment"
// executable é um diretório que deve seguir a seguinte organização:
// <cart-name>/
//	- assets/
//  - main.lua
uint64_t Kernel::exec(const string& executable, vector<string> environment) {
	Path executablePath(executable);

	// Verifica a existência e estrutura de do cart "executable"
	if (!checkCartStructure(executablePath)) {
		return 0;
	}

	// Cria o processo carregando o cart para a memória na
	// primeira localização livre
	auto process = new Process(executablePath, environment, lastPid++, lastUsedMemByte);

	// Adiciona as chamadas de sistema providas pelo Kernel
	// ao ambiente lua do processo
	process->addSyscalls();

	// Adiciona ao início da pilha de execução de forma que não será
	// executado até que todos os outros saiam ou um yield seja chamado
	// (ou caso esse seja o único processo na pilha)
	processes.push_front(process);

	return process->getPid();
}

// Libera o fluxo de controle para "to"
bool Kernel::yield(const uint64_t pid, const uint64_t to) {
	return false;
}

void Kernel::exit(const uint64_t pid) {
	for (auto process : processes) {
		if (process->getPid() == pid) {
			processes.remove(process);
			break;
		}
	}
}

// API de acesso à memória
uint64_t Kernel::write(uint64_t start, const uint8_t* data, uint64_t size) {
	uint64_t end = start + size;
	// Quantos bytes foram escritos
	uint64_t written = 0;

	if (start > end) {
		uint64_t buffer = end;
		end = start;
		start = buffer;
	}

	if (start > lastUsedMemByte) {
		start = lastUsedMemByte;
		size = end - start;
	}

	if (end > lastUsedMemByte) {
		end = lastUsedMemByte;
		size = end - start;
	}

	// Segmenta o write para cada bloco de ram em que ele afetar
	for (auto memBlock : ram) {
		uint64_t blkStart = memBlock->addr(), blkSize = memBlock->size();
		uint64_t blkEnd = blkStart + blkSize;

		// Verifica se o write afeta esse bloco de memória
		if (blkEnd >= start && blkStart <= end) {
			// Calcula as boundaries do write para atingir apenas esse bloco
			uint64_t writeStart, writeEnd;

			if (blkStart < start) {
				writeStart = start;
			}
			else {
				writeStart = blkStart;
			}

			if (blkEnd > end) {
				writeEnd = end;
			}
			else {
				writeEnd = blkEnd;
			}

			// Executa um write apenas nesse bloco
			written += memBlock->write(writeStart-blkStart, data+(writeStart-start), writeEnd - writeStart);
		}
	}

	return written;
}

string Kernel::read(uint64_t start, uint64_t size) {
	uint64_t end = start + size;
	// Quantos bytes foram lidos
	uint64_t numRead = 0;

	if (start > end) {
		uint64_t buffer = end;
		end = start;
		start = buffer;
	}

	if (start > lastUsedMemByte) {
		start = lastUsedMemByte;
		size = end - start;
	}

	if (end > lastUsedMemByte) {
		end = lastUsedMemByte;
		size = end - start;
	}

	string stringBuffer((size_t)size, '\0');
	uint8_t* buffer = (uint8_t*)&stringBuffer[0];

	// Segmenta o read para cada bloco de ram em que ele afetar
	for (auto memBlock : ram) {
		uint64_t blkStart = memBlock->addr(), blkSize = memBlock->size();
		uint64_t blkEnd = blkStart + blkSize - 1;

		// Verifica se o read afeta esse bloco de memória
		if (blkEnd >= start && blkStart <= end) {
			// Calcula as boundaries do read para atingir apenas esse bloco
			uint64_t readStart, readEnd;

			if (blkStart < start) {
				readStart = start;
			}
			else {
				readStart = blkStart;
			}

			if (blkEnd > end) {
				readEnd = end;
			}
			else {
				readEnd = blkEnd;
			}

			// Executa um read apenas nesse bloco
			numRead += memBlock->read(readStart - blkStart, buffer + (readStart - start), readEnd - readStart);
		}
	}

	return stringBuffer;
}

bool Kernel::checkCartStructure(Path& root) {
	cout << "kernel " << "checking cart " << root.getPath() << endl;

	Path lua = root.resolve(Process::LuaEntryPoint);
	Path assets = root.resolve(Process::AssetsEntryPoint);

	cout << "	" << " checking if dir " << assets.getPath() << endl;
	cout << "	" << " checking if file " << lua.getPath() << endl;

	return fs::isDir(root) &&
		   fs::isDir(assets) &&
		   !fs::isDir(lua);
}

// Wrapper estático para a API
unsigned long kernel_api_write(unsigned long to, const string data) {
	return (unsigned long)KernelSingleton->write(to, (uint8_t*)data.data(), data.size());
}

string kernel_api_read(const unsigned long from, const unsigned long amount) {
	return KernelSingleton->read(from, amount);
}

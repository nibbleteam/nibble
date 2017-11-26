#ifndef KERNEL_H
#define KERNEL_H

#include <cstdint>
#include <vector>
#include <list>
#include <string>
#include <kernel/filesystem.hpp>
#include <kernel/Process.hpp>
#include <kernel/Memory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <SFML/Graphics.hpp>

using namespace std;

// Simula o hardware do console e um kernel com
// seis chamadas de sistema. Três para gerenciar
// a memória e três para gerenciar processos.
class Kernel {
	sf::RenderWindow window;
	// Memória para acesso direto aos dispositivos
    // Cada seção específica (joysticks, video, cart)
    // é implementada como uma extensão
    // da classe Memory
    vector <Memory*> ram;
    // Contém todos os processos carregados em memória
    // apenas um está em execução a cada instante (o último elemento da lista)
    list <Process*> processes;
	// Contador de ID para os processos gerados
	uint64_t lastPid;
	// Aponta para o último byte usado de memória
	uint64_t lastUsedMemByte;
	// GPU 
    GPU *gpu;
public:
    Kernel();
    ~Kernel();

    // Loop principal do console. Atualiza o processo em execução e desenha a tela.
    void loop();

    // API do kernel
    // Acesso direto a memória
    // O acesso ao vídeo e áudio também é feito através de
    // writes e reads
    // Estas funções operam no vetor de ram, dividindo suas
    // chamadas em blocos unitários que podem ser executados
    // por um dos elementos de ram (dispositivos)
    uint64_t write(uint64_t, const uint8_t*, uint64_t);
    string read(uint64_t, uint64_t);
    // Gerenciamento de processos
    uint64_t exec(const string&, vector<string>);
    bool yield(const uint64_t, const uint64_t);
    void exit(const uint64_t);
private:
    // Mapeia dispositivos para a memória, essencialmente
    // adicionando dispositivos ao vetor ram. Chamada pelo
    // construtor
    void createMemoryMap();
    void destroyMemoryMap();
	void addMemoryDevice(Memory*);
	// Verifica estrutura de um cartridge
	bool checkCartStructure(Path&);
};

extern Kernel *KernelSingleton;

// API estática para o acesso via Lua
unsigned long kernel_api_write(const unsigned long, const string);
string kernel_api_read(const unsigned long, const unsigned long);

#endif /* KERNEL_H */

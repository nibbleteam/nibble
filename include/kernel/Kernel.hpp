#ifndef KERNEL_H
#define KERNEL_H

#include <cstdint>
#include <vector>
#include <set>
#include <string>
#include <mutex>
#include <SFML/Graphics.hpp>
#include <kernel/filesystem.hpp>
#include <kernel/Process.hpp>
#include <kernel/Memory.hpp>
#include <kernel/drivers/GPU.hpp>
#include <kernel/drivers/Audio.hpp>
#include <kernel/drivers/Keyboard.hpp>
#include <kernel/drivers/Mouse.hpp>
#include <kernel/drivers/Controller.hpp>
#include <LuaBridge/LuaBridge.h>

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
    set <Process*> processes;
    // Contador de ID para os processos gerados
    uint64_t lastPid;
    // Usado para saber qual o pid que fez uma chamada de sistema
    Process* runningProcess;
    // Aponta para o último byte usado de memória
    uint64_t lastUsedMemByte;
    // GPU 
    GPU *gpu;
    // HID
    Keyboard *keyboard;
    Mouse *mouse;
    Controller *controller;
    // Placa de áudio
    Audio *audio;
    // Não deixa a callback de áudio/vídeo serem chamadas ao mesmo
    // tempo
    mutex audioMutex;
    // Waitlist: processos que estão bloqueados
    // esperando utros processos
    map<uint64_t, uint64_t> waitlist;
public:
    Kernel();
    ~Kernel();

    // Controles de power e botões de hardware
    void startup();
    void shutdown();
    void reset();
    void menu();

    // Loop principal do console. Atualiza o processo em execução e desenha a tela.
    void loop();
    // Tick do audio
    void audio_tick(uint8_t);

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
    // Executa app
    int64_t exec(const string&, map<string, string>);
    // Bloqueia enquanto app não sair
    void wait(const uint64_t);
    // Fecha uma app
    void kill(const uint64_t);
    // Environment de processos
    void setenv(const string, const string);
    string getenv(const string);
    // IPC
    luabridge::LuaRef receive();
    bool send(const uint64_t, luabridge::LuaRef);
private:
    // Mapeia dispositivos para a memória, essencialmente
    // adicionando dispositivos ao vetor ram. Chamada pelo
    // construtor
    void createMemoryMap();
    void destroyMemoryMap();
    void addMemoryDevice(Memory*);
    // Verifica estrutura de um cartridge
    bool checkCartStructure(Path&);
    // Desbloqueia processos se estiverem
    // na waitlist e o bloqueador já estiver
    // saído
    void checkWaitlist();
};

extern Kernel *KernelSingleton;

// API estática para o acesso via Lua
string kernel_api_read(const unsigned long, const unsigned long);
unsigned long kernel_api_write(const unsigned long, const string);
unsigned long kernel_api_exec(const string, luabridge::LuaRef);
void kernel_api_wait(unsigned long);
void kernel_api_kill(unsigned long);
void kernel_api_setenv(const string, const string);
string kernel_api_getenv(const string);
luabridge::LuaRef kernel_api_receive();
bool kernel_api_send(unsigned long, luabridge::LuaRef);

#endif /* KERNEL_H */


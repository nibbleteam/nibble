#ifndef KERNEL_H
#define KERNEL_H

#include <cstdint>
#include <memory>
#include <vector>
#include <set>
#include <string>
#include <mutex>
#include <atomic>
#include <list>

#include <kernel/filesystem.hpp>
#include <kernel/Process.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Types.hpp>

#include <devices/GPU.hpp>
#include <devices/Audio.hpp>
#include <devices/Keyboard.hpp>
#include <devices/Mouse.hpp>
#include <devices/Controller.hpp>

#include <LuaBridge/LuaBridge.h>

using namespace std;

#define NIBBLE_APP_MENU     "apps/system/menu.nib"

// Simula o hardware do console e um kernel.
class Kernel {
private:
    /* Memória */
    Memory memory;

    /* Processos */

    // Contador de ID para os processos gerados
    PID lastProcess;
    // Processo atual, usado para saber quem
    // chamou as chamadas de sistema
    atomic<PID> runningProcess;
    // Lista de processos executando ou bloqueando
    map <PID, shared_ptr<Process>> processes;
    // Tabela de esperas
    map <PID, PID> waitTable;

    /* Dispositivos */

    // GPU 
    unique_ptr<GPU> gpu;
    // APU
    unique_ptr<Audio> audio;
    // HID
    unique_ptr<Keyboard> keyboard;
    unique_ptr<Mouse> mouse;
    unique_ptr<Controller> controller;

    // Usado para sincronizar o vídeo com a placa
    // de áudio
    mutex audioMutex;
public:
    Kernel();
    ~Kernel();

    // Controles de power e botões de hardware
    void startup();
    void shutdown();
    void reset();
    void menu();

    // Sinal de sincronização do áudio
    void audioTick();

    // Loop principal do console. Atualiza o processo em execução e desenha a tela.
    void loop();

    // API do kernel
    // Acesso direto a memória
    // O acesso ao vídeo e áudio também é feito através de
    // writes e reads
    size_t write(size_t, const uint8_t*, size_t);
    string read(size_t, size_t);
    // Gerenciamento de processos
    // Executa app
    tuple<int32_t, string> exec(const string&, map<string, string>&);
    // Bloqueia enquanto app não sair
    void wait(const PID);
    // Fecha uma app
    void kill(const PID);
    // Environment de processos
    void setenv(const string, const string);
    string getenv(const string);
    // IPC
    luabridge::LuaRef receive();
    bool send(const PID, luabridge::LuaRef);
    // Arquivos
    // List diretório
    vector<string> list(const string&);
    // Mapeia arquivo para memória
    size_t memmap(const string&);
    // Salva arquivo mapeado em memória para o disco
    void memsync(const size_t, const string&, bool);
    // Muda o tamanho de um arquivo mapeado
    // em memória
    size_t memresize(const size_t, const size_t);
private:
    // Verifica estrutura de um cartridge
    bool checkAppStructure(Path&);
    // Desbloqueia processos se estiverem
    // na waitlist e o bloqueador já estiver
    // saído
    void updateWaitTable();
};

extern weak_ptr<Kernel> KernelSingleton;

// API estática para o acesso via Lua
string kernel_api_read(const size_t, const size_t);
size_t kernel_api_write(const size_t, const string&);
int kernel_api_exec(lua_State*);
void kernel_api_wait(PID);
void kernel_api_kill(PID);
void kernel_api_setenv(const string, const string);
string kernel_api_getenv(const string);
luabridge::LuaRef kernel_api_receive();
bool kernel_api_send(PID, luabridge::LuaRef);
size_t kernel_api_memmap(const string&);
void kernel_api_memsync(const size_t, const string&, bool);
size_t kernel_api_memresize(const size_t, const size_t);
luabridge::LuaRef kernel_api_list(const string&, lua_State*);

#endif /* KERNEL_H */


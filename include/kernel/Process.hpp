#ifndef PROCESS_H
#define PROCESS_H

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <cstdint>
#include <string>
#include <vector>
#include <kernel/filesystem.hpp>
#include <kernel/Memory.hpp>
#include <kernel/drivers/CartridgeMemory.hpp>
#include <kernel/drivers/VideoMemory.hpp>

using namespace std;

class Process {
    // RAM e estado da vm Lua
    lua_State *st;
    // RAM do cartucho. É colocada na ram
    // principal do kernel quando o cartucho está em execução
    CartridgeMemory *cartridgeMemory;
    // Variáveis ambiente
    vector<string> environment;
    // ID
    const uint64_t pid;
    bool mapped;
    bool ok;
public:
    const static string LuaEntryPoint;
    const static string AssetsEntryPoint;
    const static string NiblibEntryPoint;

    Process(Path&, vector<string>, const uint64_t, const uint64_t, VideoMemory*);
    ~Process();

    // Verifica se não há erros no código
    bool isOk();

    // Roda o processo
    // TODO: delta tempo
    void init();
    void update();
    void draw();

    // Áudio
    void audio_tick(uint8_t);

    // Usado para colocar o cart na ram principal quando
    // esse processo entrar em execução
    Memory* getMemory();
    // Retira o cart da ram
    void unmap();
    // Verifica se o cart está em ram
    bool isMapped();

    const uint64_t getPid();

    void addSyscalls();
};

#endif /* PROCESS_H */

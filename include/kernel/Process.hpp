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
#include <queue>
#include <LuaBridge/LuaBridge.h>
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
    map<string, string> environment;
    // ID
    const uint64_t pid;
    bool mapped;
    bool initialized;
    bool ok;
    bool running;
    // IPC
    // Através de tabelas Lua
    queue<luabridge::LuaRef> receivedMessages;
public:
    Path executable;
    const static string LuaEntryPoint;
    const static string AssetsEntryPoint;
    const static string NiblibEntryPoint;

    Process(Path&, map<string, string>, const uint64_t, const uint64_t, VideoMemory*);
    ~Process();

    // Verifica se não há erros no código
    bool isOk();
    // Verifica se init() já foi chamado
    bool isInitialized();
    // Verifica se o processo está rodando ou em pausa
    bool isRunning();
    void setRunning(bool);

    // Roda o processo
    void init();
    void update(float);
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

    // Controle de environment
    void setEnvVar(const string&, const string&);
    string getEnvVar(const string&);
    map<string, string> getEnv();
    // IPC
    luabridge::LuaRef readMessage();
    void writeMessage(luabridge::LuaRef);
private:
    void copyLuaValue(lua_State*, lua_State*, int);
};

#endif /* PROCESS_H */

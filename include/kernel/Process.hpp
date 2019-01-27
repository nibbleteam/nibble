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
#include <map>
#include <queue>

#include <LuaBridge/LuaBridge.h>

#include <kernel/filesystem.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Types.hpp>

using namespace std;

class Process {
    // RAM e estado da vm Lua
    lua_State *st;
    // Variáveis ambiente
    map<string, string> environment;
    // IPC
    // Através de tabelas Lua
    queue<luabridge::LuaRef> receivedMessages;
protected:
    friend class Kernel;

    // ID
    const PID pid;
    const PID parent;

    bool initialized;
    bool ok;
    bool running;

    // String de erros Lua
    string error;

    // Dados do app
#pragma pack(push, 1)
    struct MemoryLayout {
        // Ponteiro para a spritesheet
        size_t spritesheet;
        // TODO: música, mapas
    };
#pragma pack(pop)

    Memory &memory;
    MemoryLayout &layout;
public:
    Path executable;
    const static string LuaEntryPoint;
    const static string AssetsEntryPoint;
    const static string NiblibEntryPoint;

    Process(Memory&, Path&, map<string, string>, const PID, const PID);
    ~Process();

    // Roda o processo
    void init();
    void update(float);
    void audio_tick();
    void draw();

    void addSyscalls();

    // Controle de environment
    void setEnvVar(const string&, const string&);
    string getEnvVar(const string&);
    map<string, string> getEnv();

    // IPC
    luabridge::LuaRef readMessage();
    void writeMessage(luabridge::LuaRef);
    void clearMessages();

    // Utilizado pelo kernel (com std::set) para ordenar processos
    bool operator < (const Process&);
private:
    void copyLuaValue(lua_State*, lua_State*, int);
    int callWithTraceback(lua_State*, int, int);
};

#endif /* PROCESS_H */

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

#include <LuaBridge/LuaBridge.h>

#include <kernel/filesystem.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Types.hpp>

using namespace std;

class Process {
    // RAM e estado da vm Lua
    lua_State *st;
protected:
    friend class Kernel;

    bool initialized;
    bool ok;
    bool running;

    // String de erros Lua
    string error;

    Memory &memory;
public:
    Path executable;
    const static string lua_entry_point;

    Process(Memory&, Path&);
    ~Process();

    // Roda o processo
    void init();
    void update(float);
    void audio_tick();
    void menu();
private:
    int call_with_traceback(lua_State*, int, int);
};

#endif /* PROCESS_H */

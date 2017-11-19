#ifndef PROCESS_H
#define PROCESS_H

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <cstdint>
#include <string>
#include <kernel/Memory.hpp>
#include <kernel/drivers/CartridgeMemory.hpp>

using namespace std;

class Process {
    // RAM e estado da vm Lua
    lua_State *st;
    // RAM do cartucho. É colocada na ram
    // principal do kernel quando o cartucho está em execução
    CartridgeMemory *cartridgeMemory;
public:
    Process(string&);
	~Process();

    // Usado para colocar na ram principal quando
    // esse processo entrar em execução
    Memory* getMemory();
};

#endif /* PROCESS_H */

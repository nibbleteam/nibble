#ifndef PROCESS_H
#define PROCESS_H

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <cstdint>
#include <string>
#include <filesystem>
#include <kernel/Memory.hpp>
#include <kernel/drivers/CartridgeMemory.hpp>

using namespace std;

class Process {
    // RAM e estado da vm Lua
    lua_State *st;
    // RAM do cartucho. É colocada na ram
    // principal do kernel quando o cartucho está em execução
    CartridgeMemory *cartridgeMemory;
	// ID
	const uint64_t pid;
	// Variáveis ambiente
	vector<string> environment;
	bool mapped;
public:
	const static string LuaEntryPoint;
	const static string AssetsEntryPoint;

    Process(const experimental::filesystem::path&, vector<string>, const uint64_t, const uint64_t);
	~Process();

	// Roda o processo
	// TODO: delta tempo
	void update();
	void draw();

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

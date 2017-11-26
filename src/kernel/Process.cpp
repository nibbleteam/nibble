#include <kernel/Process.hpp>
#include <kernel/Kernel.hpp>
#include <kernel/filesystem.hpp>
#include <LuaBridge/LuaBridge.h>
#include <iostream>

using namespace luabridge;

const string Process::LuaEntryPoint = "main.lua";
const string Process::AssetsEntryPoint = "assets";

Process::Process(Path& executable,
				 vector<string> environment,
				 const uint64_t pid,
				 const uint64_t cartStart):
	environment(environment),
	pid(pid),
	mapped(false) {
	// Pontos de entrada no sistema de arquivos para código
	// e dados do cart
	Path lua = executable.resolve(LuaEntryPoint);
	Path assets = executable.resolve(AssetsEntryPoint);
	
	// Carrega os assets para o cartridge (que será copiado para RAM
	// na localização cartStart)
	cartridgeMemory = new CartridgeMemory(assets, cartStart);

	// Carrega o código
	st = luaL_newstate();
	luaL_openlibs(st);
	luaL_dofile(st, (const char*)lua.getPath().c_str());

	cout << "pid " << pid << " loading cart " << lua.getPath() << endl;
}

Process::~Process() {
	lua_close(st);
}

void Process::addSyscalls() {
	getGlobalNamespace(st)
		.beginNamespace("kernel")
		.addFunction("write", &kernel_api_write)
		.addFunction("read", &kernel_api_read)
		.endNamespace();
}

void Process::init() {
	lua_getglobal(st, "init");
	if (lua_isfunction(st, -1)) {
		if (lua_pcall(st, 0, 0, 0) != 0) {
			cout << "pid " << pid << " init(): " << lua_tostring(st, -1) << endl;
			KernelSingleton->exit(pid);
		}
	}
	else {
		cout << "pid " << pid << " init() is not defined. exiting." << endl;
		KernelSingleton->exit(pid);
	}
}

void Process::update() {
	lua_getglobal(st, "update");
	if (lua_isfunction(st, -1)) {
		if (lua_pcall(st, 0, 0, 0) != 0) {
			cout << "pid " << pid << " update(): " << lua_tostring(st, -1) << endl;
			KernelSingleton->exit(pid);
		}
	}
	else {
		cout << "pid " << pid << " update() is not defined. exiting." << endl;
		KernelSingleton->exit(pid);
	}
}

void Process::draw() {
	lua_getglobal(st, "draw");
	if (lua_isfunction(st, -1)) {
		if (lua_pcall(st, 0, 0, 0) != 0) {
			cout << "pid " << pid << " draw(): " << lua_tostring(st, -1) << endl;
			KernelSingleton->exit(pid);
		}
	}
	else {
		cout << "pid " << pid << " draw() is not defined. exiting." << endl;
		KernelSingleton->exit(pid);
	}
}

const uint64_t Process::getPid() {
	return pid;
}

Memory* Process::getMemory() {
	mapped = true;
	return cartridgeMemory;
}

void Process::unmap() {
	mapped = false;
}

bool Process::isMapped() {
	return mapped;
}

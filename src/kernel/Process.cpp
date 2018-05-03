#include <kernel/Process.hpp>
#include <kernel/Kernel.hpp>
#include <kernel/filesystem.hpp>
#include <LuaBridge/LuaBridge.h>
#include <iostream>

using namespace luabridge;

const string Process::LuaEntryPoint = "main.lua";
const string Process::AssetsEntryPoint = "assets";
const string Process::NiblibEntryPoint = "niblib/main.lua";

Process::Process(Path& executable,
                 map<string, string> environment,
                 const uint64_t pid,
                 const uint64_t cartStart,
                 VideoMemory *video):
    environment(environment),
    pid(pid),
    mapped(false),
    initialized(false),
    ok(true),
    executable(executable) {
    // Pontos de entrada no sistema de arquivos para código
    // e dados do cart
    Path lua = executable.resolve(LuaEntryPoint);
    Path assets = executable.resolve(AssetsEntryPoint);
    Path niblib = Path(NiblibEntryPoint);
	
    // Carrega os assets para o cartridge (que será copiado para RAM
    // na localização cartStart)
    cartridgeMemory = new CartridgeMemory(assets, cartStart, video);

    st = luaL_newstate();

    // Carrega libs padrão lua
    luaL_openlibs(st);

    // Carrega a niblib
    if (luaL_loadfile(st, (const char*)niblib.getPath().c_str())) {
        cout << "error loading niblib " << lua_tostring(st, -1) << endl;
        ok = false;
    }
    else if (lua_pcall(st, 0, LUA_MULTRET, 0)) {
        cout << "error loading niblib " << lua_tostring(st, -1) << endl;
        ok = false;
    }

    cout << "pid " << pid << " loading cart " << lua.getPath() << endl;

    // Carrega o código do cart
    if (luaL_loadfile(st, (const char*)lua.getPath().c_str())) {
        cout << "syntax error on cartridge " << lua_tostring(st, -1) << endl;
        ok = false;
    }
    else if (lua_pcall(st, 0, LUA_MULTRET, 0)) {
        cout << "runtime error on cartridge " << lua_tostring(st, -1) << endl;
        ok = false;
    }

    this->environment["pid"] = to_string(pid);
}

Process::~Process() {
    lua_close(st);
}

bool Process::isOk() {
    return ok;
}

void Process::addSyscalls() {
    getGlobalNamespace(st)
        .beginNamespace("kernel")
        .addFunction("read", &kernel_api_read)
        .addFunction("write", &kernel_api_write)
        .addFunction("exec", &kernel_api_exec)
        .addFunction("yield", &kernel_api_yield)
        .addFunction("exit", &kernel_api_exit)
        .addFunction("setenv", &kernel_api_setenv)
        .addFunction("getenv", &kernel_api_getenv)
        .endNamespace();
}

void Process::init() {
    if (!initialized) {
        initialized = true;

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

void Process::audio_tick(uint8_t channel) {
    lua_getglobal(st, "audio_tick");
    lua_pushnumber(st, channel);
    if (lua_isfunction(st, -2)) {
        if (lua_pcall(st, 1, 0, 0) != 0) {
            cout << "pid " << pid << " audio_tick(): " << lua_tostring(st, -1) << endl;
            KernelSingleton->exit(pid);
        }
    }
    else {
        cout << "pid " << pid << " audio_tick() is not defined. exiting." << endl;
        KernelSingleton->exit(pid);
    }
}

const uint64_t Process::getPid() {
    return pid;
}

Memory* Process::getMemory() {
    if (!mapped) {
        mapped = true;
        cartridgeMemory->load();
    }

    return cartridgeMemory;
}

void Process::unmap() {
    if (mapped) {
        mapped = false;
    }
}

bool Process::isMapped() {
    return mapped;
}

void Process::setEnvVar(const string& key, const string& value) {
    environment[key] = value;
}

string Process::getEnvVar(const string& key) {
    return environment[key];
}

map<string, string> Process::getEnv() {
    return environment;
}

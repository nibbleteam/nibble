#include <kernel/Types.hpp>
#include <kernel/Process.hpp>
#include <kernel/Kernel.hpp>
#include <kernel/filesystem.hpp>

#include <kernel/mmap/Image.hpp>

#include <LuaBridge/LuaBridge.h>
#include <iostream>

using namespace luabridge;

const string Process::LuaEntryPoint = "main.lua";
const string Process::AssetsEntryPoint = "assets";
const string Process::NiblibEntryPoint = "frameworks/niblib/main.lua";

Process::Process(Memory &memory,
                 Path &executable,
                 map<string, string> environment,
                 const PID pid, const PID parent):
    environment(environment),
    pid(pid),
    parent(parent),
    initialized(false),
    ok(true),
    running(true),
    error(""),
    memory(memory),
    layout(*((MemoryLayout*)memory.allocate(PROCESS_INFO_LENGTH, "Process Information"))),
    executable(executable) {
    // Pontos de entrada no sistema de arquivos para código
    // e dados do app
    Path lua = executable.resolve(LuaEntryPoint);
    Path assets = executable.resolve(AssetsEntryPoint);
    Path niblib = Path(NiblibEntryPoint);
	
    layout.spritesheet = kernel_api_memmap(assets.resolve("/sheet.png").getPath());

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

    cout << "pid " << pid << " loading app " << lua.getPath() << endl;

    // Adiciona pasta do executável & frameworks
    // ao search path 
    string loadPath = "package.path = package.path .. ';./"+executable.getOriginalPath()+"/?.lua;./frameworks/?/main.lua;./frameworks/?.lua'";
    if (luaL_dostring(st, loadPath.c_str())) {
        error = string(lua_tostring(st, -1));

        cout << "error when setting search path " << error << endl;
        ok = false;
    }

    // Carrega o código do app
    if (luaL_loadfile(st, (const char*)lua.getPath().c_str())) {
        error = string(lua_tostring(st, -1));

        cout << "syntax error on cartridge " << error << endl;
        ok = false;
    }
    else if (lua_pcall(st, 0, LUA_MULTRET, 0)) {
        error = string(lua_tostring(st, -1));

        cout << "runtime error on cartridge " << error << endl;
        ok = false;
    }

    this->environment["pid"] = to_string(pid);
    this->environment["parent.pid"] = to_string(parent);
    this->environment["name"] = executable.getName();
    this->environment["addr"] = to_string(((uint8_t*)&layout)-memory.raw);
}

Process::~Process() {
    lua_close(st);

    memory.deallocate(layout.spritesheet);
    memory.deallocate((uint8_t*)&layout);
}

void Process::addSyscalls() {
    getGlobalNamespace(st)
        .beginNamespace("kernel")
        .addFunction("read", &kernel_api_read)
        .addFunction("write", &kernel_api_write)
        .addCFunction("exec", &kernel_api_exec)
        .addFunction("wait", &kernel_api_wait)
        .addFunction("kill", &kernel_api_kill)
        .addFunction("setenv", &kernel_api_setenv)
        .addFunction("getenv", &kernel_api_getenv)
        .addFunction("send", &kernel_api_send)
        .addFunction("receive", &kernel_api_receive)
        .addFunction("memmap", &kernel_api_memmap)
        .addFunction("memsync", &kernel_api_memsync)
        .addFunction("memresize", &kernel_api_memresize)
        .addFunction("list", &kernel_api_list)
        .endNamespace();
}

void Process::init() {
    if (!initialized) {
        lua_getglobal(st, "init");
        if (lua_isfunction(st, -1)) {
            if (lua_pcall(st, 0, 0, 0) != 0) {
                cout << "pid " << pid << " init(): " << lua_tostring(st, -1) << endl;
                KernelSingleton.lock()->kill(pid);
            }
        }

        initialized = true;
    }
}

void Process::update(float dt) {
    lua_getglobal(st, "update");
    if (lua_isfunction(st, -1)) {
        lua_pushnumber(st, dt);
        if (lua_pcall(st, 1, 0, 0) != 0) {
            cout << "pid " << pid << " update(): " << lua_tostring(st, -1) << endl;
            KernelSingleton.lock()->kill(pid);
        }
    }
}

void Process::draw() {
    lua_getglobal(st, "draw");
    if (lua_isfunction(st, -1)) {
        if (lua_pcall(st, 0, 0, 0) != 0) {
            cout << "pid " << pid << " draw(): " << lua_tostring(st, -1) << endl;
            KernelSingleton.lock()->kill(pid);
        }
    }
}

void Process::audio_tick() {
    lua_getglobal(st, "audio_tick");
    if (lua_isfunction(st, -1)) {
        if (lua_pcall(st, 0, 0, 0) != 0) {
            cout << "pid " << pid << " audio_tick(): " << lua_tostring(st, -1) << endl;
            KernelSingleton.lock()->kill(pid);
        }
    }
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

luabridge::LuaRef Process::readMessage() {
    if (!receivedMessages.empty()) {
        luabridge::LuaRef message = receivedMessages.front();
        receivedMessages.pop();
        return message;
    } else {
        return luabridge::LuaRef(st);
    }
}

void Process::clearMessages() {
    while (!receivedMessages.empty()) {
        receivedMessages.pop();
    }
}

void Process::writeMessage(luabridge::LuaRef msg) {
    // Mensagens são tabelas apenas
    if (msg.isTable()) {
        lua_State *msgState = msg.state();

        // Coloca a tabela na stack externa
        push(msgState, msg);
        lua_pushnil(msgState);

        // Coloca a nova tabela na nossa stack
        lua_newtable(st);

        // Itera pela tabela na stack externa
        if (lua_checkstack(msgState, 8) != 0) {
            while (lua_next(msgState, -2) != 0) {
                // Copia a chave para a nossa stack
                copyLuaValue(msgState, st, -2);
                // Copia o valor para o nosso stack 
                copyLuaValue(msgState, st, -1);
                // Coloca  chave e valor na tabela criada na nossa stack
                lua_settable(st, -3);
                // Remove o valor da stack externa
                lua_pop(msgState, 1);
            }
        } else {
            cout << "NO MORE SPACE ON THE EXTERN STACK" << endl;
            // Remove a chave "nil"
            lua_pop(msgState, 1);
        }
        // Remove a tabela da stack externa
        lua_pop(msgState, 1);

        // Cria uma referência para a nossa tabela
        LuaRef table = Stack<LuaRef>::get(st, -1);
        // Remove a nossa tabela da stack
        lua_pop(st, 1);

        // Coloca  tabela convertida na nossa lista de mensagens
        receivedMessages.push(table);
    }
}

// Copia um valor de from para to, que está na posição p de from
void Process::copyLuaValue(lua_State* from, lua_State* to, int p) {
    // Verifica o tipo do valor na stack
    int t = lua_type(from, p);

    switch (t) {
        // Para tipos simples, copia diretamente
        case LUA_TSTRING: {
            string value = string(lua_tostring(from, p));

            lua_pushstring(to, value.c_str());
        }
            break;
        case LUA_TBOOLEAN:
            lua_pushboolean(to, lua_toboolean(from, p));
            break;
        case LUA_TNUMBER:
            lua_pushnumber(to, lua_tonumber(from, p));
            break;
        // Para tabelas, chama a função recursivamente
        case LUA_TTABLE:
            // TODO: Tabelas como chaves/valores
            break;
    }
}

bool Process::operator < (const Process& p) {
    return pid < p.pid;
}

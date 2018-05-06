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
    running(true),
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

bool Process::isInitialized() {
    return initialized;
}

void Process::addSyscalls() {
    getGlobalNamespace(st)
        .beginNamespace("kernel")
        .addFunction("read", &kernel_api_read)
        .addFunction("write", &kernel_api_write)
        .addFunction("exec", &kernel_api_exec)
        .addFunction("wait", &kernel_api_wait)
        .addFunction("kill", &kernel_api_kill)
        .addFunction("setenv", &kernel_api_setenv)
        .addFunction("getenv", &kernel_api_getenv)
        .addFunction("send", &kernel_api_send)
        .addFunction("receive", &kernel_api_receive)
        .endNamespace();
}

void Process::init() {
    if (!initialized) {
        initialized = true;

        lua_getglobal(st, "init");
        if (lua_isfunction(st, -1)) {
            if (lua_pcall(st, 0, 0, 0) != 0) {
                cout << "pid " << pid << " init(): " << lua_tostring(st, -1) << endl;
                KernelSingleton->kill(pid);
            }
        }
        else {
            cout << "pid " << pid << " init() is not defined. exiting." << endl;
            KernelSingleton->kill(pid);
        }
    }
}

void Process::update(float dt) {
    lua_getglobal(st, "update");
    lua_pushnumber(st, dt);
    if (lua_isfunction(st, -2)) {
        if (lua_pcall(st, 1, 0, 0) != 0) {
            cout << "pid " << pid << " update(): " << lua_tostring(st, -1) << endl;
            KernelSingleton->kill(pid);
        }
    }
    else {
        cout << "pid " << pid << " update() is not defined. exiting." << endl;
        KernelSingleton->kill(pid);
    }
}

void Process::draw() {
    lua_getglobal(st, "draw");
    if (lua_isfunction(st, -1)) {
        if (lua_pcall(st, 0, 0, 0) != 0) {
            cout << "pid " << pid << " draw(): " << lua_tostring(st, -1) << endl;
            KernelSingleton->kill(pid);
        }
    }
    else {
        cout << "pid " << pid << " draw() is not defined. exiting." << endl;
        KernelSingleton->kill(pid);
    }
}

void Process::audio_tick(uint8_t channel) {
    lua_getglobal(st, "audio_tick");
    lua_pushnumber(st, channel);
    if (lua_isfunction(st, -2)) {
        if (lua_pcall(st, 1, 0, 0) != 0) {
            cout << "pid " << pid << " audio_tick(): " << lua_tostring(st, -1) << endl;
            KernelSingleton->kill(pid);
        }
    }
    else {
        cout << "pid " << pid << " audio_tick() is not defined. exiting." << endl;
        KernelSingleton->kill(pid);
    }
}

const uint64_t Process::getPid() const {
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

bool Process::isRunning() {
    return running; 
}

void Process::setRunning(bool running) {
    this->running = running;
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
    return pid < p.getPid();
}

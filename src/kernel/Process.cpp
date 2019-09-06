#include <kernel/Types.hpp>
#include <kernel/Process.hpp>
#include <kernel/Kernel.hpp>
#include <kernel/filesystem.hpp>

#include <kernel/mmap/Image.hpp>

#include <iostream>

const string Process::lua_entry_point = "main.lua";

Process::Process(Memory &memory, Path &executable):
    initialized(false), ok(true), running(true), error(""),
    memory(memory), executable(executable) {
    // TODO: ideia: system rom com spritesheets acessíveis de todos os processos
    // TODO: alocar memória para assets de cada processo
    //memory.allocate(PROCESS_INFO_LENGTH, "Process Information");
    //layout.spritesheet = kernel_api_memmap(assets.resolve("/sheet.png").getPath());

    // Pontos de entrada no sistema de arquivos para código
    // e dados do app
    Path lua = executable.resolve(lua_entry_point);
	
    st = luaL_newstate();

    // Carrega libs padrão lua
    luaL_openlibs(st);

    cout << "Loading lua entrypoint " << lua.get_path() << " ..." << endl;

    // Carrega o código do app
    if (luaL_loadfile(st, (const char*)lua.get_path().c_str())) {
        error = string(lua_tostring(st, -1));

        cout << "\t" << error << endl;
        ok = false;
    }
    else if (lua_pcall(st, 0, LUA_MULTRET, 0)) {
        error = string(lua_tostring(st, -1));

        cout << "\t" << error << endl;
        ok = false;
    }

    // TODO: lua-side
    //this->environment["pid"] = to_string(pid);
    //this->environment["parent.pid"] = to_string(parent);
    //this->environment["name"] = executable.getName();
    //this->environment["addr"] = to_string(((uint8_t*)&layout)-memory.raw);
}

Process::~Process() {
    lua_close(st);

    // TODO
    //memory.deallocate(layout.spritesheet);
    //memory.deallocate((uint8_t*)&layout);
}

void Process::init() {
    if (!initialized && ok) {
        lua_getglobal(st, "init");
        if (lua_isfunction(st, -1)) {
            if (call_with_traceback(st, 0, 0) != 0) {
                cout << "system error: init(): " << lua_tostring(st, -1) << endl;
                ok = false;
            }
        }

        initialized = true;
    }
}

void Process::update(float dt) {
    if (!ok) {
        return;
    }

    lua_getglobal(st, "update");
    if (lua_isfunction(st, -1)) {
        lua_pushnumber(st, dt);
        if (call_with_traceback(st, 1, 0) != 0) {
            cout << "system error: update(): " << lua_tostring(st, -1) << endl;
            ok = false;
        }
    }
}

void Process::menu() {
    if (!ok) {
        return;
    }

    lua_getglobal(st, "menu");
    if (lua_isfunction(st, -1)) {
        if (call_with_traceback(st, 0, 0) != 0) {
            cout << "system error: menu(): " << lua_tostring(st, -1) << endl;
            ok = false;
        }
    }
}

void Process::audio_tick() {
    if (!ok) {
        return;
    }

    lua_getglobal(st, "audio_tick");
    if (lua_isfunction(st, -1)) {
        if (call_with_traceback(st, 0, 0) != 0) {
            cout << "system error: audio_tick(): " << lua_tostring(st, -1) << endl;
            ok = false;
        }
    }
}

int Process::call_with_traceback(lua_State* l, int args, int rets) {
  int handler_position = lua_gettop(l)-args;
  int status;

  lua_pushcfunction(l, [](lua_State* l) -> int {
    luaL_traceback(l, l, lua_tostring(l, -1), 1);

    return 1;
  });

  lua_insert(l, handler_position);

  status = lua_pcall(l, args, rets, handler_position);

  lua_remove(l, handler_position);

  return status;
}

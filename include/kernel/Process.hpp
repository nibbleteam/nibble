#ifndef PROCESS_H
#define PROCESS_H

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

#include <cstdint>

class Process {
    lua_State *st;
};

#endif /* PROCESS_H */

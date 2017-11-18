#include <SFML/Graphics.hpp>

extern "C" {
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
}

void test_lua() {
    lua_State *st = luaL_newstate();

    lua_close(st);
}

int main() {
    sf::RenderWindow window(sf::VideoMode(320, 240), "PongBoy");

    while (window.isOpen()) {
        sf::Event event;

        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed) {
                window.close();
            }
        }

        window.display();
    }

    return 0;
}

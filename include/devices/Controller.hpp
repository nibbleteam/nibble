#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <map>
#include <cstdint>

#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

#include <Specs.hpp>

#include <SDL.h>

using namespace std;

// Estados possíveis de um botão
#define BUTTON_OFF 0
#define BUTTON_OFF_ON 1
#define BUTTON_ON 2
#define BUTTON_ON_OFF 3
// Mapeamento padrão do controle
#define J_UP 9
#define J_RIGHT 12
#define J_DOWN 10
#define J_LEFT 11
#define J_RED 1 // 0
#define J_BLUE 3
#define J_BLACK_ALT 4
#define J_WHITE_ALT 5
#define J_BLACK 6
#define J_WHITE 7
#define J_PAUSE 8

class Controller: public Device {
#pragma pack(push, 1)
    struct ControllerMemory {
        unsigned int left :2;
        unsigned int down :2;
        unsigned int right :2;
        unsigned int up :2;

        unsigned int black :2;
        unsigned int white :2;

        unsigned int red :2;
        unsigned int blue :2;
    };
#pragma pack(pop)

#pragma pack(push, 1)
	struct PauseButton {
        unsigned int a :2;
        unsigned int b :2;
        unsigned int c :2;
        unsigned int d :2;
    };
#pragma pack(pop)

#pragma pack(push, 1)
	struct ControllersMemory {
        // Cada dois bits indicam um dos quatro estados dos
        // joysticks
        uint8_t connected;

        ControllerMemory controllers[CONTROLLER_AMOUNT];

        PauseButton pauses;
    };
#pragma pack(pop)
    ControllersMemory &controllers;
    map<unsigned int, unsigned int> sdl2nibble;
public:
    Controller(Memory&);

    void update();
    void kbd_pressed(SDL_Event&);
    void kbd_released(SDL_Event&);
    void joy_pressed(SDL_Event&);
    void joy_released(SDL_Event&);
    void joy_connected(SDL_Event&);
    void joy_disconnected(SDL_Event&);
    void joy_moved(SDL_Event&);
    void all_released();
private:
    unsigned int get_open_slot();

    void press(const uint8_t, const uint8_t);
    void release(const uint8_t, const uint8_t);

    uint8_t get(const uint8_t, const uint8_t);
    void set(const uint8_t, const uint8_t, const uint8_t);

    void set_state(const unsigned int, const unsigned int);
    unsigned int get_state(const unsigned int);
};

#endif /* CONTROLLER_H */

#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <map>
#include <cstdint>

#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

#include <Specs.hpp>

#include <SDL2/SDL.h>

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
#define J_RED 0
#define J_BLUE 3
#define J_BLACK 6
#define J_WHITE 7
#define J_PAUSE 8

class Controller : public Device {
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
    // Mapeia os números os controles SFML para os
    // controles do nibble
    map<unsigned int, unsigned int> sfml2nibble;
public:
    Controller(Memory&);

    void update();
    void kbdPressed(SDL_Event&);
    void kbdReleased(SDL_Event&);
    void joyPressed(SDL_Event&);
    void joyReleased(SDL_Event&);
    void joyConnected(SDL_Event&);
    void joyDisconnected(SDL_Event&);
    void joyMoved(SDL_Event&);
    void allReleased();
private:
    unsigned int getOpenSlot();
    void press(const uint8_t, const uint8_t);
    void release(const uint8_t, const uint8_t);
    uint8_t get(const uint8_t, const uint8_t);
    void set(const uint8_t, const uint8_t, const uint8_t);
    void setState(const unsigned int, const unsigned int);
    unsigned int getState(const unsigned int);
};

#endif /* CONTROLLER_H */

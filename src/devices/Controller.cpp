#include <iostream>
#include <cstring>

#include <devices/Controller.hpp>

Controller::Controller(Memory& memory):
                       controllers(*((ControllersMemory*)memory.allocate(CONTROLLER_MEM_SIZE, "Controllers"))) {
    // Zera todos os botões
    memset(&controllers, 0, CONTROLLER_MEM_SIZE);
    // O primeiro controle está sempre conectado 
    controllers.connected = 0b00000000;
}

uint8_t Controller::get(uint8_t c, uint8_t b) {
    uint8_t state = 0;

    switch (b) {
    case 0:
        state = controllers.controllers[c].up;
        break;
    case 1:
        state = controllers.controllers[c].right;
        break;
    case 2:
        state = controllers.controllers[c].down;
        break;
    case 3:
        state = controllers.controllers[c].left;
        break;
    case 4:
        state = controllers.controllers[c].red;
        break;
    case 5:
        state = controllers.controllers[c].blue;
        break;
    case 6:
        state = controllers.controllers[c].black;
        break;
    case 7:
        state = controllers.controllers[c].white;
        break;
    case 8:
        if (c == 0)
            state = controllers.pauses.a;
        else if (c == 1)
            state = controllers.pauses.b;
        else if (c == 2)
            state = controllers.pauses.c;
        else if (c == 3)
            state = controllers.pauses.d;
        break;
    }

    return state;
}

void Controller::set(uint8_t c, uint8_t b, uint8_t value) {
    switch (b) {
    case 0:
        controllers.controllers[c].up = value;
        break;
    case 1:
        controllers.controllers[c].right = value;
        break;
    case 2:
        controllers.controllers[c].down = value;
        break;
    case 3:
        controllers.controllers[c].left = value;
        break;
    case 4:
        controllers.controllers[c].red = value;
        break;
    case 5:
        controllers.controllers[c].blue = value;
        break;
    case 6:
        controllers.controllers[c].black = value;
        break;
    case 7:
        controllers.controllers[c].white = value;
        break;
    case 8:
        if (c == 0)
            controllers.pauses.a = value;
        else if (c == 1)
            controllers.pauses.b = value;
        else if (c == 2)
            controllers.pauses.c = value;
        else if (c == 3)
            controllers.pauses.d = value;
        break;
    default:
        break;
    }
}

void Controller::press(uint8_t c, uint8_t b) {
    int state = get(c, b);

    if (state == BUTTON_OFF || state == BUTTON_ON_OFF) {
        set(c, b, BUTTON_OFF_ON);
    }
}

void Controller::release(uint8_t c, uint8_t b) {
    int state = get(c, b);

    if (state == BUTTON_ON || state == BUTTON_OFF_ON) {
        set(c, b, BUTTON_ON_OFF);
    }
}

void Controller::kbd_pressed(SDL_Event& event) {
    switch (event.key.keysym.sym) {
    case SDLK_UP:
        press(0, 0);
        break;
    case SDLK_RIGHT:
        press(0, 1);
        break;
    case SDLK_DOWN:
        press(0, 2);
        break;
    case SDLK_LEFT:
        press(0, 3);
        break;
    case SDLK_x:
        press(0, 4);
        break;
    case SDLK_c:
        press(0, 5);
        break;
    case SDLK_s:
        press(0, 6);
        break;
    case SDLK_d:
        press(0, 7);
        break;
    case SDLK_p:
        press(0, 8);
        break;
    default:
        break;
    }
}

void Controller::kbd_released(SDL_Event& event) {
    switch (event.key.keysym.sym) {
    case SDLK_UP:
        release(0, 0);
        break;
    case SDLK_RIGHT:
        release(0, 1);
        break;
    case SDLK_DOWN:
        release(0, 2);
        break;
    case SDLK_LEFT:
        release(0, 3);
        break;
    case SDLK_x:
        release(0, 4);
        break;
    case SDLK_c:
        release(0, 5);
        break;
    case SDLK_s:
        release(0, 6);
        break;
    case SDLK_d:
        release(0, 7);
        break;
    case SDLK_p:
        release(0, 8);
        break;
    default:
        break;
    }
}

void Controller::joy_moved(SDL_Event& event) {
    unsigned int c = sdl2nibble[event.jaxis.which];

    if (event.jaxis.axis == 0) {
        if (abs(event.jaxis.value) < 10) {
            release(c, 1);
            release(c, 3);
        } else if (event.jaxis.value> 0) {
            press(c, 1);
        } else {
            press(c, 3);
        }
    }

    if (event.jaxis.axis == 1) {
        if (abs(event.jaxis.value) < 10) {
            release(c, 0);
            release(c, 2);
        } else if (event.jaxis.value > 0) {
            press(c, 2);
        } else {
            press(c, 0);
        }
    }
}

void Controller::joy_pressed(SDL_Event& event) {
    unsigned int c = sdl2nibble[event.jbutton.which];

    switch (event.jbutton.button) {
    case J_BLUE:
        press(c, 4);
        break;
    case J_RED:
        press(c, 5);
        break;
    case J_BLACK: case J_BLACK_ALT:
        press(c, 6);
        break;
    case J_WHITE: case J_WHITE_ALT:
        press(c, 7);
        break;
    case J_PAUSE:
        press(c, 8);
        break;
    default:
        break;
    }
}

void Controller::joy_released(SDL_Event& event) {
    unsigned int c = sdl2nibble[event.jbutton.which];

    switch (event.jbutton.button) {
    case J_BLUE:
        release(c, 4);
        break;
    case J_RED:
        release(c, 5);
        break;
    case J_BLACK:
        release(c, 6);
        break;
    case J_WHITE:
        release(c, 7);
        break;
    case J_PAUSE:
        release(c, 8);
        break;
    default:
        break;
    }
}

void Controller::joy_connected(SDL_Event& event) {
    cout << "[nibble] " << "joystick connected" << endl;

    unsigned int slot = get_open_slot();

    sdl2nibble[event.jdevice.which] = slot;

    SDL_JoystickOpen(event.jdevice.which);

    set_state(slot, BUTTON_OFF_ON);
}

void Controller::joy_disconnected(SDL_Event& event) {
    unsigned int slot = sdl2nibble[event.jdevice.which];
    sdl2nibble.erase(event.jdevice.which);

    set_state(slot, BUTTON_ON_OFF);
}

unsigned int Controller::get_state(const unsigned int c) {
    return (controllers.connected>>((CONTROLLER_AMOUNT-c)*2-2))&3;
}

void Controller::set_state(const unsigned int c, const unsigned int value) {
    controllers.connected |= value << ((CONTROLLER_AMOUNT-c)*2-2);
}

unsigned int Controller::get_open_slot() {
    for (unsigned int i=0;i<CONTROLLER_AMOUNT;i++) {
        unsigned int connected = (controllers.connected>>((CONTROLLER_AMOUNT-i)*2-2))&3;
        if (connected == BUTTON_OFF ||
            connected == BUTTON_ON_OFF) {
            return i;
        }
    }

    return 0;
}

void Controller::all_released() {
    for (unsigned int c=0;c<CONTROLLER_AMOUNT;c++) {
        for (unsigned int b=0; b<8; b++) {
            release(c, b);
        }
    }
}

void Controller::update() {
    for (unsigned int c=0;c<CONTROLLER_AMOUNT;c++) {
        int controller_state = get_state(c);

        if (controller_state == BUTTON_ON_OFF)
            set_state(c, BUTTON_OFF);
        else if (controller_state == BUTTON_OFF_ON)
            set_state(c, BUTTON_ON);

        for (unsigned int b=0; b<8; b++) {
            int state = get(c, b);

            if (state == BUTTON_ON_OFF)
                set(c, b, BUTTON_OFF);
            else
            if (state == BUTTON_OFF_ON)
                set(c, b, BUTTON_ON);
        }
    }
}

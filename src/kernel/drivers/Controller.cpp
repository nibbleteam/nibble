#include <kernel/drivers/Controller.hpp>
#include <iostream>
#include <cstring>

Controller::Controller(const uint64_t addr) :
    address(addr), length(10) {
    // Zera todos os botões
    memset(&controllers, 0, 10);
    // O primeiro controle está sempre conectado 
    controllers.connected = 0b10000000;
}

Controller::~Controller() {
}

string Controller::name() {
	return "CONTROLLER";
}

// Apenas leitura
uint64_t Controller::write(const uint64_t pos, const uint8_t* data, const uint64_t amount) {
    return 0;
}

uint64_t Controller::read(const uint64_t pos, uint8_t* data, const uint64_t amount) {
    memcpy(data, (uint8_t*)(&controllers) + pos, (size_t)amount);

    return amount;
}

uint64_t Controller::size() {
    return length;
}

uint64_t Controller::addr() {
    return address;
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

void Controller::kbdPressed(sf::Event& event) {
    switch (event.key.code) {
    case sf::Keyboard::Up:
        press(0, 0);
        break;
    case sf::Keyboard::Right:
        press(0, 1);
        break;
    case sf::Keyboard::Down:
        press(0, 2);
        break;
    case sf::Keyboard::Left:
        press(0, 3);
        break;
    case sf::Keyboard::X:
        press(0, 4);
        break;
    case sf::Keyboard::C:
        press(0, 5);
        break;
    case sf::Keyboard::S:
        press(0, 6);
        break;
    case sf::Keyboard::D:
        press(0, 7);
        break;
    case sf::Keyboard::P:
        press(0, 8);
        break;
    default:
        break;
    }
}

void Controller::kbdReleased(sf::Event& event) {
    switch (event.key.code) {
    case sf::Keyboard::Up:
        release(0, 0);
        break;
    case sf::Keyboard::Right:
        release(0, 1);
        break;
    case sf::Keyboard::Down:
        release(0, 2);
        break;
    case sf::Keyboard::Left:
        release(0, 3);
        break;
    case sf::Keyboard::X:
        release(0, 4);
        break;
    case sf::Keyboard::C:
        release(0, 5);
        break;
    case sf::Keyboard::S:
        release(0, 6);
        break;
    case sf::Keyboard::D:
        release(0, 7);
        break;
    case sf::Keyboard::P:
        release(0, 8);
        break;
    default:
        break;
    }
}

void Controller::joyMoved(sf::Event& event) {
    unsigned int c = sfml2nibble[event.joystickMove.joystickId];

    if (event.joystickMove.axis == sf::Joystick::X ||
        event.joystickMove.axis == sf::Joystick::PovX) {
        if (abs(event.joystickMove.position) < 10) {
            release(c, 1);
            release(c, 3);
        } else if (event.joystickMove.position > 0) {
            press(c, 1);
        } else {
            press(c, 3);
        }
    }

    if (event.joystickMove.axis == sf::Joystick::Y ||
        event.joystickMove.axis == sf::Joystick::PovY) {
        if (abs(event.joystickMove.position) < 10) {
            release(c, 0);
            release(c, 2);
        } else if (event.joystickMove.position > 0) {
            press(c, 2);
        } else {
            press(c, 0);
        }
    }
}

void Controller::joyPressed(sf::Event& event) {
    unsigned int c = sfml2nibble[event.joystickButton.joystickId];

    switch (event.joystickButton.button) {
    case J_BLUE:
        press(c, 4);
        break;
    case J_RED:
        press(c, 5);
        break;
    case J_BLACK:
        press(c, 6);
        break;
    case J_WHITE:
        press(c, 7);
        break;
    case J_PAUSE:
        press(c, 8);
        break;
    default:
        break;
    }
}

void Controller::joyReleased(sf::Event& event) {
    unsigned int c = sfml2nibble[event.joystickButton.joystickId];

    switch (event.joystickButton.button) {
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

void Controller::joyConnected(sf::Event& event) {
    unsigned int slot = getOpenSlot();

    sfml2nibble[event.joystickConnect.joystickId] = slot;

    setState(slot, BUTTON_OFF_ON);
} 

void Controller::joyDisconnected(sf::Event& event) {
    unsigned int slot = sfml2nibble[event.joystickConnect.joystickId];
    sfml2nibble.erase(event.joystickConnect.joystickId);

    setState(slot, BUTTON_ON_OFF);
} 

unsigned int Controller::getState(const unsigned int c) {
    return (controllers.connected>>((CONTROLLER_NUM-c)*2-2))&3;
}

void Controller::setState(const unsigned int c, const unsigned int value) {
    controllers.connected |= value << ((CONTROLLER_NUM-c)*2-2);
}

unsigned int Controller::getOpenSlot() {
    for (unsigned int i=0;i<CONTROLLER_NUM;i++) {
        unsigned int connected = (controllers.connected>>((CONTROLLER_NUM-i)*2-2))&3;
        if (connected == BUTTON_OFF ||
            connected == BUTTON_ON_OFF) {
            return i;
        }
    }

    return 0;
}

void Controller::allReleased() {
    for (unsigned int c=0;c<CONTROLLER_NUM;c++) {
        for (unsigned int b=0; b<8; b++) {
            release(c, b);
        }
    }
}

void Controller::update() {
    for (unsigned int c=0;c<CONTROLLER_NUM;c++) {
        int controllerState = getState(c);

        if (controllerState == BUTTON_ON_OFF)
            setState(c, BUTTON_OFF);
        else if (controllerState == BUTTON_OFF_ON)
            setState(c, BUTTON_ON);

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

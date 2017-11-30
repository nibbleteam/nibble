#include <kernel/drivers/Controller.hpp>
#include <iostream>
#include <cstring>

Controller::Controller(const uint64_t addr) :
    address(addr), length(sizeof(controllers)) {
    // Zera todos os botões
    memset(&controllers, 0, sizeof(controllers));
    // O primeiro controle está sempre conectado 
    controllers.connected = 0b10000000;
}

Controller::~Controller() {
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
    uint8_t state;

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

void Controller::joyPressed(sf::Event&) {

}

void Controller::joyReleased(sf::Event&) {
}

void Controller::joyConnected(sf::Event&) {
} 

void Controller::joyDisconnected(sf::Event&) {
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

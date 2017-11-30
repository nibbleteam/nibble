#ifndef CONTROLLER_H
#define CONTROLLER_H

#include <cstdint>
#include <SFML/Window.hpp>
#include <kernel/Memory.hpp>

using namespace std;

#define CONTROLLER_NUM 4
// Estados possíveis de um botão
#define BUTTON_OFF 0
#define BUTTON_OFF_ON 1
#define BUTTON_ON 2
#define BUTTON_ON_OFF 3

class Controller : public Memory {
#pragma pack(push, 1)
    struct ControllerMemory {
        unsigned int left :2;
        unsigned int down :2;
        unsigned int right :2;
        unsigned int up :2;

        unsigned int black :2;
        unsigned int white :2;

        unsigned int blue :2;
        unsigned int red :2;
    };

    struct PauseButton {
        unsigned int a :2;
        unsigned int b :2;
        unsigned int c :2;
        unsigned int d :2;
    };

    struct ControllersMemory {
        // Cada dois bits indicam um dos quatro estados dos
        // joysticks
        uint8_t connected;

        ControllerMemory controllers[CONTROLLER_NUM];

        PauseButton pauses;
    };
#pragma pack(pop)
    ControllersMemory controllers;
    const uint64_t address;
    const uint64_t length;
public:
    Controller(const uint64_t);
    ~Controller();

    void update();
    void kbdPressed(sf::Event&);
    void kbdReleased(sf::Event&);
    void joyPressed(sf::Event&);
    void joyReleased(sf::Event&);
    void joyConnected(sf::Event&);
    void joyDisconnected(sf::Event&);
    void allReleased();

    uint64_t write(const uint64_t, const uint8_t*, const uint64_t);
    uint64_t read(const uint64_t, uint8_t*, const uint64_t);

    uint64_t size();
    uint64_t addr();
private:
    void press(const uint8_t, const uint8_t);
    void release(const uint8_t, const uint8_t);
    uint8_t get(const uint8_t, const uint8_t);
    void set(const uint8_t, const uint8_t, const uint8_t);
};

#endif /* CONTROLLER_H */

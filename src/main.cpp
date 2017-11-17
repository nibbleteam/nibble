#include <SFML/Graphics.hpp>

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

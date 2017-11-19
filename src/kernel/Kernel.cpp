#include <kernel/Kernel.hpp>

Kernel::Kernel():
	window(sf::VideoMode(320, 240), "PongBoy") {

	createMemoryMap();

	exec("apps/shell", vector<string>());
}

Kernel::~Kernel() {
	destroyMemoryMap();
}

void Kernel::createMemoryMap() {

}

void Kernel::destroyMemoryMap() {
	for (auto memory: ram) {
		delete memory;
	}
}

void Kernel::loop() {
	while (window.isOpen()) {
		sf::Event event;

		while (window.pollEvent(event)) {
			if (event.type == sf::Event::Closed) {
				window.close();
			}
		}

		// Escolhe processo
		// Atualiza processo (chama update)
		// Desenha processo (chama draw)

		window.display();
	}
}

// API de gerenciamento de processos

// Executa "executable" passando "environment"
uint64_t Kernel::exec(const string& executable, vector<string> environment) {
	return 0;
}

// Libera o fluxo de controle para "to"
bool Kernel::yield(const uint64_t to) {
	return false;
}

void Kernel::exit() {

}


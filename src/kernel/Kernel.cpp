#include <Icon.hpp>
#include <SFML/OpenGL.hpp>
#include <kernel/Kernel.hpp>
#include <kernel/drivers/RAM.hpp>
#include <kernel/drivers/Audio.hpp>
#include <kernel/drivers/VideoMemory.hpp>
#include <kernel/drivers/RandomMemory.hpp>
#include <algorithm>
#include <iostream>

using namespace std;

Kernel::Kernel():
    window(sf::VideoMode(640, 480), "Nibble"),
    lastPid(1),
    lastUsedMemByte(0) {
    // FPS Máximo 
    window.setFramerateLimit(30);
    // O tamanho virtual da janela é sempre 320x240
    window.setView(sf::View(sf::FloatRect(0, 0, 320, 240)));
    // Não gera múltiplos keypresses se a tecla ficar apertada
    window.setKeyRepeatEnabled(false);
    // Não mostra o cursor
    window.setMouseCursorVisible(false);
    // Coloca o ícone
    sf::Image Icon;
	if (Icon.loadFromMemory(icon_png, icon_png_len))
        window.setIcon(320, 320, Icon.getPixelsPtr());

	lastUsedMemByte = 0;
	createMemoryMap();
}

void Kernel::menu() {
    // Não abre menu no menu
    if (processes.back() &&
        processes.back()->executable.getOriginalPath() != "apps/menu") {
        auto environment = processes.back()->getEnv();
        environment["app.pid"] = environment["pid"];

        auto pid = exec("apps/menu", environment);
        yield(pid);
    }
}

void Kernel::reset() {
	audio->stop();
    shutdown();
	startup();
}

void Kernel::shutdown() {
    for (auto process : processes) {
        delete process;
    }
    processes.clear();
}

void Kernel::startup() {
    lastPid = 1;

    audio->play();

    // TODO: Erro quando não conseguir lançar o processo,
    // talvez um pequeno processo codificado em C++ diretamente
    // apenas para mostrar mensagens de erro e coisas parecidas?
    // e.g.: um processo "system"
    if (exec("apps/shell", map<string, string>()) > 0) {
        cout << "[kernel] " << "process started" << endl;
    }
}

Kernel::~Kernel() {
    audio->stop();
	destroyMemoryMap();
	shutdown();
	delete gpu;
}

void Kernel::addMemoryDevice(Memory* device) {
    ram.push_back(device);

	cout << "[" << lastUsedMemByte << " - " << lastUsedMemByte+device->size() << "]: ";
	cout << device->name() << endl;

    lastUsedMemByte += device->size();
}

// Mapeia os dispositivos (placa de vídeo, placa de áudio, controles, leds etc)
// para a RAM
void Kernel::createMemoryMap() {
    // Vídeo
    gpu = new GPU(window, 320, 240, lastUsedMemByte);
    addMemoryDevice(gpu->getCommandMemory());
    addMemoryDevice(gpu->getPaletteMemory());
    addMemoryDevice(gpu->getVideoMemory());
    // Gerador de random
    addMemoryDevice(new RandomMemory(lastUsedMemByte));
    // Input (controle, teclado, mouse)
    controller = new Controller(lastUsedMemByte);
    addMemoryDevice((Memory*)controller);
    keyboard = new Keyboard(lastUsedMemByte);
    addMemoryDevice((Memory*)keyboard);
    mouse = new Mouse(lastUsedMemByte);
    addMemoryDevice((Memory*)mouse);
    // Audio
    audio = new Audio(lastUsedMemByte);
    addMemoryDevice(audio);
    // RAM
    addMemoryDevice(new RAM(lastUsedMemByte, 32*1024));
}

void Kernel::destroyMemoryMap() {
    // Deleta todos os dispositivos mapeados em memória
    // exceto aqueles que são processos, que são deletados
    // pelos respectivos processos
    for (auto memory: ram) {
        bool rm = true;

        if (memory == gpu->getCommandMemory() ||
			memory == gpu->getPaletteMemory() ||
			memory == gpu->getVideoMemory()) {
            rm = false;
        } else {
            for (auto process : processes) {
                if (process->getMemory() == memory) {
                    rm = false;
                }
            }
        }

        if (rm) delete memory;
    }

    ram.clear();
}

void Kernel::loop() {
    sf::Clock clock;
    float lastTime = 0;
    
    while (window.isOpen()) {
        float currentTime = clock.getElapsedTime().asSeconds();
        float fps = 1.f / (currentTime - lastTime);
        lastTime = currentTime;
        cerr << fps << "\r";

        sf::Event event;

        // Event handling
        controller->update();
        mouse->update();
        while (window.pollEvent(event)) {
            switch (event.type) {
                // Fecha a janela no "x" ou alt-f4 etc
            case sf::Event::Closed: {
                window.close();
            }
                break;
                // Redimensiona e centraliza o vídeo
            case sf::Event::Resized: {
                ((VideoMemory*)gpu->getVideoMemory())->resize();
            }
                break;
                // Teclado
            case sf::Event::TextEntered: {
                keyboard->input(event.text.unicode);
            }
                break;
                // Controle
            case sf::Event::LostFocus: {
                controller->allReleased();
                mouse->released(0);
                mouse->released(1);
            }
                break;
            case sf::Event::KeyPressed: {
                if (event.key.code == sf::Keyboard::R &&
                    event.key.control) {
					reset();
                } else if (event.key.code == sf::Keyboard::M &&
                    event.key.control) {
                    menu();
                } else {
                    controller->kbdPressed(event);
                }
            }
                break;
            case sf::Event::KeyReleased: {
                controller->kbdReleased(event);
            }
                break;
            case sf::Event::JoystickButtonPressed: {
                if (event.joystickButton.button == 9) {
                    menu();
                } else {
                    controller->joyPressed(event);
                }
            }
                break;
            case sf::Event::JoystickButtonReleased: {
                controller->joyReleased(event);
            }
                break;
            case sf::Event::JoystickMoved: {
                controller->joyMoved(event);
            }
                break;
            case sf::Event::JoystickConnected: {
                controller->joyConnected(event);
            }
                break;
            case sf::Event::JoystickDisconnected: {
                controller->joyDisconnected(event);
            }
                break;
            // Mouse
            case sf::Event::MouseButtonPressed: {
                mouse->pressed(event.mouseButton.button != sf::Mouse::Button::Left);
            }
                break;
            case sf::Event::MouseButtonReleased: {
                mouse->released(event.mouseButton.button != sf::Mouse::Button::Left);
            }
                break;
            case sf::Event::MouseLeft: {
                mouse->released(0);
                mouse->released(1);
            }
                break;
            case sf::Event::MouseMoved: {
                uint16_t x = event.mouseMove.x;
                uint16_t y = event.mouseMove.y;
                ((VideoMemory*)gpu->getVideoMemory())->transformMouse(x, y);
                mouse->moved(x, y);
            }
                break;
            default:
                break;
            }
        }

        // Roda o processo no topo da lista de processos
        if (processes.size() > 0) {
            Process *p = processes.back();

            // Traz o cart do processo pra RAM se já não estiver
            if (!p->isMapped()) {
                // Retira RAM do processo anterior
                for (auto q :processes) {
                    if (ram.back() == q->getMemory()) {
                        ram.pop_back();
                        q->unmap();
                        break;
                    }
                }
                ram.push_back(p->getMemory());

                audioMutex.lock();
                p->init();
                audioMutex.unlock();
            } else {
                // Chama as callbacks do processo
                audioMutex.lock();
                p->update();
                p->draw();
                audioMutex.unlock();
            }
        }

        gpu->draw();
        window.display();
    }
}

// Executa "executable" passando "environment"
// executable é um diretório que deve seguir a seguinte organização:
// <cart-name>/
//	- assets/
//  - main.lua
int64_t Kernel::exec(const string& executable, map<string, string> environment) {
    cout << "[kernel] exec " << executable << endl;

    Path executablePath(executable);

    // Verifica a existência e estrutura de do cart "executable"
    if (!checkCartStructure(executablePath)) {
        return 0;
    }

    // Cria o processo carregando o cart para a memória na
    // primeira localização livre
    auto process = new Process(executablePath, environment, lastPid++, lastUsedMemByte, (VideoMemory*)gpu->getVideoMemory());

    if (process->isOk()) {
        // Adiciona as chamadas de sistema providas pelo Kernel
        // ao ambiente lua do processo
        process->addSyscalls();

        // Adiciona ao início da pilha de execução de forma que não será
        // executado até que todos os outros saiam ou um yield seja chamado
        // (ou caso esse seja o único processo na pilha)
        processes.push_front(process);

        return process->getPid();
    } else {
        return -1;
    }

    return process->getPid();
}

// Libera o fluxo de controle para "to"
bool Kernel::yield(const uint64_t to) {
    for (auto process : processes) {
        if (process->getPid() == to) {
            processes.remove(process);
            processes.push_back(process);
            break;
        }
    }

    return false;
}

void Kernel::exit(const uint64_t pid) {
    if (pid == 0) {
        if (processes.back()->getPid() != 1) {
            // Se for o processo do menu, passa para o processo anterior
            // qual foi a opção selecionada no menu
            if (processes.back()->executable.getOriginalPath() == "apps/menu") {
                auto menu = processes.back();
                processes.pop_back();
                processes.back()->setEnvVar("menu.entry", menu->getEnvVar("menu.entry"));
            } else {
                processes.pop_back();
            }
        }
    } else if (pid > 1) {
        for (auto process : processes) {
            if (process->getPid() == pid) {
                processes.remove(process);
                break;
            }
        }
    }
}

string Kernel::getenv(const string key) {
    return processes.back()->getEnvVar(key);
}

void Kernel::setenv(const string key, const string value) {
    processes.back()->setEnvVar(key, value);
}

void Kernel::audio_tick(uint8_t channel) {
    bool unmap = false;

    // Roda o processo no topo da lista de processos
    if (processes.size() > 0) {
        Process *p = processes.back();

        // Traz o cart do processo pra RAM se já não estiver
        if (!p->isMapped()) {
            // Retira RAM do processo anterior
            for (auto q :processes) {
                if (ram.back() == q->getMemory()) {
                    ram.pop_back();
                    q->unmap();
                    break;
                }
            }
            ram.push_back(p->getMemory());

            unmap = true;
        }

        audioMutex.lock();
        p->audio_tick(channel);
        audioMutex.unlock();

        // Retira a ram do processo
        if (unmap) {
            ram.pop_back();
            p->unmap();
        }
    }
}

// API de acesso à memória
uint64_t Kernel::write(uint64_t start, const uint8_t* data, uint64_t size) {
    uint64_t end = start + size;
    // Quantos bytes foram escritos
    uint64_t written = 0;

    if (start > end) {
        uint64_t buffer = end;
        end = start;
        start = buffer;
    }

    if (start > lastUsedMemByte) {
        start = lastUsedMemByte;
        size = end - start;
    }

    if (end > lastUsedMemByte) {
        end = lastUsedMemByte;
        size = end - start;
    }

    // Segmenta o write para cada bloco de ram em que ele afetar
    for (auto memBlock : ram) {
        uint64_t blkStart = memBlock->addr(), blkSize = memBlock->size();
        uint64_t blkEnd = blkStart + blkSize;

        // Verifica se o write afeta esse bloco de memória
        if (blkEnd > start && blkStart < end) {
            // Calcula as boundaries do write para atingir apenas esse bloco
            uint64_t writeStart, writeEnd;

            if (blkStart < start) {
                writeStart = start;
            }
            else {
                writeStart = blkStart;
            }

            if (blkEnd > end) {
                writeEnd = end;
            }
            else {
                writeEnd = blkEnd;
            }

            // Executa um write apenas nesse bloco
            written += memBlock->write(writeStart-blkStart, data+(writeStart-start), writeEnd - writeStart);
        }
    }

    return written;
}

string Kernel::read(uint64_t start, uint64_t size) {
    uint64_t end = start + size;
    // Quantos bytes foram lidos
    uint64_t numRead = 0;

    if (start > end) {
        uint64_t buffer = end;
        end = start;
        start = buffer;
    }

    if (start > lastUsedMemByte) {
        start = lastUsedMemByte;
        size = end - start;
    }

    if (end > lastUsedMemByte) {
        end = lastUsedMemByte;
        size = end - start;
    }

    string stringBuffer((size_t)size, '\0');
    uint8_t* buffer = (uint8_t*)&stringBuffer[0];

    // Segmenta o read para cada bloco de ram em que ele afetar
    for (auto memBlock : ram) {
        uint64_t blkStart = memBlock->addr(), blkSize = memBlock->size();
        uint64_t blkEnd = blkStart + blkSize;

        // Verifica se o read afeta esse bloco de memória
        if (blkEnd > start && blkStart < end) {
            // Calcula as boundaries do read para atingir apenas esse bloco
            uint64_t readStart, readEnd;

            if (blkStart < start) {
                readStart = start;
            }
            else {
                readStart = blkStart;
            }

            if (blkEnd > end) {
                readEnd = end;
            }
            else {
                readEnd = blkEnd;
            }

            // Executa um read apenas nesse bloco
            numRead += memBlock->read(readStart - blkStart, buffer + (readStart - start), readEnd - readStart);
        }
    }

    return stringBuffer.substr(0, numRead);
}

bool Kernel::checkCartStructure(Path& root) {
    cout << "[kernel] " << "checking cart " << root.getPath() << endl;

    Path lua = root.resolve(Process::LuaEntryPoint);
    Path assets = root.resolve(Process::AssetsEntryPoint);

    cout << "	" << " checking if dir " << assets.getPath() << endl;
    cout << "	" << " checking if file " << lua.getPath() << endl;

    return fs::isDir(root) &&
        fs::isDir(assets) &&
        !fs::isDir(lua);
}

// Wrapper estático para a API
unsigned long kernel_api_write(unsigned long to, const string data) {
    return (unsigned long)KernelSingleton->write(to, (uint8_t*)data.data(), data.size());
}

string kernel_api_read(const unsigned long from, const unsigned long amount) {
    return KernelSingleton->read(from, amount);
}

unsigned long kernel_api_exec(const string executable, luabridge::LuaRef lEnvironment) {
    if (lEnvironment.isTable()) {
        map <string, string> environment;

        auto L = lEnvironment.state();
        push(L, lEnvironment);         
        lua_pushnil(L);

        while (lua_next(L, -2) != 0) {
            if (lua_isstring(L, -2)) {
                environment.emplace(lua_tostring(L, -2), lua_tostring(L, -1));
            }
            lua_pop(L, 1);
        }
     
        lua_pop(L, 1);

        return KernelSingleton->exec(executable, environment);
    } else {
        cout << "ERROR" << endl;
        return 0;
    }
}

bool kernel_api_yield(unsigned long pid) {
    return KernelSingleton->yield(pid);
}

void kernel_api_exit(unsigned long pid) {
    return KernelSingleton->exit(pid);
}

void kernel_api_setenv(const string key, const string value) {
    KernelSingleton->setenv(key, value);
}

string kernel_api_getenv(const string key) {
    return KernelSingleton->getenv(key);
}

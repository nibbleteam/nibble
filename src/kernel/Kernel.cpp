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
    auto p = runningProcess;
    // Não abre menu no menu
    if (p &&
        p->executable.getOriginalPath() != "apps/menu") {
        auto environment = p->getEnv();
        environment["app.pid"] = environment["pid"];

        auto pid = exec("apps/menu", environment);
        //wait(pid);
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
        float delta = currentTime - lastTime;
        //float fps = 1.f / delta;
        lastTime = currentTime;

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
        audioMutex.lock();
        auto pcopy = processes;
        for (auto p :pcopy) {
            if (!p->isRunning())
                continue;

            runningProcess = p;

            // Traz o cart do processo pra RAM se já não estiver
            ram.push_back(p->getMemory());

            if (p->isInitialized()) {
                p->update(delta);
                p->draw();
                gpu->render();
            } else {
                p->init();
            }

            ram.pop_back();
            p->unmap();
        }
        audioMutex.unlock();

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

        processes.insert(process);

        return process->getPid();
    } else {
        return -1;
    }

    return process->getPid();
}

// Espera "wait" sair
void Kernel::wait(const uint64_t wait) {
    waitlist.emplace(runningProcess->getPid(), wait);
    runningProcess->setRunning(false);
}

void Kernel::kill(const uint64_t pid) {
    auto p = runningProcess;

    if (pid == 0) {
        if (p->getPid() != 1) {
            processes.erase(p);
        }
    } else if (pid > 1) {
        for (auto process : processes) {
            if (process->getPid() == pid) {
                processes.erase(process);
                break;
            }
        }
    }

    checkWaitlist();
}

string Kernel::getenv(const string key) {
    return runningProcess->getEnvVar(key);
}

void Kernel::setenv(const string key, const string value) {
    runningProcess->setEnvVar(key, value);
}

void Kernel::audio_tick(uint8_t channel) {
    audioMutex.lock();
    auto previousRunningProcess = runningProcess;

    auto pcopy = processes;
    for (auto p :pcopy) {
        if (!p->isRunning())
            continue;

        runningProcess = p;

        // Traz o cart do processo pra RAM se já não estiver
        if (p->isInitialized()) {
            p->audio_tick(channel);
        }
    }

    runningProcess = previousRunningProcess;
    audioMutex.unlock();
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

void Kernel::checkWaitlist() {
    for (auto w=waitlist.begin();w!=waitlist.end();) {
        auto i = *w;
        bool exists = false;
        for (auto p :processes) {
            if (p->getPid() == i.second) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            for (auto p :processes) {
                if (p->getPid() == i.first) {
                    p->setRunning(true);
                    break;
                }
            }
            
            waitlist.erase(w++); 
        } else {
            w++;
        }
    }
}

luabridge::LuaRef Kernel::receive() {
    return runningProcess->readMessage();
}

bool Kernel::send(const uint64_t pid, luabridge::LuaRef message) {
    for (auto p :processes) {
        if (p->getPid() == pid) {
            p->writeMessage(message);

            return true;
        }
    }

    return false;
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
            if (lua_isstring(L, -2) && lua_isstring(L, -1)) {
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

void kernel_api_wait(unsigned long pid) {
    KernelSingleton->wait(pid);
}

void kernel_api_kill(unsigned long pid) {
    KernelSingleton->kill(pid);
}

void kernel_api_setenv(const string key, const string value) {
    KernelSingleton->setenv(key, value);
}

string kernel_api_getenv(const string key) {
    return KernelSingleton->getenv(key);
}

bool kernel_api_send(unsigned long pid, luabridge::LuaRef message) {
    return KernelSingleton->send(pid, message);
}

luabridge::LuaRef kernel_api_receive() {
    return KernelSingleton->receive();
}

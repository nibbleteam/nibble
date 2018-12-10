#include <iostream>
#include <algorithm>
#include <stdexcept>
#include <thread>

#include <kernel/Kernel.hpp>
#include <kernel/mmap/Image.hpp>
#include <kernel/mmap/Binary.hpp>

using namespace std;

Kernel::Kernel() {
    // Cria dispositivos
    gpu = make_unique<GPU>(memory);
    audio = make_unique<Audio>(memory);
    controller = make_unique<Controller>(memory);
    keyboard = make_unique<Keyboard>(memory);
    mouse = make_unique<Mouse>(memory);

    // Inicializa kernel & dispositivos
    startup();
}

Kernel::~Kernel() {
    shutdown();
}

void Kernel::startup() {
    runningProcess = 0;
    lastProcess = 1;

    gpu->startup();
    mouse->startup();
    audio->startup();
    keyboard->startup();
    controller->startup();

    auto initEnv = map<string, string>();

    if (get<0>(exec("apps/system/core/init.nib", initEnv)) > 0) {
        cout << "[kernel] " << "process started" << endl;
    }
}

void Kernel::menu() {
    try {
        // Pega o processo que está rodando
        auto &process = processes.at(runningProcess);

        // Não abre menu no menu
        if (process->executable.getOriginalPath() != NIBBLE_APP_MENU) {
            // Adiciona "app.pid" a uma cópia do environment do processo
            auto environment = process->getEnv();
            environment["app.pid"] = environment["pid"];

            exec(NIBBLE_APP_MENU, environment);
        }
    } catch (out_of_range &o) {
        // Nenhum processo rodando
    }
}

void Kernel::shutdown() {
    /* Limpeza do Kernel */

    // Se não há processos, a wait table precisa
    // estar vazia
    waitTable.clear();

    // Mensagens na queue de um processo enquanto
    // outro está sendo deletado causam SEGFAULT,
    // por isso limpamos primeiro
    for_each(begin(processes), end(processes), [&] (auto &pair) {
        auto &process = pair.second;
        process->clearMessages();
    });

    // Deletamos os processos
    processes.clear();

    /* Shutdown dos periféricos */

    gpu->shutdown();
    mouse->shutdown();
    audio->shutdown();
    keyboard->shutdown();
    controller->shutdown();
}

void Kernel::loop() {
    sf::Clock clock;
    float lastTime = 0;
    
    while (gpu->window.isOpen()) {
        float currentTime = clock.getElapsedTime().asSeconds();
        float delta = currentTime - lastTime;
        //float fps = 1.f / delta;
        lastTime = currentTime;

        sf::Event event;

        // Event handling
        controller->update();
        mouse->update();
        while (gpu->window.pollEvent(event)) {
            switch (event.type) {
                // Fecha a janela no "x" ou alt-f4 etc
            case sf::Event::Closed: {
                gpu->window.close();
            }
                break;
                // Redimensiona e centraliza o vídeo
            case sf::Event::Resized: {
                gpu->resize();
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
                    shutdown();
                    startup();
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
                int16_t x = event.mouseMove.x;
                int16_t y = event.mouseMove.y;
                gpu->transformMouse(x, y);
                mouse->moved(x, y);
            }
                break;
            default:
                break;
            }
        }

        // Roda o processo no topo da lista de processos
        audioMutex.lock();
        auto processes_copy = processes;
        for (auto &pair: processes_copy) {
            auto &pid = pair.first;
            auto &process = pair.second;

            if (!process->running)
                continue;

            runningProcess = pid;

            auto spritesheetMetadata = (mmap::ImageMetadata*)(memory.raw+process->layout.spritesheet);
            auto spritesheet = (memory.raw+process->layout.spritesheet+sizeof(mmap::ImageMetadata));

            gpu->sourceW = spritesheetMetadata->w;
            gpu->sourceH = spritesheetMetadata->h;
            gpu->source = spritesheet;

            if (process->initialized) {
                process->update(delta);
                process->draw();
            } else {
                process->init();
            }
        }
        audioMutex.unlock();

        gpu->draw();
    }
}

// Executa "executable" passando "environment"
// executable é um diretório que deve seguir a seguinte organização:
// <cart-name>/
//  - main.lua
tuple<int32_t, string> Kernel::exec(const string &executable, map<string, string> &environment) {
    cout << "[kernel] exec " << executable << endl;

    Path executablePath(executable);

    // Verifica a existência e estrutura de do cart "executable"
    if (!checkAppStructure(executablePath)) {
        return tuple<int, string> (-3, "app not found: \""+executablePath.getOriginalPath()+"\"");
    }

    // Cria o processo carregando o app para a memória na
    // primeira localização livre
    processes[lastProcess] = make_shared<Process>(memory, executablePath, environment, lastProcess, runningProcess);
    auto &process = processes[lastProcess];

    if (process->ok) {
        // Adiciona as chamadas de sistema providas pelo Kernel
        // ao ambiente lua do processo
        process->addSyscalls();

        return tuple<int, string> (lastProcess++, "");
    } else {
        return tuple<int, string> (-4, process->error);
    }
}

// Espera "wait" sair
void Kernel::wait(const PID wait) {
    waitTable[runningProcess] = wait;
    processes[runningProcess]->running = false;
}

void Kernel::kill(const PID pid) {
    auto &p = processes[runningProcess];

    if (pid == 0) {
        if (p->pid != 1) {
            processes.erase(p->pid);
        }
    } else if (pid > 1) {
        processes.erase(pid);
    }

    updateWaitTable();
}

string Kernel::getenv(const string key) {
    return processes[runningProcess]->getEnvVar(key);
}

void Kernel::setenv(const string key, const string value) {
    return processes[runningProcess]->setEnvVar(key, value);
}

// API de acesso à memória
size_t Kernel::write(size_t start, const uint8_t* data, size_t size) {
    if (start >= NIBBLE_MEM_SIZE) {
        return 0;
    }

    if (start+size > NIBBLE_MEM_SIZE) {
        size = NIBBLE_MEM_SIZE-start;
    }

    memcpy(memory.raw+start, data, size);

    memory.triggers(start, start+size, Memory::ACCESS_WRITE);

    return size;
}

string Kernel::read(size_t start, size_t size) {
    if (start >= NIBBLE_MEM_SIZE) {
        return "";
    }

    if (start+size > NIBBLE_MEM_SIZE) {
        size = NIBBLE_MEM_SIZE-start;
    }

    string stringBuffer(size, '\0');
    uint8_t* buffer = (uint8_t*)&stringBuffer[0];

    memory.triggers(start, start+size, Memory::ACCESS_READ);

    memcpy(buffer, memory.raw+start, size);

    memory.triggers(start, start+size, Memory::ACCESS_AFTER_READ);

    return stringBuffer;
}

bool Kernel::checkAppStructure(Path& root) {
    cout << "[kernel] " << "checking app " << root.getPath() << endl;

    Path lua = root.resolve(Process::LuaEntryPoint);

    cout << "	" << " checking if file " << lua.getPath() << endl;

    return fs::isDir(root) &&
        !fs::isDir(lua);
}

void Kernel::updateWaitTable() {
    for (auto w=waitTable.begin();w!=waitTable.end();) {
        auto i = *w;
        bool exists = false;


        for (auto &p :processes) {
            if (p.second->pid == i.second) {
                exists = true;
                break;
            }
        }

        if (!exists) {
            processes[i.first]->running = true;
            
            waitTable.erase(w++); 
        } else {
            w++;
        }
    }
}

void Kernel::audioTick() {
    audioMutex.lock();
    auto pcopy = processes;
    for (auto &pair :processes) {
        auto &pid = pair.first;
        auto &p = pair.second;
        
        if (!p->running)
            continue;

        runningProcess = pid;

        if (p->initialized) {
            p->audio_tick();
        }
    }
    audioMutex.unlock();
}

luabridge::LuaRef Kernel::receive() {
    return processes[runningProcess]->readMessage();
}

bool Kernel::send(const uint64_t pid, luabridge::LuaRef message) {
    try {
        processes.at(pid)->writeMessage(message);
    } catch (out_of_range &o) {
        return false;
    }

    return true;
}

// Mapeia o arquivo `file` na memória
// retorna o endereço no qual foi mapeado
size_t Kernel::memmap(const string& file) {
    auto filePath = Path(file);
    auto ext = filePath.getExtension();

    if (ext == "png") {
        return mmap::read_image(memory, filePath);
    }

    return mmap::read_binary(memory, filePath);
}

// Escreve a área de memória <pos> 
void Kernel::memsync(const size_t pos, const string& file, bool del) {
    auto filePath = Path(file);
    auto ext = filePath.getExtension();

    if (ext == "png") {
        mmap::write_image(memory, pos, filePath);
    } else {
        mmap::write_binary(memory, pos, filePath);
    }

    if (del) {
        memory.deallocate(pos);
    }
}

// Aumenta ou diminui o tamanho de um arquivo
// mapeado em memória
size_t Kernel::memresize(const size_t pos, const size_t size) {
    return memory.resize(pos, size);
}

vector<string> Kernel::list(const string& dir) {
    vector<string> stringList;
    auto dirPath = Path(dir);
    bool success;

    auto list = fs::listDirectory(dirPath, success);

    for (auto &path: list) {
        stringList.push_back(path.getOriginalPath());
    }

    return stringList;
}

// Wrapper estático para a API
unsigned long kernel_api_write(unsigned long to, const string& data) {
    return (unsigned long)KernelSingleton.lock()->write(to, (uint8_t*)data.data(), data.size());
}

string kernel_api_read(const unsigned long from, const unsigned long amount) {
    return KernelSingleton.lock()->read(from, amount);
}

int kernel_api_exec(lua_State* L) {
    int args = lua_gettop(L);

    if (args >= 2) {
        if (lua_istable(L, 2)) {
            const string executable = string(lua_tostring(L, 1));
            map <string, string> environment;

            lua_gettable(L, 2);
            lua_pushnil(L);

            while (lua_next(L, -2) != 0) {
                if (lua_isstring(L, -2) && lua_isstring(L, -1)) {
                    environment.emplace(lua_tostring(L, -2), lua_tostring(L, -1));
                }
                lua_pop(L, 1);
            }
         
            lua_pop(L, 1);

            auto result = KernelSingleton.lock()->exec(executable, environment);

            lua_pop(L, 1);
            lua_pop(L, 1);

            lua_pushnumber(L, get<0>(result));
            lua_pushstring(L, get<1>(result).c_str());

            return 2;
        } else {
            lua_pop(L, 1);
            lua_pop(L, 1);

            lua_pushnumber(L, -2);
            lua_pushstring(L, "`environment` is not a table!");

            return 2;
        }
    }

    lua_pop(L, 1);
    lua_pop(L, 1);

    lua_pushnumber(L, -1);
    lua_pushstring(L, "needs 2 arguments");

    return 2;
}

void kernel_api_wait(unsigned long pid) {
    KernelSingleton.lock()->wait(pid);
}

void kernel_api_kill(unsigned long pid) {
    KernelSingleton.lock()->kill(pid);
}

void kernel_api_setenv(const string key, const string value) {
    KernelSingleton.lock()->setenv(key, value);
}

string kernel_api_getenv(const string key) {
    return KernelSingleton.lock()->getenv(key);
}

bool kernel_api_send(unsigned long pid, luabridge::LuaRef message) {
    return KernelSingleton.lock()->send(pid, message);
}

luabridge::LuaRef kernel_api_receive() {
    return KernelSingleton.lock()->receive();
}

size_t kernel_api_memmap(const string& file) {
    return KernelSingleton.lock()->memmap(file);
}

void kernel_api_memsync(const size_t pos, const string& file, bool del) {
    KernelSingleton.lock()->memsync(pos, file, del);
}

size_t kernel_api_memresize(const size_t pos, const size_t size) {
    return KernelSingleton.lock()->memresize(pos, size);
}

luabridge::LuaRef kernel_api_list(const string& dir, lua_State *L) {
    auto dirs = KernelSingleton.lock()->list(dir);
    auto i = 1;
    auto tbl = luabridge::newTable(L);

    for (auto &d: dirs) {
        tbl[i++] = d;
    }

    return tbl;
}

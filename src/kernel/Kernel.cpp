#include <iostream>
#include <algorithm>
#include <stdexcept>
#include <thread>

#include <kernel/Kernel.hpp>
#include <kernel/mmap/Image.hpp>
#include <kernel/mmap/Binary.hpp>

using namespace std;

Kernel::Kernel() {
    if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
        cout << "SDL_Init: " << SDL_GetError() << endl;
    }

    memory.set_log(true);

    cout << endl << "=============== Memory Map ===============" << endl;

    // Cria dispositivos
    gpu = make_unique<GPU>(memory);
    audio = make_unique<Audio>(memory);
    controller = make_unique<Controller>(memory);
    keyboard = make_unique<Keyboard>(memory);
    mouse = make_unique<Mouse>(memory);

#ifndef NIBBLE_DISABLE_MIDI_CONTROLLER
    midi_controller = make_unique<MidiController>(memory);
#endif

    cout << "==========================================" << endl << endl;

    memory.set_log(false);

    // Inicializa kernel & dispositivos
    startup();
}

Kernel::~Kernel() {
    shutdown();

    SDL_Quit();
}

void Kernel::startup() {
    gpu->startup();
    mouse->startup();
    keyboard->startup();
    controller->startup();
#ifndef NIBBLE_DISABLE_MIDI_CONTROLLER
    midi_controller->shutdown();
#endif
    audio->startup();

    auto entrypoint = Path("./frameworks/kernel/");

    process = make_unique<Process>(memory, entrypoint);

    if (!process->ok) {
        cout << "Could not start LuaJIT" << endl;
        exit(1);
    }
}

void Kernel::menu() {
    open_menu_next_frame = true;
}

void Kernel::shutdown() {
    /* Shutdown dos periféricos */

    gpu->shutdown();
    audio->shutdown();
    mouse->shutdown();
    keyboard->shutdown();
    controller->shutdown();
#ifndef NIBBLE_DISABLE_MIDI_CONTROLLER
    midi_controller->shutdown();
#endif

    // TODO: Hack para dealocar memória dos processos
    // mas não dos despositivos
    memory.deallocate(79856);
}

void Kernel::loop() {
    float last_time = 0;

    while (true) {
        float current_time = SDL_GetTicks();
        float delta = (current_time - last_time)/1000;
        //float fps = 1.f / delta;
        last_time = current_time;

        SDL_Event event;

        // Input updating
        controller->update();
        mouse->update();
        keyboard->update();
#ifndef NIBBLE_DISABLE_MIDI_CONTROLLER
        midi_controller->update();
#endif

        // Event handling
        while (SDL_PollEvent(&event)) {
            switch (event.type) {
                // Fecha a janela no "x" ou alt-f4 etc
                case SDL_QUIT: {
                    return;
                } break;

                case SDL_WINDOWEVENT: {
                    switch (event.window.event) {
                        // Redimensiona e centraliza o vídeo
                        case SDL_WINDOWEVENT_RESIZED:
                        case SDL_WINDOWEVENT_SIZE_CHANGED: {
                            gpu->resize();
                        } break;
                        // Solta botões ao perder foco
                        case SDL_WINDOWEVENT_FOCUS_LOST: {
                            controller->all_released();
                            mouse->released(0);
                            mouse->released(1);
                        } break;
                        // Solta botões do mouse ao sair
                        case SDL_WINDOWEVENT_LEAVE: {
                            mouse->released(0);
                            mouse->released(1);
                        } break;
                    }
                } break;

                // Teclado
                case SDL_TEXTINPUT: {
                    // TODO: Enviar toda a string (em utf-8)
                    keyboard->input(event.text.text[0]);
                } break;

                case SDL_KEYDOWN: {
                    if (event.key.keysym.sym == SDLK_r &&
                        (event.key.keysym.mod&KMOD_LCTRL ||
                         event.key.keysym.mod&KMOD_RCTRL)) {
                        shutdown();
                        startup();
                    } else if (event.key.keysym.sym == SDLK_ESCAPE) {
                        menu();
                    } else if (event.key.keysym.sym == SDLK_RETURN) {
                        keyboard->input(13);
                    } else if (event.key.keysym.sym == SDLK_BACKSPACE) {
                        keyboard->input(8);
                    } else {
                        controller->kbd_pressed(event);
                    }
                } break;

                case SDL_KEYUP: {
                    controller->kbd_released(event);
                } break;

                case SDL_JOYBUTTONDOWN: {
                    if (event.jbutton.button == 9) {
                        menu();
                    } else {
                        controller->joy_pressed(event);
                    }
                } break;

                case SDL_JOYBUTTONUP: {
                    controller->joy_released(event);
                } break;

                case SDL_JOYAXISMOTION: {
                    controller->joy_moved(event);
                } break;

                case SDL_JOYDEVICEADDED: {
                    controller->joy_connected(event);
                } break;

                case SDL_JOYDEVICEREMOVED: {
                    controller->joy_disconnected(event);
                } break;

                // Mouse
                case SDL_MOUSEBUTTONDOWN: {
                    mouse->pressed(event.button.button != SDL_BUTTON_LEFT);
                } break;

                case SDL_MOUSEBUTTONUP: {
                    mouse->released(event.button.button != SDL_BUTTON_LEFT);
                } break;

                case SDL_MOUSEMOTION: {
                    int16_t x = event.motion.x;
                    int16_t y = event.motion.y;

                    gpu->transform_mouse(x, y);
                    mouse->moved(x, y);
                } break;

                default:
                    break;
            }
        }

        // Espera a gpu inicializar
        if (gpu->cycle > BOOT_CYCLES) {
            // Roda o processo no topo da lista de processos
            if (process->initialized) {
                if (open_menu_next_frame) {
                    open_menu_next_frame = false;

                    process->menu();
                }

                process->update(delta);
            } else {
                process->init();
            }
        }

        SDL_Delay(max<int>((1000/GPU_FRAMERATE-1)-(SDL_GetTicks()-last_time), 0));

        gpu->draw();
    }
}

size_t Kernel::api_write(const size_t where, const size_t wanted_size, const uint8_t* what) {
    if (where >= NIBBLE_MEM_SIZE) {
        return 0;
    }

    const auto size = where+wanted_size>NIBBLE_MEM_SIZE? NIBBLE_MEM_SIZE-where: wanted_size;

    memcpy(memory.raw+where, what, size);
    memory.triggers(where, where+size, Memory::ACCESS_WRITE);

    return size;
}

size_t Kernel::api_read(char* buffer, const size_t where, size_t wanted_size) {
    if (where >= NIBBLE_MEM_SIZE) {
        return 0;
    }

    const auto size = where+wanted_size>NIBBLE_MEM_SIZE?NIBBLE_MEM_SIZE-where:wanted_size;

    memory.triggers(where, where+size, Memory::ACCESS_READ);

    memcpy(buffer, memory.raw+where, size);

    memory.triggers(where, where+size, Memory::ACCESS_AFTER_READ);

    return size;
}

void Kernel::api_use_spritesheet(const size_t source, const int w, const int h) {
    auto spritesheet = memory.raw+source;

    gpu->source_w = w;
    gpu->source_h = h;
    gpu->source = spritesheet;
}

tuple<size_t, int, int> Kernel::api_load_spritesheet(const string from_str) {
    auto path = Path(from_str);

    return mmap::read_image(memory, path);
}

// Wrapper estático para a API

size_t kernel_api_write(const size_t to, const size_t amount, const char* data) {
    return KernelSingleton.lock()->api_write(to, amount, (uint8_t*)data);
}

size_t kernel_api_read(char* buffer, const size_t from, const size_t amount) {
    return KernelSingleton.lock()->api_read(buffer, from, amount);
}

void kernel_api_load_spritesheet(const char* from, size_t* ptr, int* w, int* h) {
    auto t = KernelSingleton.lock()->api_load_spritesheet(string(from));

    *ptr = get<0>(t);
    *w = get<1>(t);
    *h = get<2>(t);
}

void kernel_api_use_spritesheet(const size_t source, const int w, const int h) {
    KernelSingleton.lock()->api_use_spritesheet(source, w, h);
}

void gpu_api_sprite(int16_t x, int16_t y,
                    int16_t sx, int16_t sy,
                    int16_t w, int16_t h,
                    uint8_t pal) {
    KernelSingleton.lock()->gpu->sprite(x, y, sx, sy, w, h, pal);
}

void gpu_api_clip(int16_t x, int16_t y, int16_t w, int16_t h) {
    KernelSingleton.lock()->gpu->clip(x, y, w, h);
}

void gpu_api_circle_fill(int16_t x, int16_t y, int16_t r, uint8_t c) {
    KernelSingleton.lock()->gpu->circle_fill(x, y, r, c);
}

void gpu_api_quad_fill(int16_t x1, int16_t y1,
                       int16_t x2, int16_t y2,
                       int16_t x3, int16_t y3,
                       int16_t x4, int16_t y4,
                       uint8_t c) {
    KernelSingleton.lock()->gpu->quad_fill(x1, y1, x2, y2, x3, y3, x4, y4, c);
}


void gpu_api_tri_fill(int16_t x1, int16_t y1,
                      int16_t x2, int16_t y2,
                      int16_t x3, int16_t y3,
                      uint8_t c) {
    KernelSingleton.lock()->gpu->tri_fill(x1, y1, x2, y2, x3, y3, c);
}

void gpu_api_rect_fill(int16_t x, int16_t y, int16_t w, int16_t h, uint8_t c) {
    KernelSingleton.lock()->gpu->rect_fill(x, y, w, h, c);
}

void gpu_api_circle(int16_t x, int16_t y, int16_t r, uint8_t c) {
    KernelSingleton.lock()->gpu->circle(x, y, r, c);
}

void gpu_api_quad(int16_t x1, int16_t y1,
                  int16_t x2, int16_t y2,
                  int16_t x3, int16_t y3,
                  int16_t x4, int16_t y4,
                  uint8_t c) {
    KernelSingleton.lock()->gpu->quad(x1, y1, x2, y2, x3, y3, x4, y4, c);
}


void gpu_api_tri(int16_t x1, int16_t y1,
                 int16_t x2, int16_t y2,
                 int16_t x3, int16_t y3,
                 uint8_t c) {
    KernelSingleton.lock()->gpu->tri(x1, y1, x2, y2, x3, y3, c);
}

void gpu_api_rect(int16_t x, int16_t y, int16_t w, int16_t h, uint8_t c) {
    KernelSingleton.lock()->gpu->rect(x, y, w, h, c);
}

void gpu_api_clear(uint8_t c) {
    KernelSingleton.lock()->gpu->clear(c);
}


void gpu_api_line(int16_t x1, int16_t y1, int16_t x2, int16_t y2, uint8_t c) {
    KernelSingleton.lock()->gpu->line(x1, y1, x2, y2, c);
}

int gpu_start_capturing(const char* file) {
    return (int)KernelSingleton.lock()->gpu->start_capturing(string(file));
}

int gpu_stop_capturing() {
    return (int)KernelSingleton.lock()->gpu->stop_capturing();
}

LuaString* api_list_files(const char* path, size_t* length_out, int* ok_out) {
    bool ok;
    auto files = fs::list_directory(Path(string(path)), ok);
    auto amount = files.size();

    *ok_out = (int)ok;
    *length_out = amount;

    if (ok && amount > 0) {
        auto ptr_files = new LuaString[amount];

        for (size_t i=0;i<amount;i++) {
            auto file = files[i];
            auto o_path = file.get_original_path();
            auto length = o_path.length();

            ptr_files[i].ptr = new char[length];

            ptr_files[i].len = length;
            memcpy(ptr_files[i].ptr, o_path.c_str(), length);
        }

        return ptr_files;
    } else {
        return nullptr;
    }
}

API int api_create_directory(const char* strpath) {
    auto path = Path(string(strpath));

    return (int)fs::create_directory(path);
}

API int api_create_file(const char* strpath) {
    auto path = Path(string(strpath));

    return (int)fs::create_file(path);
}

API int api_touch_file(const char* strpath) {
    auto path = Path(string(strpath));

    return (int)fs::touch_file(path);
}

API void audio_enqueue_command(const uint64_t timestamp,
                               const uint8_t ch,
                               const uint8_t cmd,
                               const uint8_t note,
                               const uint8_t intensity) {
    KernelSingleton.lock()->audio->enqueue_command(timestamp, ch, cmd, note, intensity);
}

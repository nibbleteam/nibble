#ifndef KERNEL_H
#define KERNEL_H

#include <cstdint>
#include <memory>
#include <vector>
#include <set>
#include <string>
#include <mutex>
#include <atomic>
#include <list>

#include <kernel/filesystem.hpp>
#include <kernel/Process.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Types.hpp>

#include <devices/GPU.hpp>
#include <devices/Audio.hpp>
#include <devices/Keyboard.hpp>
#include <devices/Mouse.hpp>
#include <devices/Controller.hpp>

#include <LuaBridge/LuaBridge.h>

using namespace std;

// Simula o hardware do console e um kernel.
class Kernel {
private:
    /* Memória */
    Memory memory;

    /* Processo -> Roda Código Lua */
    unique_ptr<Process> process;

    // Usado para sincronizar o vídeo com a placa
    // de áudio
    mutex audio_mutex;
public:
    /* Dispositivos */

    // GPU 
    unique_ptr<GPU> gpu;
    // APU
    unique_ptr<Audio> audio;
    // HID
    unique_ptr<Keyboard> keyboard;
    unique_ptr<Mouse> mouse;
    unique_ptr<Controller> controller;
public:
    Kernel();
    ~Kernel();

    // Controles de power e botões de hardware
    void startup();
    void shutdown();
    void reset();
    void menu();

    // Sinal de sincronização do áudio
    void audio_tick();

    // Loop principal do console.
    // Roda o processo (código Lua)
    void loop();

    // API
    size_t api_write(const size_t, const size_t, const uint8_t*);
    size_t api_read(char*, const size_t, const size_t);

    void api_use_spritesheet(const size_t, const int, const int);
    tuple<size_t, int, int> api_load_spritesheet(string);
};

extern "C" {
    int main(int, char**);

    typedef struct LuaString {
        char* ptr;
        size_t len;
    } LuaString;

    // Memória
    size_t kernel_api_read(char*, const size_t, const size_t);
    size_t kernel_api_write(const size_t, const size_t, const char*);

    // Spritesheets
    void kernel_api_load_spritesheet(const char*, size_t*, int*, int*);
    void kernel_api_use_spritesheet(const size_t, const int, const int);

    // Arquivos
    LuaString* api_list_files(const char*, size_t*, int*);

    // Desenho
    void gpu_api_line(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_rect(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_tri(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_quad(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_circle(int16_t, int16_t, int16_t, uint8_t);

    void gpu_api_rect_fill(int16_t, int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_tri_fill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_quad_fill(int16_t, int16_t,
                           int16_t, int16_t,
                           int16_t, int16_t,
                           int16_t, int16_t,
                           uint8_t);
    void gpu_api_circle_fill(int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_sprite(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    void gpu_api_clip(int16_t, int16_t, int16_t, int16_t);
    void gpu_api_clear(uint8_t);
    int gpu_start_capturing(const char*);
    int gpu_stop_capturing();

#include <cstdlib>
}

extern weak_ptr<Kernel> KernelSingleton;

#endif /* KERNEL_H */


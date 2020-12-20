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
#include <queue>

extern "C" {
#include <uv.h>
}

#include <kernel/filesystem.hpp>
#include <kernel/Process.hpp>
#include <kernel/Memory.hpp>
#include <kernel/Types.hpp>

#include <devices/GPU.hpp>
#include <devices/Audio.hpp>
#include <devices/Keyboard.hpp>
#include <devices/Mouse.hpp>
#include <devices/Controller.hpp>
#include <devices/MidiController.hpp>

#ifdef WIN32
#define API __declspec(dllexport)
#else
#define API
#endif

using namespace std;

// Simula o hardware do console e um kernel.
class Kernel {
private:
    /* Memória */
    Memory memory;

    /* Processo -> Roda Código Lua */
    unique_ptr<Process> process;

    /* Devemos abrir o menu na próxima frame? */
    bool open_menu_next_frame;

    /* Ligado? */
    bool power;

    /* Início da memória livre */
    size_t process_memory_start;

    /* Conexões UDP */
    unique_ptr<uv_loop_t> event_loop;
    unique_ptr<uv_udp_t> udp;

    /* Mensagens de rede */
    queue<string> network_messages;
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
#ifndef NIBBLE_DISABLE_MIDI_CONTROLLER
    unique_ptr<MidiController> midi_controller;
#endif
public:
    Kernel(const bool);
    ~Kernel();

    // Controles de power e botões de hardware
    void startup();
    void shutdown();
    void reset();
    void menu();

    // Loop principal do console.
    // Roda o processo (código Lua)
    void loop();

    // O servidor enviou uma mensagem
    void network_message_received(const string);

    // API
    void api_shutdown();

    size_t api_write(const size_t, const size_t, const uint8_t*);
    size_t api_read(char*, const size_t, const size_t);

    void api_use_spritesheet(const size_t, const int, const int);
    tuple<size_t, int, int> api_load_spritesheet(string);
    void api_save_spritesheet(const size_t, const int, const int, const string);
    void api_unload_spritesheet(const size_t);

    void api_send_network_message(const string);
    string api_receive_network_message(bool*);
};

extern "C" {
    API typedef struct LuaString {
        char* ptr;
        size_t len;
    } LuaString;

    // Energia
    API void kernel_api_shutdown();

    // Memória
    API size_t kernel_api_read(char*, const size_t, const size_t);
    API size_t kernel_api_write(const size_t, const size_t, const char*);

    // Spritesheets
    API void kernel_api_load_spritesheet(const char*, size_t*, int*, int*);
    API void kernel_api_save_spritesheet(const size_t, const int, const int, const char*);
    API void kernel_api_use_spritesheet(const size_t, const int, const int);
    API void kernel_api_unload_spritesheet(const size_t);

    // Arquivos
    API LuaString* api_list_files(const char*, size_t*, int*);
    API int api_create_directory(const char*);
    API int api_touch_file(const char*);
    API int api_create_file(const char*);

    // Desenho
    API void gpu_api_line(int16_t, int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_rect(int16_t, int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_tri(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_quad(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_circle(int16_t, int16_t, int16_t, uint8_t);

    API void gpu_api_rect_fill(int16_t, int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_tri_fill(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_quad_fill(int16_t, int16_t,
                           int16_t, int16_t,
                           int16_t, int16_t,
                           int16_t, int16_t,
                           uint8_t);
    API void gpu_api_circle_fill(int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_sprite(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);
    API void gpu_api_clip(int16_t, int16_t, int16_t, int16_t);
    API void gpu_api_clear(uint8_t);
    API int gpu_start_capturing(const char*);
    API int gpu_stop_capturing();

    // Cursor
    API void gpu_api_set_cursor(int16_t, int16_t, int16_t, int16_t, int16_t, int16_t, uint8_t);

    // Áudio
    API void audio_enqueue_command(const uint64_t,
                                   const uint8_t,
                                   const uint8_t,
                                   const uint8_t,
                                   const uint8_t);
    // Rede
    API void send_network_message(const char*, const size_t);
    API LuaString receive_network_message(int*);

    #include <cstdlib>
}

extern weak_ptr<Kernel> KernelSingleton;

#endif /* KERNEL_H */


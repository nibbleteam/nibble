#ifndef MEMORY_H
#define MEMORY_H

#include <functional>
#include <cstdint>
#include <cstring>
#include <string>
#include <tuple>
#include <map>

using namespace std;

class Memory {
public:
    // Tipos de triggers
    enum AccessMode {
        ACCESS_WRITE, ACCESS_READ, ACCESS_AFTER_READ
    };
private:
    // Representa um bloco contínuo de memória, alocado por
    // allocate ou vazio
    struct Area {
        size_t pos;
        size_t size;

        Area(size_t, size_t, function<void(AccessMode)> = nullptr);

        bool operator < (Area&);

        function <void(AccessMode)> trigger;
    };

    // Áreas de memória
    map<uint8_t*, Area> free_areas;
    map<uint8_t*, Area> used_areas;

    bool log_memory_allocation;
protected:
    friend class Kernel;
    friend class Process;

    // Acesso direto à memória
    uint8_t* raw;
public:
    Memory();
    ~Memory();

    // Quantos bytes livres e usados
    size_t free();
    size_t used();

    // Retorna um ponteiro para uma região não usada
    // de memória por n bytes
    uint8_t* allocate(const size_t, const string, function<void(AccessMode)> = nullptr);
    tuple<uint8_t*, size_t> allocate_with_position(const size_t, const string, function<void(AccessMode)> = nullptr);
    // Permite que esse ponteiro seja retornado novamente
    void deallocate(uint8_t*);
    void deallocate(const size_t);

    // Redimensiona uma área de memória
    size_t resize(const size_t, const size_t);

    // Converte uma posição para um ponteiro
    uint8_t* to_ptr(const size_t);
    // Retorna o tamanho de uma área
    size_t get_size(uint8_t*);

    // Verifica e roda os triggers para as áreas dadas
    void triggers(const size_t, const size_t, const AccessMode);

    // Habilita/Desabilita log de alocação
    void set_log(bool);
};

#endif /* MEMORY_H */

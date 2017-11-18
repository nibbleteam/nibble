#ifndef KERNEL_H
#define KERNEL_H

#include <cstdint>

class Kernel {
    // Memória para acesso direto aos dispositivos
    // Cada seção específica (joysticks, video, cart)
    // é implementada como uma extensão
    // da classe Memory
    vector <Memory*> ram;
    
public:

    Kernel();
    ~Kernel();

    // API do kernel
    // Acesso direto a memória
    // O acesso ao vídeo e áudio também é feito através de
    // writes e reads
    uint64_t write(uint64_t, uint8_t*, uint64_t);
    uint64_t read(uint64_t, uint8_t*, uint64_t);
    uint64_t copy(uint64_t, uint64_t, uint64_t);
    // Gerenciamento de processos
    uint64_t exec(string&, vector<string>&);
    bool yield(uint64_t);
    void exit();
};

#endif KERNEL_H

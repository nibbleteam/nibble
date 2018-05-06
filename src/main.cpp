#include <kernel/Kernel.hpp>
#include <cstdlib>

Kernel *KernelSingleton;

void cleanup() {
    delete KernelSingleton;
}

// Entrypoint para rodar no windows, simplesmente chama
// o main padrão
#ifdef WIN32
#include <windows.h>
int WinMain(HINSTANCE* i, HINSTANCE* p, LPTSTR c, int n) {
    return main();
}
#endif

int main() {
    std::atexit(cleanup);

    KernelSingleton = new Kernel();

    KernelSingleton->startup();
    KernelSingleton->loop();

    return 0;
}

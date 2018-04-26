#include <kernel/Kernel.hpp>
#include <cstdlib>

Kernel *KernelSingleton;

void cleanup() {
    delete KernelSingleton;
}

int main() {
    std::atexit(cleanup);

    KernelSingleton = new Kernel();

    KernelSingleton->startup();
    KernelSingleton->loop();

    return 0;
}

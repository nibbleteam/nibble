#include <kernel/Kernel.hpp>
#include <cstdlib>

void cleanup() {
    delete KernelSingleton;
}

int main() {
    std::atexit(cleanup);

	KernelSingleton = new Kernel();

	KernelSingleton->loop();

    return 0;
}

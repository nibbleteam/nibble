#define SDL_MAIN_HANDLED
#include <kernel/Kernel.hpp>

weak_ptr<Kernel> KernelSingleton;

int main() {
    auto kernel = make_shared<Kernel>();

    KernelSingleton = kernel;

    kernel->loop();

    return 0;
}

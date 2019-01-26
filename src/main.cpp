#include <kernel/Kernel.hpp>

#ifdef EMSCRIPTEN
#include <emscripten.h>
#endif

weak_ptr<Kernel> KernelSingleton;

#ifdef EMSCRIPTEN
void loop() {
    KernelSingleton.lock()->loop();
}
#endif

int main(int, char**) {
    auto kernel = make_shared<Kernel>();

    KernelSingleton = kernel;

#ifdef EMSCRIPTEN
    emscripten_set_main_loop(loop, 0, 1);
#else
    kernel->loop();
#endif

    return 0;
}

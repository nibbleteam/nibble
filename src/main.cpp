#include <kernel/Kernel.hpp>

extern "C" {
#include <getopt.h>
}

weak_ptr<Kernel> KernelSingleton;

int main(int argc, char** argv) {
    char option;

    bool fullscreen_startup = false;

    while ((option = getopt(argc, argv, "f")) > 0) {
        if (option == 'f') {
            fullscreen_startup = true;
        }
    }

    cout << "|¯¯¯\\|¯¯¯|   o   |¯¯|    |¯¯|    |¯¯| '  /¯x¯¯\\" << endl;
    cout << "|       '| |¯¯¯| |  ¯¯\\' |  ¯¯\\' |  |__ | (\\__/" << endl;
    cout << "|___|\\___| |___| |__x_/° |__x_/° |_____| \\____\\" << endl;
    cout << "v" << VERSION_STRING << endl;

    auto kernel = make_shared<Kernel>(fullscreen_startup);

    KernelSingleton = kernel;

    kernel->loop();

    return 0;
}

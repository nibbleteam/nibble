#include <kernel/Kernel.hpp>

weak_ptr<Kernel> KernelSingleton;

int main(int, char**) {
    cout << "|¯¯¯\\|¯¯¯|   o   |¯¯|    |¯¯|    |¯¯| '  /¯x¯¯\\" << endl;
    cout << "|       '| |¯¯¯| |  ¯¯\\' |  ¯¯\\' |  |__ | (\\__/" << endl;
    cout << "|___|\\___| |___| |__x_/° |__x_/° |_____| \\____\\" << endl;
    cout << "v" << VERSION_STRING << endl;

    auto kernel = make_shared<Kernel>();

    KernelSingleton = kernel;

    kernel->loop();

    return 0;
}

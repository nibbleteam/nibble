#include <kernel/Kernel.hpp>

int main() {
	KernelSingleton = new Kernel();

	KernelSingleton->loop();

	delete KernelSingleton;

    return 0;
}

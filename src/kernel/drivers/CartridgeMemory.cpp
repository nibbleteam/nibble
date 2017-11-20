#include <kernel/drivers/CartridgeMemory.hpp>

CartridgeMemory::CartridgeMemory(Path& assets, const uint64_t addr) :
	address(addr) {

}

CartridgeMemory::~CartridgeMemory() {
}

uint64_t CartridgeMemory::write(const uint64_t, const uint8_t*, const uint64_t) {
	return 0;
}

uint64_t CartridgeMemory::read(uint64_t, uint8_t*, uint64_t) {
	return 0;
}

uint64_t CartridgeMemory::size() {
	return 0;
}

uint64_t CartridgeMemory::addr() {
	return address;
}
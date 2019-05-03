#include <devices/MidiController.hpp>

#include <vector>
#include <iostream>

#include <Specs.hpp>

using namespace std;

MidiController::MidiController(Memory& memory) {
    mem = memory.allocate(MIDI_CONTROLLER_QUEUE_SIZE, "Midi Controller");

    try {
        midi_in = make_unique<RtMidiIn>();
    } catch (RtMidiError &error) {
        error.printMessage();
    }

    auto ports = midi_in->getPortCount();

    if (ports > 0) {
        midi_in->openPort(ports-2);
    }
}

void MidiController::update() {
    vector<uint8_t> message;

    auto offset = 0;

    while (true) {
        // TODO: passar esse tempo para a memória também
        double _ = midi_in->getMessage(&message);

        if (message.size() > 0) {
            mem[offset++] = message.size();

            for (auto b=0;b<message.size();b++) {
                mem[offset++] = message[b];
            }
        } else {
            break;
        }
    }
}


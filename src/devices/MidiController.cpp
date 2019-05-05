#include <devices/MidiController.hpp>

#include <vector>
#include <iostream>

#include <Specs.hpp>

using namespace std;

MidiController::MidiController(Memory& memory): ok(true) {
    mem = memory.allocate(MIDI_CONTROLLER_QUEUE_SIZE, "Midi Controller");

    try {
        midi_in = make_unique<RtMidiIn>();
    } catch (RtMidiError &error) {
        ok = false;
        error.printMessage();
    }

    try {
        auto ports = midi_in->getPortCount();

        if (ports > 0) {
            midi_in->openPort(ports-1);
        }
    } catch (RtMidiError &error) {
        ok = false;
        error.printMessage();
    }
}

void MidiController::update() {
    vector<uint8_t> message;

    auto offset = 0;

    while (ok) {
        // TODO: passar esse tempo para a memória também
        double t = midi_in->getMessage(&message);

        if (message.size() > 0) {
            mem[offset++] = message.size();

            for (size_t b=0;b<message.size();b++) {
                mem[offset++] = message[b];
            }
        } else {
            break;
        }
    }
}


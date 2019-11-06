#ifndef NIBBLE_DISABLE_MIDI_CONTROLLER
#include <devices/MidiController.hpp>

#include <vector>
#include <iostream>

#include <Specs.hpp>

using namespace std;

MidiController::MidiController(Memory& memory): ok(true) {
    mem = memory.allocate(MIDI_CONTROLLER_QUEUE_SIZE, "Midi Controller");

    try {
        midi_in.push_back(make_unique<RtMidiIn>());

        // Mostra o Nibble em DAWs
        midi_in[0]->openVirtualPort("Nibble");
    } catch (RtMidiError &error) {
        ok = false;
        error.printMessage();
    }

    try {
        auto ports = midi_in[0]->getPortCount();

        if (ports > 1) {
            for (int p=ports-2;p>=0;p--) {
                midi_in.push_back(make_unique<RtMidiIn>());
            }
        }

        for (size_t p=0;p<ports;p++) {
            midi_in[p]->openPort(p);
            midi_in[p]->setClientName("Nibble");
        }
    } catch (RtMidiError &error) {
        ok = false;
        error.printMessage();
    }
}

void MidiController::update() {
    vector<uint8_t> message;

    auto offset = 0;

    for (auto &in: midi_in) {
        while (ok) {
            // TODO: passar esse tempo para a memória também
            double t = in->getMessage(&message);

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
}

#endif

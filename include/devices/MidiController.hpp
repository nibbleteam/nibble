#ifndef NIBBLE_DISABLE_MIDI_CONTROLLER
#ifndef NIBBLE_MIDI_H
#define NIBBLE_MIDI_H

#include <memory>
#include <vector>

#include <RtMidi.h> 
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

class MidiController: public Device {
    uint8_t *mem;

    vector<unique_ptr<RtMidiIn> > midi_in;

    bool ok;
public:
    MidiController(Memory&);

    void update();
};

#endif /* NIBBLE_MIDI_H */
#endif

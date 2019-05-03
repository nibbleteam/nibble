#ifndef NIBBLE_MIDI_H
#define NIBBLE_MIDI_H

#include <memory>

#include <RtMidi.h> 
#include <kernel/Memory.hpp>
#include <kernel/Device.hpp>

class MidiController: public Device {
    uint8_t *mem;

    unique_ptr<RtMidiIn> midi_in;
public:
    MidiController(Memory&);

    void update();
};

#endif /* NIBBLE_MIDI_H */

/*
 * Dispositivos são todos os periféricos ao kernel
 * do Nibble: GPU, APU, mouse, teclado etc
 */

#ifndef DEVICE_H
#define DEVICE_H

class Device {
public:
    virtual void startup() {};
    virtual void shutdown() {};
};

#endif /* DEVICE_H */

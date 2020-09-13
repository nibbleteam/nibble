[English](README.md) [Português](README.pt-BR.md)

# Nibble

A Fantasy Console, designed to run on *real* hardware and with a strong focus on
UX and design.

# Getting Started

First, you will need to download the emulator and SDK from the
[releases](https://github.com/nibbleteam/nibble/releases) page.

The macOS version probably needs some tinkering to run, because it's not notarized by Apple.

After extracting the `.zip` file you can run the `nibble` executable.

You will be greeted by the shell.

You can type the name of any software to start it.

<p align="center">
        <img style="image-rendering: pixelated;" src ="https://github.com/pongboy/nibble/raw/master/assets/screencaps/v0.2.0-cut.gif" width="800" height="480"/>
</p>

Be sure to check out the [documentation](https://docs.nibble.world).

# Compilling 

Nibble uses the CMake tool for compillation, there are two steps needed to compile it:

1. create a build directory and enter: `mkdir build && cd build`;
2. run cmake and make: `cmake .. && make`.

Those two steps will generate a `nibble` binary that can be run from inside the
`src` directory (this is needed because Nibble's OS is there):

`cd ../src && ../build/nibble`

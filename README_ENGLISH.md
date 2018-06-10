# Nibble

# What is it?

Nibble is a fantasy console designed to work in real hardware.

<p align="center">
        <img style="image-rendering: pixelated;" src ="https://github.com/pongboy/nibble/raw/master/assets/screencaps/shell-demo.gif" width="640" height="480"/>
</p>

# Code hierarchy

## Directories

* **[src](src/)**: Source code
* **[include](include/)**: Headers
* **[assets](assets/)**: Assets for carts
* **[extern](extern/)**: External libraries
* **[src/kernel/drivers/](src/kernel/drivers/)**: Device implementations
* **[src/apps/](src/apps/)**: System carts
* **[src/niblib/](src/niblib/)**: Library accessible by all Lua processes

## Files

* **[src/main.cpp](src/main.cpp)**: Entrypoint
* **[src/kernel/Kernel.cpp](src/kernel/Kernel.cpp)**: Process and memory control; Lua API
* **[include/kernel/Memory.hpp](include/kernel/Memory.hpp)**: API for devices apped to memory
* **[src/kernel/Process.cpp](src/kernel/Process.cpp)**: Load and executes carts
* **[src/kernel/drivers/VideoMemory.cpp](src/kernel/drivers/VideoMemory.cpp)**: Direct access to textures in memory

# Compiling

## Linux

1. Clone the project

        git clone https://github.com/pongboy/nibble

2. Enter to the directory and create a directory called `build`

        cd nibble
        git submodule update --init --recursive
        mkdir build

3. Install dependencies

        sudo apt install libx11-dev libxrandr-dev libgl-dev libudev-dev libopenal-dev libflac-dev libvorbis-dev libfreetype6-dev

4. Enter `build` and build

        cd build
        cmake ..
        make

## Windows (general)

Clone the code using your preferred method (Git GUI, Git Bash, Git CMD), remember to download the submodules using `git submodule update --init --recursive` that are for your platform

Install CMake

Open CMAKE GUI and select Nibble's directory in the first text field

In the second text field, emter Nibble's directory with `\build` at the end

Build.

### Windows (Code::Blocks)

Click in `configure` and choose `Code Blocks - MinGW Makefiles`.

Configure the building for the project

Open Code::Blocks and compile. Select "pongboy" as target and compile.

### Windows (Visual Studio)

Click `configure` and choose the builder according to your VS version

Configure the building for the project.

Open the project in VS and compile. Add "pongboy" to the solution as entrypoint and compile.

## macOS (XCode)

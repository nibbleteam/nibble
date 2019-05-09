cmake_minimum_required(VERSION 3.14)

project(nibble VERSION 0.1
               DESCRIPTION "A fantasy console designed to run on real hardware"
               LANGUAGES CXX C)

# Static only

set(BUILD_SHARED_LIBS FALSE)
set(PNG_SHARED FALSE)
set(PNG_STATIC TRUE)
set(PNG_TESTS FALSE)
set(LIBTYPE STATIC)
set(SDL_SHARED FALSE)
set(SDL_STATIC TRUE)

#
# PART 1 - Dependencies
#

find_library(LUAJIT libluajit.a lua51.lib subprojects/luajit/src)

add_subdirectory(subprojects/giflib)
add_subdirectory(subprojects/libpng)
add_subdirectory(subprojects/rtmidi)
add_subdirectory(subprojects/sdl2)
add_subdirectory(subprojects/zlib)

#
# PART 2 - Nibble
#

# 1. Add the source files and headers

set(SOURCE_FILES src/main.cpp
                 src/devices/MidiController.cpp
                 src/devices/Keyboard.cpp
                 src/devices/Controller.cpp
                 src/devices/Mouse.cpp
                 src/devices/Audio.cpp
                 src/devices/GPU.cpp
                 src/kernel/TriangleWave.cpp
                 src/kernel/FMSynthesizer.cpp
                 src/kernel/Envelope.cpp
                 src/kernel/Wave.cpp
                 src/kernel/Channel.cpp
                 src/kernel/Process.cpp
                 src/kernel/Memory.cpp
                 src/kernel/filesystem.cpp
                 src/kernel/mmap/Binary.cpp
                 src/kernel/mmap/Image.cpp
                 src/kernel/SquareWave.cpp
                 src/kernel/Kernel.cpp
                 src/kernel/SawWave.cpp)

set(INCLUDE_DIRS include/ subprojects/luajit/src)

# 2. Create an executable from the files

add_executable(nibble ${SOURCE_FILES})

# 3. Add include directories

target_include_directories(nibble PRIVATE ${INCLUDE_DIRS})

target_link_libraries(nibble zlibstatic ${LUAJIT} giflib png_static rtmidi SDL2-static SDL2main)

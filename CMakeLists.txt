cmake_minimum_required(VERSION 3.13)

project(nibble VERSION 0.1
               DESCRIPTION "A fantasy console designed to run on real hardware"
               LANGUAGES CXX C)

# Static only

set(BUILD_SHARED_LIBS FALSE)
set(RTMIDI_BUILD_STATIC_LIBS TRUE)
set(PNG_SHARED FALSE)
set(PNG_STATIC TRUE)
set(PNG_TESTS FALSE)
set(LIBTYPE STATIC)
set(SDL_SHARED FALSE)
set(SDL_STATIC TRUE)

#
# PART 1 - Dependencies
#

# zlib first since libpng depends on it

add_subdirectory(subprojects/zlib)

# adjust some details for libpng

set(ZLIB_LIBRARY zlibstatic)
set(ZLIB_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/subprojects/zlib)

set(SKIP_INSTALL_ALL TRUE)

add_subdirectory(subprojects/libpng)
add_subdirectory(subprojects/giflib)
add_subdirectory(subprojects/rtmidi)
add_subdirectory(subprojects/sdl2)

find_library(LUAJIT NAMES lua51.lib libluajit.a HINTS subprojects/luajit/src)

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

set(INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/include/
                 ${CMAKE_SOURCE_DIR}/subprojects/sdl2/include/
                 ${CMAKE_SOURCE_DIR}/subprojects/luajit/src/
                 ${CMAKE_SOURCE_DIR}/subprojects/giflib/
                 ${CMAKE_SOURCE_DIR}/subprojects/libpng/
                 ${ZLIB_INCLUDE_DIR})

# 2. Create an executable from the files

add_executable(nibble ${SOURCE_FILES})

# 3. Add include directories

target_include_directories(nibble PRIVATE ${INCLUDE_DIRS})

# 4. Link with the needed libraries

target_link_libraries(nibble zlibstatic
                             png_static
                             giflib
                             rtmidi
                             SDL2-static
                             SDL2main
                             ${LUAJIT})

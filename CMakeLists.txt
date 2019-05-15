cmake_minimum_required(VERSION 3.13)

project(nibble VERSION 0.1
               DESCRIPTION "A fantasy console designed to run on real hardware"
               LANGUAGES CXX C)

set(CMAKE_BUILD_TYPE Release)

if(MSVC)
    set(CMAKE_CXX_FLAGS_RELEASE "")
    set(CMAKE_CXX_FLAGS_DEBUG "")
    set(CMAKE_C_FLAGS_RELEASE "")
    set(CMAKE_C_FLAGS_DEBUG "")
else()
    set(CMAKE_CXX_FLAGS "-rdynamic")
endif()

# Static only

set(BUILD_SHARED_LIBS OFF)
set(RTMIDI_BUILD_STATIC_LIBS ON)
set(PNG_SHARED OFF)
set(PNG_STATIC ON)
set(PNG_TESTS OFF)
set(LIBTYPE STATIC)
set(SDL_SHARED OFF)
set(SDL_STATIC ON)
set(FORCE_STATIC_VCRT ON)

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
                 src/kernel/SawWave.cpp
                 include/devices/MidiController.hpp
                 include/devices/Keyboard.hpp
                 include/devices/Controller.hpp
                 include/devices/Mouse.hpp
                 include/devices/Audio.hpp
                 include/devices/GPU.hpp
                 include/kernel/TriangleWave.hpp
                 include/kernel/FMSynthesizer.hpp
                 include/kernel/Envelope.hpp
                 include/kernel/Wave.hpp
                 include/kernel/Channel.hpp
                 include/kernel/Process.hpp
                 include/kernel/Memory.hpp
                 include/kernel/filesystem.hpp
                 include/kernel/mmap/Binary.hpp
                 include/kernel/mmap/Image.hpp
                 include/kernel/SquareWave.hpp
                 include/kernel/Kernel.hpp
                 include/kernel/SawWave.hpp)

set(INCLUDE_DIRS ${CMAKE_SOURCE_DIR}/include/
                 ${CMAKE_SOURCE_DIR}/subprojects/sdl2/include/
                 ${CMAKE_SOURCE_DIR}/subprojects/luajit/src/
                 ${CMAKE_SOURCE_DIR}/subprojects/giflib/
                 ${CMAKE_SOURCE_DIR}/subprojects/libpng/
                 ${ZLIB_INCLUDE_DIR})

# 2. Create an executable from the files

if(WIN32)
    add_executable(nibble ${SOURCE_FILES})
else()
    add_executable(nibble ${SOURCE_FILES})
endif()

# 3. Add include directories

target_include_directories(nibble PRIVATE ${INCLUDE_DIRS})

# 4. Link with the needed libraries

if(MSVC)
    add_link_options("/MT")
endif()

target_link_libraries(nibble zlibstatic
                             png_static
                             giflib
                             rtmidi
                             SDL2-static
                             SDL2main
                             ${LUAJIT})

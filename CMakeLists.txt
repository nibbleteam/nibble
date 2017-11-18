cmake_minimum_required(VERSION 2.8)

project(pongboy)

# Output
set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR}/bin)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR})

# Source, headers, 3rd party and build
set(PROJECT_SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
set(PROJECT_HEADER_DIR ${CMAKE_SOURCE_DIR}/include)
set(PROJECT_EXTERN_DIR ${CMAKE_SOURCE_DIR}/extern)
set(PROJECT_BUILD_DIR ${CMAKE_SOURCE_DIR}/build)

# SFML and Lua
include(ExternalProject)

if (WIN32)
    add_definitions(-DSFML_STATIC)
endif (WIN32)

ExternalProject_Add(SFML
                SOURCE_DIR "${PROJECT_EXTERN_DIR}/sfml/"
                CMAKE_ARGS
                    "-DBUILD_SHARED_LIBS=false"
                    "-DCMAKE_INSTALL_PREFIX=${PROJECT_BUILD_DIR}")

ExternalProject_Add(LUA
                    SOURCE_DIR "${PROJECT_EXTERN_DIR}/lua/"
                    CMAKE_ARGS
                        "-DCMAKE_INSTALL_PREFIX=${PROJECT_BUILD_DIR}")

include_directories("${PROJECT_HEADER_DIR}")
include_directories("${PROJECT_BUILD_DIR}/include")
link_directories("${PROJECT_BUILD_DIR}/lib")

# Exe
add_executable(pongboy ${PROJECT_SOURCE_DIR}/main.cpp)
add_dependencies(pongboy SFML LUA)

# Linking
target_link_libraries(pongboy debug sfml-window-s-d optimized sfml-window-s)
target_link_libraries(pongboy debug sfml-graphics-s-d optimized sfml-graphics-s)
target_link_libraries(pongboy debug sfml-audio-s-d optimized sfml-audio-s)
target_link_libraries(pongboy debug sfml-network-s-d optimized sfml-network-s)
target_link_libraries(pongboy debug sfml-system-s-d optimized sfml-system-s)

if (UNIX)
    target_link_libraries(pongboy lualib pthread udev X11 Xrandr GL openal FLAC vorbis)
endif (UNIX)

if (WIN32)
    target_link_libraries(pongboy lualib opengl32 winmm FLAC vorbis)
endif (WIN32)

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

include_directories("${PROJECT_HEADER_DIR}")
include_directories("${PROJECT_BUILD_DIR}/include")
link_directories("${PROJECT_BUILD_DIR}/lib")

# SFML
include(ExternalProject)
ExternalProject_Add(SFML
                    SOURCE_DIR "${PROJECT_EXTERN_DIR}/sfml/"
                    CMAKE_ARGS
                        "-DBUILD_SHARED_LIBS=false"
                        "-DCMAKE_INSTALL_PREFIX=${PROJECT_BUILD_DIR}"
                    )

# Exe
add_executable(pongboy ${PROJECT_SOURCE_DIR}/main.cpp)

# Linking
target_link_libraries(pongboy sfml-window-s sfml-graphics-s sfml-audio-s sfml-network-s sfml-system-s)

if (UNIX)
    target_link_libraries(pongboy pthread udev X11 Xrandr GL openal FLAC vorbis)
endif (UNIX)


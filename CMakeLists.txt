cmake_minimum_required(VERSION 2.8)

project(nibble)
set(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "" FORCE)

# Warnings
if(MSVC)
  # Force to always compile with W4
  if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
    string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
  endif()
elseif(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
  # Update if necessary
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic")
endif()

# Use C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CXX_EXTENSIONS OFF)
if(MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++14")
endif(MSVC)

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

ExternalProject_Add(GIF
                    SOURCE_DIR "${PROJECT_EXTERN_DIR}/giflib/"
                    CMAKE_ARGS
                        "-DCMAKE_INSTALL_PREFIX=${PROJECT_BUILD_DIR}")

include_directories("${PROJECT_HEADER_DIR}")
include_directories("${PROJECT_BUILD_DIR}/include")
link_directories("${PROJECT_BUILD_DIR}/lib")

# Copy lua carts
add_custom_target(LuaCartsBin
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/apps ${CMAKE_BINARY_DIR}/apps
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/niblib ${CMAKE_BINARY_DIR}/niblib
)
add_custom_target(LuaCartsBuild
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/apps ${PROJECT_BUILD_DIR}/apps
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/niblib ${PROJECT_BUILD_DIR}/niblib
)

# Exe
add_executable(nibble
                ${PROJECT_SOURCE_DIR}/main.cpp
                ${PROJECT_SOURCE_DIR}/kernel/Kernel.cpp
                ${PROJECT_HEADER_DIR}/kernel/Kernel.hpp
                ${PROJECT_SOURCE_DIR}/kernel/Process.cpp
                ${PROJECT_HEADER_DIR}/kernel/Process.hpp
                ${PROJECT_SOURCE_DIR}/kernel/RenderBuffer.cpp
                ${PROJECT_HEADER_DIR}/kernel/RenderBuffer.hpp
                ${PROJECT_HEADER_DIR}/kernel/Memory.hpp
                ${PROJECT_HEADER_DIR}/kernel/drivers/CartridgeMemory.hpp
                ${PROJECT_SOURCE_DIR}/kernel/drivers/CartridgeMemory.cpp
                ${PROJECT_HEADER_DIR}/kernel/drivers/RAM.hpp
                ${PROJECT_SOURCE_DIR}/kernel/drivers/RAM.cpp
                ${PROJECT_HEADER_DIR}/kernel/drivers/RandomMemory.hpp
                ${PROJECT_SOURCE_DIR}/kernel/drivers/RandomMemory.cpp
                ${PROJECT_HEADER_DIR}/kernel/drivers/VideoMemory.hpp
                ${PROJECT_SOURCE_DIR}/kernel/drivers/VideoMemory.cpp
                ${PROJECT_HEADER_DIR}/kernel/drivers/GPU.hpp
                ${PROJECT_SOURCE_DIR}/kernel/drivers/GPU.cpp
                ${PROJECT_HEADER_DIR}/kernel/drivers/GPUCommandMemory.hpp
                ${PROJECT_SOURCE_DIR}/kernel/drivers/GPUCommandMemory.cpp
                ${PROJECT_HEADER_DIR}/kernel/drivers/PaletteMemory.hpp
                ${PROJECT_SOURCE_DIR}/kernel/drivers/PaletteMemory.cpp
                ${PROJECT_HEADER_DIR}/kernel/filesystem.hpp
                ${PROJECT_SOURCE_DIR}/kernel/filesystem.cpp
              )
add_dependencies(nibble SFML LUA GIF LuaCartsBin LuaCartsBuild)

if ( MSVC )
    set_target_properties(nibble PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR} )
    set_target_properties(nibble PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR} )
    set_target_properties(nibble PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR} )
	set_target_properties(nibble PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
endif ( MSVC )

# Linking
target_link_libraries(nibble debug sfml-window-s-d optimized sfml-window-s)
target_link_libraries(nibble debug sfml-graphics-s-d optimized sfml-graphics-s)
target_link_libraries(nibble debug sfml-audio-s-d optimized sfml-audio-s)
target_link_libraries(nibble debug sfml-network-s-d optimized sfml-network-s)
target_link_libraries(nibble debug sfml-system-s-d optimized sfml-system-s)
target_link_libraries(nibble lualib)
target_link_libraries(nibble giflib)

if (UNIX)
    target_link_libraries(nibble pthread udev X11 Xrandr GL openal FLAC vorbis)
endif (UNIX)

if (WIN32)
    target_link_libraries(nibble opengl32 winmm FLAC vorbis)
endif (WIN32)

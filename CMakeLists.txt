cmake_minimum_required(VERSION 2.8)

project(nibble)
set(CMAKE_CONFIGURATION_TYPES "Debug;Release" CACHE STRING "" FORCE)
set(BUILD_SHARED_LIBS OFF)

# Warnings
if(MSVC)
  # Force to always compile with W4
  if(CMAKE_CXX_FLAGS MATCHES "/W[0-4]")
    string(REGEX REPLACE "/W[0-4]" "/W4" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
  endif()
  # Full optimization for speed
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /O2")
elseif(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
  # Update if necessary
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pedantic -O3")
endif()

# Use C++14
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CXX_EXTENSIONS OFF)
if(MSVC)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /std:c++14 /MT")
endif(MSVC)

# Output
set(CMAKE_BINARY_DIR ${CMAKE_SOURCE_DIR}/bin)
set(EXECUTABLE_OUTPUT_PATH ${CMAKE_BINARY_DIR})

# Source, headers, 3rd party and build
set(PROJECT_SOURCE_DIR ${CMAKE_SOURCE_DIR}/src)
set(PROJECT_HEADER_DIR ${CMAKE_SOURCE_DIR}/include)
set(PROJECT_EXTERN_DIR ${CMAKE_SOURCE_DIR}/extern)
set(PROJECT_BUILD_DIR ${CMAKE_SOURCE_DIR}/build)

add_subdirectory("${PROJECT_EXTERN_DIR}/zlib/")
set(ZLIB_INCLUDE_DIR "${PROJECT_EXTERN_DIR}/zlib/" "${CMAKE_CURRENT_BINARY_DIR}/zlib_build")

if (UNIX)
    set(ZLIB_LIBRARY z)
else (UNIX)
    set(ZLIB_LIBRARY zlib)
endif (UNIX)

add_subdirectory("${PROJECT_EXTERN_DIR}/libpng/")
add_subdirectory("${PROJECT_EXTERN_DIR}/SDL2/")
add_subdirectory("${PROJECT_EXTERN_DIR}/lua/")
add_subdirectory("${PROJECT_EXTERN_DIR}/giflib/")

include_directories("${PROJECT_HEADER_DIR}")
include_directories("${PROJECT_BUILD_DIR}/include")
link_directories("${PROJECT_BUILD_DIR}/lib")

# Copy lua carts
add_custom_target(LuaCartsBin
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/apps ${CMAKE_BINARY_DIR}/apps
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/frameworks ${CMAKE_BINARY_DIR}/frameworks
)
add_custom_target(LuaCartsBuild
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/apps ${PROJECT_BUILD_DIR}/apps
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PROJECT_SOURCE_DIR}/frameworks ${PROJECT_BUILD_DIR}/frameworks
)

SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH "$ORIGIN/libraries")

# Exe
add_executable(nibble
                ${PROJECT_SOURCE_DIR}/main.cpp
                ${PROJECT_HEADER_DIR}/Icon.hpp
                ${PROJECT_SOURCE_DIR}/kernel/Kernel.cpp
                ${PROJECT_HEADER_DIR}/kernel/Kernel.hpp
                ${PROJECT_SOURCE_DIR}/kernel/Process.cpp
                ${PROJECT_HEADER_DIR}/kernel/Process.hpp
                ${PROJECT_SOURCE_DIR}/kernel/Memory.cpp
                ${PROJECT_HEADER_DIR}/kernel/Memory.hpp
                ${PROJECT_SOURCE_DIR}/kernel/Wave.cpp
                ${PROJECT_HEADER_DIR}/kernel/Wave.hpp
                ${PROJECT_SOURCE_DIR}/kernel/SquareWave.cpp
                ${PROJECT_HEADER_DIR}/kernel/SquareWave.hpp
                ${PROJECT_SOURCE_DIR}/kernel/SawWave.cpp
                ${PROJECT_HEADER_DIR}/kernel/SawWave.hpp
                ${PROJECT_SOURCE_DIR}/kernel/TriangleWave.cpp
                ${PROJECT_HEADER_DIR}/kernel/TriangleWave.hpp
                ${PROJECT_SOURCE_DIR}/kernel/FMSynthesizer.cpp
                ${PROJECT_HEADER_DIR}/kernel/FMSynthesizer.hpp
                ${PROJECT_SOURCE_DIR}/kernel/Envelope.cpp
                ${PROJECT_HEADER_DIR}/kernel/Envelope.hpp
                ${PROJECT_SOURCE_DIR}/kernel/Channel.cpp
                ${PROJECT_HEADER_DIR}/kernel/Channel.hpp
                ${PROJECT_SOURCE_DIR}/kernel/mmap/Image.cpp
                ${PROJECT_HEADER_DIR}/kernel/mmap/Image.hpp
                ${PROJECT_SOURCE_DIR}/kernel/mmap/Binary.cpp
                ${PROJECT_HEADER_DIR}/kernel/mmap/Binary.hpp
                ${PROJECT_SOURCE_DIR}/devices/Audio.cpp
                ${PROJECT_HEADER_DIR}/devices/Audio.hpp
                ${PROJECT_SOURCE_DIR}/devices/Controller.cpp
                ${PROJECT_HEADER_DIR}/devices/Controller.hpp
                ${PROJECT_SOURCE_DIR}/devices/Keyboard.cpp
                ${PROJECT_HEADER_DIR}/devices/Keyboard.hpp
                ${PROJECT_SOURCE_DIR}/devices/Mouse.cpp
                ${PROJECT_HEADER_DIR}/devices/Mouse.hpp
                ${PROJECT_SOURCE_DIR}/devices/GPU.cpp
                ${PROJECT_HEADER_DIR}/devices/GPU.hpp
                ${PROJECT_SOURCE_DIR}/kernel/filesystem.cpp
                ${PROJECT_HEADER_DIR}/kernel/filesystem.hpp
              )
add_dependencies(nibble LuaCartsBin LuaCartsBuild)

if ( MSVC )
    set_target_properties(nibble PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR} )
    set_target_properties(nibble PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR} )
    set_target_properties(nibble PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR} )
	set_target_properties(nibble PROPERTIES VS_DEBUGGER_WORKING_DIRECTORY ${CMAKE_BINARY_DIR})
endif ( MSVC )

if (WIN32)
    set_target_properties(nibble PROPERTIES WIN32_EXECUTABLE true)
endif (WIN32)

if (UNIX)
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
endif (UNIX)

target_link_libraries(nibble lualib)
target_link_libraries(nibble giflib)
target_link_libraries(nibble SDL2-static)
target_link_libraries(nibble png_static)
target_link_libraries(nibble zlibstatic)

if (UNIX)
    target_link_libraries(nibble pthread X11 sndio dl)
endif (UNIX)

if (WIN32)
    target_link_libraries(nibble winmm)
endif (WIN32)

project('nibble', 'cpp', default_options: ['b_vscrt=mt'])

add_global_link_arguments('-rdynamic', language: 'cpp')

luajit = subproject('luajit')
luajit_dep = luajit.get_variable('luajit_dep')

sdl2 = subproject('sdl2')
sdl2_dep = sdl2.get_variable('sdl2_dep')
sdl2main_dep = sdl2.get_variable('sdl2main_dep')

giflib = subproject('giflib')
giflib_dep = giflib.get_variable('giflib_dep')

libpng = subproject('libpng')
libpng_dep = libpng.get_variable('png_dep')

zlib = subproject('zlib')
zlib_dep = zlib.get_variable('zlib_dep')

compiler = meson.get_compiler('cpp')

imm32_dep = compiler.find_library('imm32', required: false)
version_dep = compiler.find_library('version', required: false)
winmm_dep = compiler.find_library('winmm', required: false)

headers = include_directories('include')

sources = [
  'src/main.cpp',
  'src/devices/Keyboard.cpp',
  'src/devices/Controller.cpp',
  'src/devices/Mouse.cpp',
  'src/devices/Audio.cpp',
  'src/devices/GPU.cpp',
  'src/kernel/TriangleWave.cpp',
  'src/kernel/FMSynthesizer.cpp',
  'src/kernel/Envelope.cpp',
  'src/kernel/Wave.cpp',
  'src/kernel/Channel.cpp',
  'src/kernel/Process.cpp',
  'src/kernel/Memory.cpp',
  'src/kernel/filesystem.cpp',
  'src/kernel/mmap/Binary.cpp',
  'src/kernel/mmap/Image.cpp',
  'src/kernel/SquareWave.cpp',
  'src/kernel/Kernel.cpp',
  'src/kernel/SawWave.cpp'
]

executable('nibble',
           sources,
           include_directories: headers,
           gui_app: true,
           dependencies: [luajit_dep, sdl2_dep, sdl2main_dep, libpng_dep, giflib_dep, zlib_dep, imm32_dep, version_dep, winmm_dep])

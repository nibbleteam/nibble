project('rtmidi', 'cpp')

compiler = meson.get_compiler('cpp')

jack_dep = compiler.find_library('jack', required: false)
alsa_dep = compiler.find_library('asound', required: false)
winmm_dep = compiler.find_library('winmm', required: false)

core_services_dep compiler.find_library('CoreServices', required: false)
core_audio_dep compiler.find_library('CoreAudio', required: false)
core_midi_dep compiler.find_library('CoreMIDI', required: false)
core_foundation_dep compiler.find_library('CoreFoundation', required: false)

api_defs = []
api_list = []

if alsa_dep.found()
  api_defs += '-D__LINUX_ALSA__'
  api_list += 'alsa'
elif jack_dep.found()
  api_defs += '-D__UNIX_JACK__'
  api_list += 'jack'
elif winmm_dep.found()
  api_defs += '-D__WINDOWS_MM__'
  api_list += 'winmm'
elif core_audio_dep.found() 
  api_defs += '-D__MACOSX_CORE__'
  api_list += 'coremidi'
endif

add_project_arguments(api_defs, language: 'cpp')

headers = include_directories('./')

sources = [
  'RtMidi.cpp',
  'rtmidi_c.cpp'
]

rtmidi_static = static_library('rtmidi',
  sources,
  dependencies: [
    jack_dep,
    alsa_dep
  ],
  include_directories: headers
)

rtmidi_dep = declare_dependency(
  include_directories: headers,
  link_with: rtmidi_static
)

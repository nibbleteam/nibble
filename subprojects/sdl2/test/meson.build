if host_machine.system() == 'windows'
  exe_link_args = ['/SUBSYSTEM:WINDOWS']
else
  exe_link_args = []
endif

test('testfile', executable('testfile', 'testfile.c',
  link_with : sdl2main,
  dependencies : sdl2_dep,
  link_args : exe_link_args,
  gui_app:true))

if gl_dep.found()
  executable('testgl2', 'testgl2.c',
  c_args : ['-DHAVE_OPENGL=1'],
  dependencies : [sdl2main_dep, sdl2_dep],
  link_args : exe_link_args,
  gui_app : true)
endif

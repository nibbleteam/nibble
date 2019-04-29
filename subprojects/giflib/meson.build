project('giflib', 'c')

giflib = static_library('giflib', 'dgif_lib.c', 'egif_lib.c', 'gifalloc.c', 'gif_err.c', 'gif_font.c', 'gif_hash.c', 'openbsd-reallocarray.c', 'quantize.c')

giflib_dep = declare_dependency(
  include_directories: include_directories('.'),
  link_with: giflib
)

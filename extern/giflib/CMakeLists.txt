cmake_minimum_required (VERSION 2.8)
project (giflib)

add_library (giflib STATIC dgif_lib.c egif_lib.c gifalloc.c gif_err.c gif_font.c gif_hash.c openbsd-reallocarray.c quantize.c)

include_directories(.)

install(FILES gif_hash.h gif_lib.h gif_lib_private.h DESTINATION include)
install(TARGETS giflib DESTINATION lib)

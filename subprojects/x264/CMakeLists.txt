cmake_minimum_required (VERSION 2.8)
project (x264)

add_library (x264 STATIC common/threadpool.c encoder/api.c common/osdep.c common/base.c common/cpu.c common/tables.c common/mc.c common/predict.c common/pixel.c common/macroblock.c common/frame.c common/dct.c common/cabac.c common/common.c common/rectangle.c common/set.c common/quant.c common/deblock.c common/vlc.c common/mvpred.c common/bitstream.c encoder/analyse.c encoder/me.c encoder/ratecontrol.c encoder/set.c encoder/macroblock.c encoder/cabac.c encoder/cavlc.c encoder/encoder.c encoder/lookahead.c)

include_directories(.)
include_directories(./common)

install(FILES x264.h DESTINATION include)
install(TARGETS x264 DESTINATION lib)

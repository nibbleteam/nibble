cmake_minimum_required (VERSION 2.8)
project (lualib)

if(WIN32)
        add_definitions( -D_CRT_SECURE_NO_WARNINGS )
endif(WIN32)

add_library (lualib STATIC lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c ltm.c lundump.c lvm.c lzio.c lauxlib.c lbaselib.c lbitlib.c lcorolib.c ldblib.c liolib.c lmathlib.c loslib.c lstrlib.c ltablib.c loadlib.c linit.c)

install(FILES lapi.h lauxlib.h lcode.h lctype.h ldebug.h ldo.h lfunc.h lgc.h llex.h llimits.h lmem.h lobject.h lopcodes.h DESTINATION include)
install(FILES lparser.h lprefix.h lstate.h lstring.h ltable.h ltests.h ltm.h luaconf.h lua.h lualib.h lundump.h lvm.h lzio.h DESTINATION include)
install(TARGETS lualib DESTINATION lib)

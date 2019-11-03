#define HAVE_WIN32THREAD 0
#define ARCH_X86_64 1
#define STACK_ALIGNMENT 64
#define HAVE_CPU_COUNT 1
#define HAVE_THREAD 1
#define HAVE_LOG2F 1
#define HAVE_STRTOK_R 1
#define HAVE_CLOCK_GETTIME 1
#define HAVE_MMAP 0
#define HAVE_THP 0
#define HAVE_AVS 1
#define USE_AVXSYNTH 0
#define HAVE_VECTOREXT 0
#define fseek fseeko
#define ftell ftello
#define HAVE_BITDEPTH8 1
#define HAVE_BITDEPTH10 1
#define HAVE_GPL 1
#define HAVE_INTERLACED 1
#define HAVE_ALTIVEC 0
#define HAVE_ALTIVEC_H 0
#define HAVE_MMX 0
#define HAVE_ARMV6 0
#define HAVE_ARMV6T2 0
#define HAVE_NEON 0
#define HAVE_BEOSTHREAD 0
#define HAVE_SWSCALE 0
#define HAVE_LAVF 0
#define HAVE_FFMS 0
#define HAVE_GPAC 0
#define HAVE_OPENCL 0
#define HAVE_LSMASH 0
#define HAVE_X86_INLINE_ASM 0
#define HAVE_AS_FUNC 0
#define HAVE_INTEL_DISPATCHER 0
#define HAVE_MSA 0
#define HAVE_WINRT 0
#define HAVE_VSX 0
#define HAVE_ARM_INLINE_ASM 0

#define BIT_DEPTH 8
#define CPU_COUNT(x) 1

#ifdef linux
#define HAVE_MALLOC_H 1
#define SYS_LINUX 1
#define HAVE_POSIXTHREAD 1
#endif

#ifdef _WIN32
#define SYS_WINDOWS 1
#define fseek _fseeki64
#define ftell _ftelli64
#endif


#ifndef _GPU_OPENGL_H_
#define _GPU_OPENGL_H_

// Referência: https://github.com/AugustoRuiz/sdl2glsl/blob/master/src/main.cpp
#include <SDL.h>
#include <SDL_opengl.h>
#include <SDL_opengl_glext.h>

void check_opengl();
SDL_Renderer* create_opengl_renderer(SDL_Window*);
GLuint create_opengl_shader();
void use_glsl_shader(GLuint);

#endif // _GPU_OPENGL_H_

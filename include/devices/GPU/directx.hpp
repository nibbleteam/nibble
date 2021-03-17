#ifndef _GPU_DIRECTX_H_
#define _GPU_DIRECTX_H_

#include <SDL.h>
#include <d3d9.h>

SDL_Renderer* create_directx_renderer(SDL_Window*);
void compile_directx_shader(SDL_Renderer*);

#endif // _GPU_DIRECTX_H_

#ifndef _GPU_DIRECTX_H_
#define _GPU_DIRECTX_H_

#include <SDL.h>
#include <d3d9.h>

SDL_Renderer* create_directx_renderer(SDL_Window*);
IDirect3DPixelShader9 **create_directx_shader(SDL_Renderer*);
void use_hlsl_shader(SDL_Renderer*, IDirect3DPixelShader9 **);

#endif // _GPU_DIRECTX_H_

#ifndef _GPU_DIRECTX_H_
#define _GPU_DIRECTX_H_

#include <SDL.h>
#include <D3DX9Shader.h>
#include <D3DX9Mesh.h>

SDL_Renderer* create_directx_renderer(SDL_Window*);
HRESULT compile_directx_shader();

#endif // _GPU_DIRECTX_H_

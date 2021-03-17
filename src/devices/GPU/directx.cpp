#include <devices/GPU/directx.hpp>

SDL_Renderer* create_directx_renderer(SDL_Window* window) {
  SDL_SetHint(SDL_HINT_RENDER_DRIVER, "direct3d");

  return SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
}

#ifdef _WIN32

#include <devices/GPU/directx.hpp>

#include <iostream>

using namespace std;

const static string dx_expand_colors_shader = R"(

)";

SDL_Renderer* create_directx_renderer(SDL_Window* window) {
  SDL_SetHint(SDL_HINT_RENDER_DRIVER, "direct3d");

  return SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
}

// TODO: do we need this?
// void compile_hlsl_program(const string &pixel_source) {
//   // FIXME: D3DXGetPixelShaderProfile(/* Get DirectX device */) could be used
//   // but it would mean we need to find the DirectX device used by the SDL
//   // renderer.
//   //
//   // That can be found in renderer->driverdata->device.
//
//   const auto no_flags = 0;
//
//   const LPD3DXBUFFER pixel_shader;
//   const LPD3DXBUFFER errors;
//
//   D3DXCreateBuffer(4096, pixel_shader);
//   D3DXCreateBuffer(8192, errors);
//
//   assert(D3D_OK == D3DXCompileShader(pixel_source.c_str(),
//                                      pixel_source.size(),
//                                      nullptr,
//                                      nullptr,
//                                      "main",
//                                      "ps_1_1"
//                                      no_flags,
//                                      pixel_shader,
//                                      errors,
//                                      nullptr));
//
//   cout << pixel_shader << endl;
//   cout << errors << endl;
// }

void compile_directx_shader(SDL_Renderer* renderer) {
  IDirect3DDevice9* device = renderer->driverdata->device;
  D3D9_Shader shader, IDirect3DPixelShader9 **pixelShader;

  assert(D3D_OK == IDirect3DDevice9_CreatePixelShader(device,
                                                      D3D9_shaders[shader],
                                                      pixelShader));

  // ...
}

#endif

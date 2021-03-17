#ifdef _WIN32

#include <devices/GPU/directx.hpp>
#include <windows.h>

#include <iostream>

using namespace std;

// Vem de: SDL_render_d3d.c
typedef struct
{
    SDL_Rect viewport;
    SDL_bool viewport_dirty;
    SDL_Texture *texture;
    SDL_BlendMode blend;
    SDL_bool cliprect_enabled;
    SDL_bool cliprect_enabled_dirty;
    SDL_Rect cliprect;
    SDL_bool cliprect_dirty;
    SDL_bool is_copy_ex;
    LPDIRECT3DPIXELSHADER9 shader;
} D3D_DrawStateCache;

typedef struct
{
    void* d3dDLL;
    IDirect3D9 *d3d;
    IDirect3DDevice9 *device;
    UINT adapter;
    D3DPRESENT_PARAMETERS pparams;
    SDL_bool updateSize;
    SDL_bool beginScene;
    SDL_bool enableSeparateAlphaBlend;
    D3DTEXTUREFILTERTYPE scaleMode[8];
    IDirect3DSurface9 *defaultRenderTarget;
    IDirect3DSurface9 *currentRenderTarget;
    void* d3dxDLL;
    LPDIRECT3DPIXELSHADER9 shaders[3];
    LPDIRECT3DVERTEXBUFFER9 vertexBuffers[8];
    size_t vertexBufferSize[8];
    int currentVertexBuffer;
    SDL_bool reportedVboProblem;
    D3D_DrawStateCache drawstate;
} D3D_RenderData;

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

static const DWORD test_shader[] = {
    0xffff0200, 0x0044fffe, 0x42415443, 0x0000001c, 0x000000d7, 0xffff0200,
    0x00000003, 0x0000001c, 0x00000100, 0x000000d0, 0x00000058, 0x00010003,
    0x00000001, 0x00000070, 0x00000000, 0x00000080, 0x00020003, 0x00000001,
    0x00000098, 0x00000000, 0x000000a8, 0x00000003, 0x00000001, 0x000000c0,
    0x00000000, 0x53656874, 0x6c706d61, 0x742b7265, 0x65546568, 0x72757478,
    0xab005565, 0x00070004, 0x00040001, 0x00000001, 0x00000000, 0x53656874,
    0x6c706d61, 0x742b7265, 0x65546568, 0x72757478, 0xab005665, 0x00070004,
    0x00040001, 0x00000001, 0x00000000, 0x53656874, 0x6c706d61, 0x742b7265,
    0x65546568, 0x72757478, 0xab005965, 0x00070004, 0x00040001, 0x00000001,
    0x00000000, 0x325f7370, 0x4d00305f, 0x6f726369, 0x74666f73, 0x29522820,
    0x534c4820, 0x6853204c, 0x72656461, 0x6d6f4320, 0x656c6970, 0x2e362072,
    0x36392e33, 0x312e3030, 0x34383336, 0xababab00, 0x05000051, 0xa00f0000,
    0x00000000, 0xbf008081, 0xbf008081, 0x3f800000, 0x05000051, 0xa00f0001,
    0x3f800000, 0x00000000, 0x3fb374bc, 0x00000000, 0x05000051, 0xa00f0002,
    0x3f800000, 0xbeb02de0, 0xbf36cf42, 0x00000000, 0x05000051, 0xa00f0003,
    0x3f800000, 0x3fe2d0e5, 0x00000000, 0x00000000, 0x0200001f, 0x80000000,
    0xb0030000, 0x0200001f, 0x80000000, 0x900f0000, 0x0200001f, 0x90000000,
    0xa00f0800, 0x0200001f, 0x90000000, 0xa00f0801, 0x0200001f, 0x90000000,
    0xa00f0802, 0x03000042, 0x800f0000, 0xb0e40000, 0xa0e40800, 0x03000042,
    0x800f0001, 0xb0e40000, 0xa0e40801, 0x03000042, 0x800f0002, 0xb0e40000,
    0xa0e40802, 0x02000001, 0x80020000, 0x80000001, 0x02000001, 0x80040000,
    0x80000002, 0x03000002, 0x80070000, 0x80e40000, 0xa0e40000, 0x03000008,
    0x80010001, 0x80e40000, 0xa0e40001, 0x03000008, 0x80020001, 0x80e40000,
    0xa0e40002, 0x0400005a, 0x80040001, 0x80e40000, 0xa0e40003, 0xa0aa0003,
    0x02000001, 0x80080001, 0xa0ff0000, 0x03000005, 0x800f0000, 0x80e40001,
    0x90e40000, 0x02000001, 0x800f0800, 0x80e40000, 0x0000ffff
};

void compile_directx_shader(SDL_Renderer* renderer) {
  IDirect3DDevice9* device = ((D3D_RenderData*)renderer->driverdata)->device;
  IDirect3DPixelShader9 **pixelShader;

  assert(D3D_OK == IDirect3DDevice9_CreatePixelShader(device,
                                                      test_shader,
                                                      pixelShader));

  // ...
}

#endif

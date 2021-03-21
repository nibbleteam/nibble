#ifdef _WIN32

#include <SDL_sysrender.h>
#include <devices/GPU/directx.hpp>
#include <windows.h>
#include <cassert>

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

static const DWORD passthrough_shader[] = {
    0xffff0200, 0x0022fffe, 0x42415443, 0x0000001c, 0x00000053, 0xffff0200,
    0x00000001, 0x0000001c, 0x20000100, 0x0000004c, 0x00000030, 0x00000003,
    0x00020001, 0x0000003c, 0x00000000, 0x5f786574, 0x706d6173, 0x0072656c,
    0x000c0004, 0x00010001, 0x00000001, 0x00000000, 0x325f7370, 0x4d00305f,
    0x6f726369, 0x74666f73, 0x29522820, 0x534c4820, 0x6853204c, 0x72656461,
    0x6d6f4320, 0x656c6970, 0x2e392072, 0x392e3232, 0x322e3934, 0x00383432,
    0x0200001f, 0x80000000, 0xb0030000, 0x0200001f, 0x90000000, 0xa00f0800,
    0x03000042, 0x800f0000, 0xb0e40000, 0xa0e40800, 0x02000001, 0x800f0800,
    0x80e40000, 0x0000ffff
};

IDirect3DPixelShader9 *create_directx_shader(SDL_Renderer* renderer) {
    IDirect3DDevice9* device = ((D3D_RenderData*)renderer->driverdata)->device;
    IDirect3DPixelShader9 **shader;

    assert(D3D_OK == IDirect3DDevice9_CreatePixelShader(device, passthrough_shader, shader));

    return *shader;
}

void use_hlsl_shader(SDL_Renderer* renderer, IDirect3DPixelShader9 *shader) {
    IDirect3DDevice9* device = ((D3D_RenderData*)renderer->driverdata)->device;

    assert(D3D_OK == IDirect3DDevice9_SetPixelShader(device, shader));
}

#endif

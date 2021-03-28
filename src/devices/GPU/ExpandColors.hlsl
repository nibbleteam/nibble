#define SCREEN_TEXTURE_PITCH 400
#define SCREEN_TEXTURE_W 100
#define SCREEN_TEXTURE_H 256

sampler2D screen_texture: register(S0) = sampler_state {
    MinFilter = None;
    MagFilter = None;
    MipFilter = None;
};

float2 index_to_position(int i, int w, int h) {
    return float2(
        (float(i%w)+0.5)/float(w),
        (float(i/w)+0.5)/float(h)
    );
}

int subpixel_value(float4 pixel, int subpixel) {
    return int(floor(pixel[3-subpixel%4]*256.0));
}

int linear_access(sampler2D tex, int index) {
    float2 position = index_to_position(index/4, SCREEN_TEXTURE_W, SCREEN_TEXTURE_H);
    float4 pixel = tex2D(tex, position);

    return subpixel_value(pixel, index);
}

int palette_colmap_2(int i) {
    return linear_access(screen_texture, SCREEN_TEXTURE_PITCH*240+640+i);
}

float4 main(float2 uv: TEXCOORD): SV_Target {
    int x = int(uv.x*SCREEN_TEXTURE_W);
    int y = int(uv.y*SCREEN_TEXTURE_H);

    float2 pixel_position = float2((float(x)+0.5)/SCREEN_TEXTURE_W,
                                   (float(y)+0.5)/SCREEN_TEXTURE_H);
    float4 pixel = tex2D(screen_texture, pixel_position);

    int raw_index = subpixel_value(pixel, int(uv.x*SCREEN_TEXTURE_PITCH));
    int paletted_index = palette_colmap_2(raw_index);

    float2 color_position = index_to_position(SCREEN_TEXTURE_W*240+paletted_index,
                                              SCREEN_TEXTURE_W, SCREEN_TEXTURE_H);
    float4 color = tex2D(screen_texture, color_position);

    return float4(color.a, color.b, color.g, color.r);
}

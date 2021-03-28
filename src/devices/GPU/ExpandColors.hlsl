#define SCREEN_TEXTURE_PITCH 400
#define SCREEN_TEXTURE_W 100
#define SCREEN_TEXTURE_H 256

sampler2D screen_texture: register(S0);

float2 index_to_position(int i, int w, int h) {
    return float2(
        (float(i%w)+0.5)/float(w),
        (float(i/w)+0.5)/float(h)
    );
}

int subpixel_value(float4 pixel, int subpixel) {
    if (subpixel == 0) {
        return int(pixel.a*255.0);
    } else if (subpixel == 1) {
        return int(pixel.b*255.0);
    } else if (subpixel == 2) {
        return int(pixel.g*255.0);
    } else if (subpixel == 3) {
        return int(pixel.r*255.0);
    } else {
        return 0;
    }
}

int subpixel_for_column(float4 pixel, int column) {
    return subpixel_value(pixel, column%4);
}

int linear_access(sampler2D tex, int index) {
    float2 position = index_to_position(index/4, SCREEN_TEXTURE_W, SCREEN_TEXTURE_H);
    float4 pixel = tex2D(tex, position);

    return subpixel_value(pixel, index%4);
}

int palette_colmap_2(int i) {
    return linear_access(screen_texture,
                         SCREEN_TEXTURE_PITCH*240+640+i);
}

float4 main(float2 uv: TEXCOORD): SV_Target {
    int x = int(uv.x*SCREEN_TEXTURE_W);
    int y = int(uv.y*SCREEN_TEXTURE_H);

    float2 pixel_position = float2((float(x)+0.5)/SCREEN_TEXTURE_W,
                                   (float(y)+0.5)/SCREEN_TEXTURE_H);
	float4 pixel = tex2D(screen_texture, pixel_position);

    int raw_index = subpixel_for_column(pixel, int(uv.x*SCREEN_TEXTURE_PITCH));
    int paletted_index = palette_colmap_2(raw_index);

    float2 color_position = index_to_position(SCREEN_TEXTURE_W*240+paletted_index,
                                              SCREEN_TEXTURE_W, SCREEN_TEXTURE_H);
    float4 color = tex2D(screen_texture, color_position);

    return float4(color.a, color.b, color.g, color.r);
}

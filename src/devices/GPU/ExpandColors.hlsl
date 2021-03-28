#define mod(x, y) (x - y * floor(x / y))

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
    float value;

    if (subpixel == 0) {
        value = pixel.a;
    } else if (subpixel == 1) {
        value = pixel.b;
    } else if (subpixel == 2) {
        value = pixel.g;
    } else if (subpixel == 3) {
        value = pixel.r;
    }

    return int(value*255.0);
}

int subpixel_for_column(float4 pixel, int column) {
    return subpixel_value(pixel, column%4);
}

int linear_access(sampler2D tex, int w, int h, int index) {
    float2 position = index_to_position(index, w, h);
    float4 pixel = tex2D(tex, position);

    return subpixel_value(pixel, int(position.x*w)%4);
}

int palette_colmap_2(int i) {
    return linear_access(screen_texture,
                         SCREEN_TEXTURE_PITCH, SCREEN_TEXTURE_H,
                         SCREEN_TEXTURE_PITCH*240+640+i%SCREEN_TEXTURE_W);
}

float4 main(float2 uv: TEXCOORD): SV_Target {
    int x = int(uv.x*SCREEN_TEXTURE_W);
    int y = int(uv.y*SCREEN_TEXTURE_H);

    float2 pixel_position = float2((float(x)+0.5)/SCREEN_TEXTURE_W,
                                   (float(y)+0.5)/SCREEN_TEXTURE_H);
	float4 pixel = tex2D(screen_texture, pixel_position);

    int raw_index = subpixel_for_column(pixel, int(uv.x*SCREEN_TEXTURE_W));
    int paletted_index = palette_colmap_2(raw_index);

    float2 color_position = index_to_position(SCREEN_TEXTURE_PITCH*240+paletted_index*4,
                                              SCREEN_TEXTURE_PITCH, SCREEN_TEXTURE_H);
    float4 color = tex2D(screen_texture, color_position);

    return float4(color.a, color.b, color.g, color.r);
}

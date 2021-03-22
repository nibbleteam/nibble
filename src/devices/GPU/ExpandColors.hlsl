sampler2D screen_texture: register(S0);

float2 index_to_position(float i, float w, float h) {
    return float2(
        (floor(i%w)+0.5)/w,
        (floor(i/w)+0.5)/h
    );
}

float subpixel_value(float4 pixel, int subpixel) {
    if (subpixel == 0) {
        return pixel.a;
    } else if (subpixel == 1) {
        return pixel.b;
    } else if (subpixel == 2) {
        return pixel.g;
    } else if (subpixel == 3) {
        return pixel.r;
    } else {
        return 0;
    }
}

float subpixel_for_column(float4 pixel, float column) {
    return subpixel_value(pixel, int(column%4.0))*255.0;
}

float linear_access(sampler2D tex, float w, float h, float index) {
    float2 position = index_to_position(index, w, h);
    float4 pixel = tex2D(tex, position);

    return subpixel_value(pixel, int((position.x*w)%4.0))*255.0;
}

float palette_colmap_2(float i) {
    return linear_access(screen_texture, 400.0, 256.0, 400.0*240.0+640.0+(i%128.0));
}

float4 main(float2 uv: TEXCOORD): SV_Target {
    int x = int(uv.x*100.0);
    int y = int(uv.y*256.0);

    float2 pixel_position = float2((float(x)+0.5)/100.0, (float(y)+0.5)/256.0);
	float4 pixel = tex2D(screen_texture, pixel_position);

    float raw_index = subpixel_for_column(pixel, floor(uv.x*400.0));
    float paletted_index = palette_colmap_2(raw_index);

    float2 color_position = index_to_position(400.0*240.0+floor(paletted_index*4.0), 400.0, 256.0);
    float4 color = tex2D(screen_texture, color_position);

    return float4(color.a, color.g, color.b, color.r);
}

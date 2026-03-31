shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform float color_depth : hint_range(1.0, 64.0) = 24.0;
uniform float dither_intensity : hint_range(0.0, 0.1) = 0.01; // Controla qué tan marcados son los puntos
uniform bool use_dither = true;

// Matriz de Bayer 8x8 para un granulado mucho más fino y profesional
float dither8x8(ivec2 p) {
    int x = p.x % 8;
    int y = p.y % 8;
    const int m[64] = int[](
         0, 32,  8, 40,  2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26,
        12, 44,  4, 36, 14, 46,  6, 38,
        60, 28, 52, 20, 62, 30, 54, 22,
         3, 35, 11, 43,  1, 33,  9, 41,
        51, 19, 59, 27, 49, 17, 57, 25,
        15, 47,  7, 39, 13, 45,  5, 37,
        63, 31, 55, 23, 61, 29, 53, 21
    );
    return float(m[y * 8 + x]) / 64.0 - 0.5;
}

void fragment() {
    vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
    vec3 rgb = screen_color.rgb;
    
    if (use_dither) {
        // FRAGCOORD usa la resolución real de la ventana
        float noise = dither8x8(ivec2(FRAGCOORD.xy));
        rgb += noise * dither_intensity;
    }
    
    // Posterización: reduce la paleta de colores
    rgb = floor(rgb * color_depth) / color_depth;
    
    COLOR = vec4(rgb, screen_color.a);
}
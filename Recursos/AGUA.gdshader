shader_type spatial;

uniform vec4 water_color : source_color = vec4(0.2, 0.6, 0.8, 1.0);
uniform float wave_speed = 0.3;
uniform float wave_strength = 0.05;

void fragment() {
    vec2 uv = UV;
    uv.y += TIME * wave_speed;

    float wave = sin(uv.x * 10.0 + TIME) * wave_strength;

    ALBEDO = water_color.rgb + wave;
}
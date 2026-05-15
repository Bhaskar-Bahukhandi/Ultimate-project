shader_type canvas_item;

// Advanced Glitch Effect - Multiple glitch types
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.5;
uniform float time_offset = 0.0;
uniform float block_size = 50.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Random noise function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = SCREEN_UV;
    float time = TIME + time_offset;
    
    // Digital block displacement
    vec2 block_uv = floor(uv * block_size) / block_size;
    float block_rand = random(block_uv + floor(time * 5.0));
    
    if (block_rand < glitch_strength * 0.3) {
        uv.x += (random(block_uv + vec2(time, 0.0)) - 0.5) * 0.1 * glitch_strength;
    }
    
    // RGB split
    vec2 offset = vec2(sin(time * 10.0 + uv.y * 20.0) * 0.01 * glitch_strength, 0.0);
    vec4 color;
    color.r = texture(screen_texture, uv + offset).r;
    color.g = texture(screen_texture, uv).g;
    color.b = texture(screen_texture, uv - offset).b;
    color.a = 1.0;
    
    // Horizontal line glitches
    float line = floor(uv.y * 100.0);
    float line_rand = random(vec2(line, floor(time * 20.0)));
    if (line_rand < glitch_strength * 0.1) {
        uv.x += (line_rand - 0.5) * 0.2;
        color = texture(screen_texture, uv);
    }
    
    // Random noise overlay
    float noise = random(uv + time * 0.1);
    color.rgb += (noise - 0.5) * 0.1 * glitch_strength;
    
    // Interlacing effect
    if (mod(floor(uv.y * 720.0), 2.0) < 1.0) {
        color.rgb *= 0.95;
    }
    
    COLOR = color;
}

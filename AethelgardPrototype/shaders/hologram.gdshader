shader_type canvas_item;

// Hologram/Projection Effect
uniform vec4 hologram_color : source_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform float scan_speed = 2.0;
uniform float flicker_speed = 10.0;
uniform float line_density = 100.0;
uniform float distortion = 0.05;

void fragment() {
    vec2 uv = UV;
    float time = TIME;
    
    // Scanline movement
    float scan = sin((uv.y + time * scan_speed) * line_density) * 0.5 + 0.5;
    
    // Horizontal distortion
    uv.x += sin(uv.y * 20.0 + time * 3.0) * distortion;
    
    // Get texture
    vec4 tex = texture(TEXTURE, uv);
    
    // Flicker effect
    float flicker = sin(time * flicker_speed) * 0.1 + 0.9;
    
    // Apply hologram effect
    vec3 final_color = tex.rgb * hologram_color.rgb;
    final_color *= scan * flicker;
    
    // Edge glow
    float edge = 1.0 - abs(uv.y - 0.5) * 2.0;
    edge = pow(edge, 3.0);
    final_color += hologram_color.rgb * edge * 0.3;
    
    COLOR = vec4(final_color, tex.a * flicker);
}

shader_type canvas_item;

// Atmospheric lighting for 2D scenes
uniform vec4 light_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform vec2 light_position = vec2(0.5, 0.3);
uniform float light_intensity = 1.5;
uniform float ambient = 0.3;
uniform float fog_density = 0.2;
uniform vec4 fog_color : source_color = vec4(0.5, 0.6, 0.8, 1.0);

void fragment() {
    vec2 uv = UV;
    vec4 tex = texture(TEXTURE, uv);
    
    // Distance-based lighting
    float dist = distance(uv, light_position);
    float light = light_intensity / (1.0 + dist * 3.0);
    light = clamp(light + ambient, 0.0, 1.0);
    
    // Apply lighting
    vec3 lit_color = tex.rgb * light_color.rgb * light;
    
    // Atmospheric fog
    float fog = fog_density * dist;
    fog = clamp(fog, 0.0, 1.0);
    lit_color = mix(lit_color, fog_color.rgb, fog);
    
    COLOR = vec4(lit_color, tex.a);
}

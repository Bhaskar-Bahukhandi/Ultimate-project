shader_type canvas_item;

// CRT Monitor Effect - Makes ColorRects look like retro terminal graphics
uniform float distortion = 0.1;
uniform float scanline_intensity = 0.15;
uniform float scanline_count = 800.0;
uniform float vignette = 0.3;
uniform float brightness = 1.2;
uniform float contrast = 1.1;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // CRT curvature distortion
    vec2 centered = uv * 2.0 - 1.0;
    vec2 distorted = centered;
    distorted.x *= 1.0 + pow(abs(centered.y), 2.0) * distortion;
    distorted.y *= 1.0 + pow(abs(centered.x), 2.0) * distortion;
    uv = (distorted + 1.0) * 0.5;
    
    // Sample texture
    vec4 color = texture(screen_texture, uv);
    
    // Scanlines
    float scanline = sin(uv.y * scanline_count) * scanline_intensity;
    color.rgb -= scanline;
    
    // Vignette effect
    vec2 vig = uv * (1.0 - uv);
    float vignette_factor = vig.x * vig.y * 15.0;
    vignette_factor = pow(vignette_factor, vignette);
    color.rgb *= vignette_factor;
    
    // Brightness and contrast
    color.rgb = ((color.rgb - 0.5) * contrast + 0.5) * brightness;
    
    // Chromatic aberration
    float aberration = 0.002;
    color.r = texture(screen_texture, uv + vec2(aberration, 0.0)).r;
    color.b = texture(screen_texture, uv - vec2(aberration, 0.0)).b;
    
    COLOR = color;
}

shader_type canvas_item;

// Glitch effect shader based on corruption level
// Tuned for readability — subtle at low corruption, cinematic at high

uniform float corruption : hint_range(0.0, 1.0) = 0.0;
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Chromatic aberration — subtle RGB split
vec3 chromatic_aberration(sampler2D tex, vec2 uv, float amount) {
	float r = texture(tex, uv + vec2(amount, 0.0)).r;
	float g = texture(tex, uv).g;
	float b = texture(tex, uv - vec2(amount, 0.0)).b;
	return vec3(r, g, b);
}

// Pixel displacement — much gentler, with rarer spikes
vec2 glitch_displacement(vec2 uv, float time, float intensity) {
	// Soft continuous wobble (very subtle)
	float wobble = sin(uv.y * 30.0 + time * 3.0) * 0.002 * intensity;

	// Rare horizontal glitch bars — only trigger occasionally
	float bar_seed = floor(time * 2.0);  // Changes twice per second
	float bar_hash = fract(sin(bar_seed * 43.17) * 4371.5);
	if (bar_hash < 0.3 * intensity) {
		// Check if this scanline is in the glitch band
		float band_center = fract(sin(bar_seed * 91.13) * 1731.2);
		float band_width = 0.02 + 0.03 * intensity;
		float dist_to_band = abs(uv.y - band_center);
		if (dist_to_band < band_width) {
			wobble += 0.015 * intensity * smoothstep(band_width, 0.0, dist_to_band);
		}
	}

	return vec2(wobble, 0.0);
}

// Color quantization (reduce colors for corrupted look)
vec3 quantize_color(vec3 color, float levels) {
	return floor(color * levels) / levels;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float time = TIME * time_scale;

	// --- 25%+ corruption: scanline shimmer + occasional RGB split flicker ---
	float scanline_25 = 0.0;
	if (corruption > 0.25) {
		float eff_low = clamp((corruption - 0.25) * 4.0, 0.0, 1.0);
		scanline_25 = sin(uv.y * 400.0 + time * 1.5) * 0.012 * eff_low;
		// Occasional screen flicker at 25%+
		float flicker_seed = floor(time * 8.0);
		float flicker_hash = fract(sin(flicker_seed * 27.63) * 3791.2);
		if (flicker_hash < 0.04 * eff_low) {
			scanline_25 += 0.03 * eff_low;
		}
	}

	// Scale corruption for heavy effect thresholds (remap 0.5-1.0 to 0.0-1.0)
	float eff = clamp((corruption - 0.5) * 2.0, 0.0, 1.0);

	// Apply displacement — above 50% corruption
	if (eff > 0.0) {
		uv += glitch_displacement(uv, time, eff);
	}

	// Sample color — chromatic aberration starts at 50% (subtle), ramps up
	vec3 color;
	if (corruption > 0.50) {
		float aberration_amount = 0.001 + 0.004 * eff;
		color = chromatic_aberration(screen_texture, uv, aberration_amount);
	} else {
		color = texture(screen_texture, uv).rgb;
	}

	// Apply scanline shimmer
	color -= scanline_25;

	// 25%+ subtle green/cyan tint flicker
	if (corruption > 0.25) {
		float tint_str = (corruption - 0.25) * 0.06;
		color.g += sin(time * 2.0) * tint_str;
		// Faint red channel noise at 50%+
		if (corruption > 0.50) {
			color.r += sin(time * 7.0 + uv.y * 100.0) * 0.02 * eff;
		}
	}

	// Screen tear effect at 50%+ — horizontal line displacement
	if (corruption > 0.50) {
		float tear_seed = floor(time * 3.0);
		float tear_hash = fract(sin(tear_seed * 53.71) * 2917.3);
		if (tear_hash < 0.15 * eff) {
			float tear_y = fract(sin(tear_seed * 91.17) * 4831.5);
			float tear_width = 0.005 + 0.01 * eff;
			if (abs(uv.y - tear_y) < tear_width) {
				// Shift this horizontal band sideways
				float shift = 0.02 * eff * sign(sin(tear_seed * 17.3));
				vec2 tear_uv = vec2(uv.x + shift, uv.y);
				color = texture(screen_texture, tear_uv).rgb;
			}
		}
	}

	// Persistent scanlines at 75%+ — heavier, CRT-style
	if (corruption > 0.75) {
		float scanline = sin(uv.y * 600.0 + time * 2.0) * 0.035;
		float scanline2 = sin(uv.y * 300.0 - time * 1.2) * 0.015;
		color -= (scanline + scanline2) * eff;
		// Static noise overlay
		float static_noise = fract(sin(dot(uv * 500.0, vec2(12.9898, 78.233)) + time * 10.0) * 43758.5453);
		color = mix(color, vec3(static_noise), 0.04 * eff);
	}

	// Vignette darkening at 75%+ — edges get dark, screen feels claustrophobic
	if (corruption > 0.75) {
		float vignette_str = (corruption - 0.75) * 2.0; // 0 to 0.5
		vec2 vig_uv = uv * 2.0 - 1.0;
		float vig = 1.0 - dot(vig_uv, vig_uv) * 0.3 * vignette_str;
		color *= max(vig, 0.5);
	}

	// Color quantization at extreme corruption (85%+)
	if (corruption > 0.85) {
		float color_levels = mix(128.0, 12.0, (corruption - 0.85) * 6.67);
		color = quantize_color(color, color_levels);
	}

	// Pixel block noise — at 85%+ (was 90%, now more visible)
	if (corruption > 0.85) {
		vec2 block_uv = floor(uv * 50.0) / 50.0;
		float noise = fract(sin(dot(block_uv, vec2(12.9898, 78.233)) + time) * 43758.5453);
		if (noise < 0.04 * eff) {
			color = vec3(noise * 0.5, noise * 0.3, noise * 0.8); // Purple-tinted glitch blocks
		}
	}

	// Color channel shifting at extreme corruption (90%+)
	if (corruption > 0.90) {
		float shift_eff = (corruption - 0.90) * 10.0;
		color.r = fract(color.r + sin(time * 0.5) * 0.15 * shift_eff);
		color.g = fract(color.g + cos(time * 0.7) * 0.08 * shift_eff);
		// Brief total whiteout flashes
		float flash_seed = floor(time * 4.0);
		float flash_hash = fract(sin(flash_seed * 67.91) * 5183.7);
		if (flash_hash < 0.03 * shift_eff) {
			color = mix(color, vec3(1.0), 0.4 * shift_eff);
		}
	}

	COLOR = vec4(color, 1.0);
}

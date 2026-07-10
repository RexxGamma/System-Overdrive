#Shader Copied lol

shader_type canvas_item;
render_mode unshaded, blend_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float scanlines_intensity : hint_range(0.0, 1.0)    = 0.18;
uniform float scanlines_count     : hint_range(80.0, 400.0) = 180.0;
uniform float aberration_amount   : hint_range(0.0, 0.012)  = 0.003;
uniform float vhs_intensity       : hint_range(0.0, 1.0)    = 0.35;
uniform float vhs_speed           : hint_range(0.0, 6.0)    = 2.0;
uniform float vhs_head_switch     : hint_range(0.0, 1.0)    = 0.4;
uniform float wiggle_amount       : hint_range(0.0, 0.01)   = 0.0015;
uniform float wiggle_speed        : hint_range(0.0, 6.0)    = 1.5;
uniform float wiggle_frequency    : hint_range(1.0, 20.0)   = 5.0;
uniform float glitch_intensity    : hint_range(0.0, 0.3)    = 0.08;
uniform float glitch_rate         : hint_range(0.05, 3.0)   = 0.15;
uniform float glitch_max_band     : hint_range(0.02, 0.25)  = 0.08;
uniform float vignette_strength   : hint_range(0.0, 2.0)    = 0.5;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	return fract(p * (p + p));
}

float hash21(vec2 p) {
	vec3 q = fract(vec3(p.xyx) * vec3(0.1031, 0.103, 0.0973));
	q += dot(q, q.yzx + 19.19);
	return fract((q.x + q.y) * q.z);
}

void fragment() {
	vec2  uv = SCREEN_UV;
	float t  = TIME;

	// Wiggle
	float phase = fract(uv.y * wiggle_frequency - t * wiggle_speed);
	uv.x += (abs(phase * 2.0 - 1.0) - 0.5) * wiggle_amount;

	// VHS drift
	float t_q  = floor(t * vhs_speed) / vhs_speed;
	uv.x += (hash21(vec2(floor(uv.y * 12.0), t_q)) - 0.5) * 0.015 * vhs_intensity;

	// Head-switch (franja superior, step en vez de smoothstep)
	float hs = step(uv.y, 0.04) * vhs_head_switch;
	uv.x += (hash11(t * 5.0 + uv.y * 3.0) - 0.5) * 0.06 * hs;

	// Glitch (banda pequeña, 2 hash calls)
	float gt   = floor(t / glitch_rate);
	float by   = hash11(gt * 1.61) * (1.0 - glitch_max_band);
	float in_b = step(by, uv.y) * step(uv.y, by + hash11(gt * 0.91) * glitch_max_band);
	uv.x += (hash21(vec2(gt, floor(uv.y * 20.0))) - 0.5) * glitch_intensity * in_b;

	uv = clamp(uv, 0.001, 0.999);

	// Aberración cromática — 3 samples
	float dx = aberration_amount;
	vec3 col;
	col.r = texture(screen_texture, uv - vec2(dx, 0.0)).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, uv + vec2(dx, 0.0)).b;

	// Scanlines
	col *= 1.0 - step(0.5, fract(uv.y * scanlines_count * 0.5)) * scanlines_intensity;

	// Vignette
	vec2 vc = uv * 2.0 - 1.0;
	col *= clamp(1.0 - dot(vc, vc) * vignette_strength * 0.45, 0.0, 1.0);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}

// ============================================================
//  SETUP en Godot 4
// ============================================================
//  CanvasLayer (layer = 10)
//  └─ BackBufferCopy  [Copy Mode = Viewport]
//     └─ TextureRect  [Anchor: Full Rect | ShaderMaterial → este archivo]
// ============================================================

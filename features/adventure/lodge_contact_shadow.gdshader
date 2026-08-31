shader_type canvas_item;

uniform vec3 shadow_color : source_color = vec3(0.025, 0.055, 0.04);
uniform float opacity : hint_range(0.0, 1.0) = 0.52;
uniform float soft_start : hint_range(0.0, 1.0) = 0.12;
uniform float solid_start : hint_range(0.0, 1.0) = 0.72;


void fragment() {
	vec4 tint = COLOR;
	vec4 sampled = texture(TEXTURE, UV);
	float source_brightness = max(sampled.r, max(sampled.g, sampled.b));
	float darkness = 1.0 - source_brightness;
	float mask = smoothstep(soft_start, solid_start, darkness);
	mask = pow(mask, 1.15);
	COLOR = vec4(shadow_color, mask * opacity * sampled.a) * tint;
}

shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D sprite_texture : source_color, filter_linear;
uniform float background_start = 0.80;
uniform float background_end = 0.94;
uniform float saturation_start = 0.05;
uniform float saturation_end = 0.20;

void fragment() {
	vec4 sampled = texture(sprite_texture, UV);
	float maximum = max(sampled.r, max(sampled.g, sampled.b));
	float minimum = min(sampled.r, min(sampled.g, sampled.b));
	float saturation = maximum - minimum;
	float luminance = dot(sampled.rgb, vec3(0.2126, 0.7152, 0.0722));
	float bright_background = smoothstep(background_start, background_end, luminance);
	float neutral_background = 1.0 - smoothstep(saturation_start, saturation_end, saturation);
	float background_alpha = bright_background * neutral_background;
	float alpha = sampled.a * (1.0 - background_alpha);
	if (alpha < 0.08) {
		discard;
	}
	ALBEDO = sampled.rgb;
	ALPHA = alpha;
}

shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D sprite_texture : source_color, filter_linear;
uniform vec3 key_color = vec3(0.94, 0.055, 0.93);
uniform float transparent_radius = 0.25;
uniform float feather_radius = 0.40;
uniform float despill_radius = 0.55;
uniform vec3 sprite_tint : source_color = vec3(1.0);

vec2 chroma(vec3 color) {
	return vec2(color.r - color.g, color.b - color.g);
}

void fragment() {
	vec4 sample_color = texture(sprite_texture, UV);
	float key_distance = distance(chroma(sample_color.rgb), chroma(key_color));
	float keyed_alpha = smoothstep(transparent_radius, feather_radius, key_distance);
	float recovery_alpha = smoothstep(transparent_radius, despill_radius, key_distance);
	float safe_alpha = max(recovery_alpha, 0.001);
	vec3 recovered_edge = clamp(
		(sample_color.rgb - key_color * (1.0 - safe_alpha)) / safe_alpha,
		vec3(0.0),
		vec3(1.0)
	);
	float recovery_weight = sqrt(max(1.0 - recovery_alpha, 0.0));
	vec3 despilled_color = mix(sample_color.rgb, recovered_edge, recovery_weight);
	float alpha = keyed_alpha * sample_color.a;
	if (alpha < 0.08) {
		discard;
	}
	ALBEDO = despilled_color * sprite_tint;
	ALPHA = alpha;
}

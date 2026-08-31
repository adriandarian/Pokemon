shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.94, 0.055, 0.93);
uniform float transparent_radius : hint_range(0.0, 0.8) = 0.10;
uniform float feather_radius : hint_range(0.0, 0.8) = 0.52;
uniform float despill_radius : hint_range(0.0, 1.2) = 0.74;


vec2 chroma(vec3 color) {
	return vec2(color.r - color.g, color.b - color.g);
}


void fragment() {
	vec4 tint = COLOR;
	vec4 sampled = texture(TEXTURE, UV);
	float key_distance = distance(chroma(sampled.rgb), chroma(key_color));
	float keyed_alpha = smoothstep(transparent_radius, feather_radius, key_distance);
	float recovery_alpha = smoothstep(transparent_radius, despill_radius, key_distance);
	float safe_alpha = max(recovery_alpha, 0.001);
	vec3 recovered_edge = clamp(
		(sampled.rgb - key_color * (1.0 - safe_alpha)) / safe_alpha,
		vec3(0.0),
		vec3(1.0)
	);
	float recovery_weight = sqrt(max(1.0 - recovery_alpha, 0.0));
	vec3 despilled_color = mix(sampled.rgb, recovered_edge, recovery_weight);
	COLOR = vec4(despilled_color, sampled.a * keyed_alpha) * tint;
}

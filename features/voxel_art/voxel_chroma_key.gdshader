shader_type canvas_item;

uniform vec3 key_color : source_color = vec3(0.94, 0.055, 0.93);
uniform float transparent_radius : hint_range(0.0, 0.5) = 0.09;
uniform float feather_radius : hint_range(0.0, 0.5) = 0.20;


void fragment() {
	vec4 tint = COLOR;
	vec4 sampled = texture(TEXTURE, UV);
	float key_distance = distance(sampled.rgb, key_color);
	float keyed_alpha = smoothstep(transparent_radius, feather_radius, key_distance);
	COLOR = vec4(sampled.rgb, sampled.a * keyed_alpha) * tint;
}


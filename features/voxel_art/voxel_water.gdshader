shader_type canvas_item;
render_mode unshaded;

uniform vec2 flow_speed = vec2(0.032, 0.018);
uniform float motion_amount : hint_range(0.0, 1.0) = 1.0;
uniform float voxel_steps : hint_range(24.0, 256.0, 1.0) = 112.0;
uniform vec4 deep_tint : source_color = vec4(0.075, 0.42, 0.47, 1.0);
uniform vec4 light_tint : source_color = vec4(0.55, 0.92, 0.84, 1.0);


void fragment() {
	vec2 flow = TIME * flow_speed * motion_amount;
	vec2 primary_uv = floor(fract(UV + flow) * voxel_steps) / voxel_steps;
	vec2 cross_uv = floor(fract(UV * vec2(1.07, 0.93) + vec2(-flow.y, flow.x) * 0.62) * voxel_steps) / voxel_steps;
	vec4 primary = texture(TEXTURE, primary_uv);
	vec4 cross_flow = texture(TEXTURE, cross_uv);
	float current_band = sin((UV.x * 1.35 + UV.y) * 78.0 - TIME * 2.1 * motion_amount);
	float shimmer = smoothstep(0.72, 0.98, current_band) * 0.12;
	vec3 water = mix(primary.rgb, cross_flow.rgb, 0.24);
	water = mix(water, deep_tint.rgb, 0.18);
	water = mix(water, light_tint.rgb, shimmer);
	COLOR = vec4(water, primary.a * COLOR.a) * vec4(COLOR.rgb, 1.0);
}


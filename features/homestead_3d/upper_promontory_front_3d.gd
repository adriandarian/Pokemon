extends RefCounted

## Isolated authored front contour for the upper homestead promontory.
##
## This module is not wired into the runtime world yet. Both visible ArrayMesh
## surfaces and collision prisms are generated from the same deterministic
## half-meter samples, leaving one source of truth for later integration.

const WEST_SIDE: StringName = &"west"
const EAST_SIDE: StringName = &"east"
const DEFAULT_SAMPLE_STEP := 0.5
const CELL_X := 1.0
const CELL_Z := 1.0
const CELL_Z_OFFSET := 0.5
const TRANSITION_HALF_X := 0.02
const MAX_SNAP_ERROR := CELL_Z * 0.5
const FACE_UV_SCALE := Vector3(0.12, 0.1836547, 1.0)
const FACE_ALBEDO_TINT := Color("#a2acc2")
const TOP_Y := 4.015
const BASE_Y := -1.43
# Broad legacy terrain boxes can stop at this shared interior seam. The contour
# then owns every visible and physical point from that seam to its authored face,
# so no rectangular grass cap can protrude beyond the new cliff.
const INTERIOR_JOIN_Z := -4.0
const TERRAIN_COLLISION_LAYER := 2
const TERRAIN_COLLISION_MASK := 1

# Vector2 values are (world_x, front_world_z). The interval between the west
# endpoint and east start is the genuine stair opening, not a visual cutout.
static var _WEST_CONTROL_POLYLINE := PackedVector2Array([
	Vector2(-13.00, -2.94),
	Vector2(-11.00, -1.45),
	Vector2(-9.00, 0.00),
	Vector2(-7.20, 1.75),
	Vector2(-5.31, 3.85),
	Vector2(-4.80, 4.95),
])

static var _EAST_CONTROL_POLYLINE := PackedVector2Array([
	Vector2(-1.20, 3.05),
	Vector2(0.25, 4.62),
	Vector2(1.00, 5.70),
	Vector2(3.50, 6.72),
	Vector2(6.10, 8.20),
	Vector2(8.75, 8.45),
	Vector2(10.80, 8.35),
	Vector2(12.00, 8.20),
	Vector2(13.30, 6.35),
	Vector2(15.00, 4.50),
])


static func get_side_ids() -> PackedStringArray:
	return PackedStringArray([WEST_SIDE, EAST_SIDE])


static func get_control_polyline(side: StringName) -> PackedVector2Array:
	match side:
		WEST_SIDE:
			return _WEST_CONTROL_POLYLINE.duplicate()
		EAST_SIDE:
			return _EAST_CONTROL_POLYLINE.duplicate()
		_:
			return PackedVector2Array()


static func get_stair_gap_bounds() -> Vector2:
	return Vector2(_WEST_CONTROL_POLYLINE[-1].x, _EAST_CONTROL_POLYLINE[0].x)


static func sample_side(
	side: StringName,
	step: float = DEFAULT_SAMPLE_STEP
) -> PackedVector2Array:
	var controls := get_control_polyline(side)
	if controls.size() < 2 or step <= 0.0:
		return PackedVector2Array()
	return _build_voxel_samples(controls, minf(step, CELL_X))


static func sample_all(
	step: float = DEFAULT_SAMPLE_STEP
) -> Dictionary:
	return {
		WEST_SIDE: sample_side(WEST_SIDE, step),
		EAST_SIDE: sample_side(EAST_SIDE, step),
	}


static func sample_front_z(side: StringName, world_x: float) -> float:
	var controls := get_control_polyline(side)
	if controls.size() < 2:
		return NAN
	if world_x < controls[0].x or world_x > controls[-1].x:
		return NAN
	return _sample_front_z(controls, world_x)


static func sample_voxel_front_z(
	side: StringName,
	world_x: float,
	step: float = DEFAULT_SAMPLE_STEP
) -> float:
	var samples := sample_side(side, step)
	if samples.size() < 2:
		return NAN
	if world_x < samples[0].x or world_x > samples[-1].x:
		return NAN
	return _sample_front_z(samples, world_x)


static func side_for_x(world_x: float) -> StringName:
	for side: StringName in get_side_ids():
		var controls := get_control_polyline(side)
		if world_x >= controls[0].x and world_x <= controls[-1].x:
			return side
	return &""


static func has_contour_at_x(world_x: float) -> bool:
	return not side_for_x(world_x).is_empty()


static func contains_top_support_xz(
	point: Vector2,
	margin: float = 0.0
) -> bool:
	var safe_margin := maxf(0.0, margin)
	for side: StringName in get_side_ids():
		var controls := get_control_polyline(side)
		if point.x < controls[0].x - safe_margin or point.x > controls[-1].x + safe_margin:
			continue
		var clamped_x := clampf(point.x, controls[0].x, controls[-1].x)
		var front_z := sample_voxel_front_z(side, clamped_x)
		if (
			point.y >= INTERIOR_JOIN_Z - safe_margin
			and point.y <= front_z + safe_margin
		):
			return true
	return false


static func supports_top_point(
	world_point: Vector3,
	vertical_tolerance: float = 0.1,
	horizontal_margin: float = 0.0
) -> bool:
	return (
		absf(world_point.y - TOP_Y) <= maxf(0.0, vertical_tolerance)
		and contains_top_support_xz(
			Vector2(world_point.x, world_point.z),
			horizontal_margin
		)
	)


static func get_validation_metrics(
	step: float = DEFAULT_SAMPLE_STEP
) -> Dictionary:
	var segment_count := 0
	var sample_count := 0
	var monotonic_x := true
	var minimum_sample_spacing := INF
	var maximum_sample_spacing := 0.0
	var maximum_front_delta := 0.0
	var maximum_snap_error := 0.0
	var minimum_cap_depth := INF
	var maximum_cap_depth := 0.0
	for side: StringName in get_side_ids():
		var controls := get_control_polyline(side)
		var samples := sample_side(side, step)
		sample_count += samples.size()
		segment_count += maxi(0, samples.size() - 1)
		for index: int in range(1, samples.size()):
			var delta_x: float = samples[index].x - samples[index - 1].x
			monotonic_x = monotonic_x and delta_x > 0.0
			minimum_sample_spacing = minf(minimum_sample_spacing, delta_x)
			maximum_sample_spacing = maxf(maximum_sample_spacing, delta_x)
			maximum_front_delta = maxf(
				maximum_front_delta,
				absf(samples[index].y - samples[index - 1].y)
			)
			var segment_midpoint := samples[index - 1].lerp(samples[index], 0.5)
			maximum_snap_error = maxf(
				maximum_snap_error,
				absf(
					segment_midpoint.y
					- _sample_front_z(controls, segment_midpoint.x)
				)
			)
		for sample: Vector2 in samples:
			maximum_snap_error = maxf(
				maximum_snap_error,
				absf(sample.y - _sample_front_z(controls, sample.x))
			)
			var cap_depth: float = sample.y - INTERIOR_JOIN_Z
			minimum_cap_depth = minf(minimum_cap_depth, cap_depth)
			maximum_cap_depth = maxf(maximum_cap_depth, cap_depth)
	if is_inf(minimum_sample_spacing):
		minimum_sample_spacing = 0.0
	if is_inf(minimum_cap_depth):
		minimum_cap_depth = 0.0
	var gap_bounds := get_stair_gap_bounds()
	return {
		"side_count": get_side_ids().size(),
		"sample_count": sample_count,
		"segment_count": segment_count,
		"top_triangle_count": segment_count * 2,
		"face_triangle_count": segment_count * 2,
		"collision_prism_count": segment_count,
		"monotonic_x": monotonic_x,
		"minimum_sample_spacing": minimum_sample_spacing,
		"maximum_sample_spacing": maximum_sample_spacing,
		"maximum_front_delta": maximum_front_delta,
		"maximum_snap_error": maximum_snap_error,
		"minimum_cap_depth": minimum_cap_depth,
		"maximum_cap_depth": maximum_cap_depth,
		"stair_gap_width": gap_bounds.y - gap_bounds.x,
		"top_y": TOP_Y,
		"base_y": BASE_Y,
		"interior_join_z": INTERIOR_JOIN_Z,
	}


static func create_contour_root(
	top_material: Material = null,
	face_material: Material = null,
	step: float = DEFAULT_SAMPLE_STEP
) -> Node3D:
	var root := Node3D.new()
	root.name = "UpperPromontoryFrontContour"

	var top_surface := SurfaceTool.new()
	top_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face_surface := SurfaceTool.new()
	face_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var collision_body := StaticBody3D.new()
	collision_body.name = "PromontoryContourCollision"
	collision_body.collision_layer = TERRAIN_COLLISION_LAYER
	collision_body.collision_mask = TERRAIN_COLLISION_MASK

	var collision_index := 0
	for side: StringName in get_side_ids():
		var samples := sample_side(side, step)
		var face_u := 0.0
		for index: int in range(samples.size() - 1):
			var left: Vector2 = samples[index]
			var right: Vector2 = samples[index + 1]
			_add_top_quad(top_surface, left, right)
			var segment_length := left.distance_to(right)
			_add_face_quad(face_surface, left, right, face_u, face_u + segment_length)
			_add_collision_prism(
				collision_body,
				"ContourPrism%03d" % collision_index,
				left,
				right
			)
			collision_index += 1
			face_u += segment_length

	var top_instance := MeshInstance3D.new()
	top_instance.name = "PromontoryContourTop"
	top_instance.mesh = top_surface.commit()
	top_instance.material_override = top_material
	root.add_child(top_instance)

	var face_instance := MeshInstance3D.new()
	face_instance.name = "PromontoryContourFace"
	face_instance.mesh = face_surface.commit()
	face_instance.material_override = _make_isolated_face_material(face_material)
	root.add_child(face_instance)

	root.add_child(collision_body)
	return root


static func _make_isolated_face_material(source_material: Material) -> Material:
	if not source_material is StandardMaterial3D:
		return source_material
	var face_material := source_material.duplicate() as StandardMaterial3D
	# The face mesh owns continuous distance/height UVs. Using those coordinates
	# prevents world-triplanar projection from rotating the masonry pattern on each
	# narrow voxel transition while leaving the shared box material untouched.
	face_material.uv1_triplanar = false
	face_material.uv1_world_triplanar = false
	face_material.uv1_scale = FACE_UV_SCALE
	face_material.albedo_color = FACE_ALBEDO_TINT
	face_material.texture_filter = (
		BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
	)
	return face_material


static func _add_top_quad(
	surface: SurfaceTool,
	left: Vector2,
	right: Vector2
) -> void:
	var left_inner := Vector3(left.x, TOP_Y, INTERIOR_JOIN_Z)
	var left_front := Vector3(left.x, TOP_Y, left.y)
	var right_front := Vector3(right.x, TOP_Y, right.y)
	var right_inner := Vector3(right.x, TOP_Y, INTERIOR_JOIN_Z)
	# Godot treats clockwise triangles as front-facing. Keep the cap clockwise from
	# above so its explicit upward normal is not flipped by the double-sided
	# material when rendered from the locked faux-isometric camera.
	_add_vertex(surface, left_inner, Vector3.UP, Vector2(left_inner.x, left_inner.z))
	_add_vertex(surface, right_front, Vector3.UP, Vector2(right_front.x, right_front.z))
	_add_vertex(surface, left_front, Vector3.UP, Vector2(left_front.x, left_front.z))
	_add_vertex(surface, left_inner, Vector3.UP, Vector2(left_inner.x, left_inner.z))
	_add_vertex(surface, right_inner, Vector3.UP, Vector2(right_inner.x, right_inner.z))
	_add_vertex(surface, right_front, Vector3.UP, Vector2(right_front.x, right_front.z))


static func _add_face_quad(
	surface: SurfaceTool,
	left: Vector2,
	right: Vector2,
	left_u: float,
	right_u: float
) -> void:
	var left_top := Vector3(left.x, TOP_Y, left.y)
	var right_top := Vector3(right.x, TOP_Y, right.y)
	var right_base := Vector3(right.x, BASE_Y, right.y)
	var left_base := Vector3(left.x, BASE_Y, left.y)
	var delta := right_top - left_top
	var outward_normal := Vector3(-delta.z, 0.0, delta.x).normalized()
	# Godot treats clockwise triangles as front-facing. Keep the camera-facing
	# contour front-facing so its explicit outward normal is not flipped by the
	# double-sided cliff material's backface shading path.
	_add_vertex(surface, left_top, outward_normal, Vector2(left_u, 0.0))
	_add_vertex(surface, right_base, outward_normal, Vector2(right_u, TOP_Y - BASE_Y))
	_add_vertex(surface, left_base, outward_normal, Vector2(left_u, TOP_Y - BASE_Y))
	_add_vertex(surface, left_top, outward_normal, Vector2(left_u, 0.0))
	_add_vertex(surface, right_top, outward_normal, Vector2(right_u, 0.0))
	_add_vertex(surface, right_base, outward_normal, Vector2(right_u, TOP_Y - BASE_Y))


static func _add_collision_prism(
	body: StaticBody3D,
	shape_name: String,
	left: Vector2,
	right: Vector2
) -> void:
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(left.x, TOP_Y, INTERIOR_JOIN_Z),
		Vector3(left.x, TOP_Y, left.y),
		Vector3(right.x, TOP_Y, right.y),
		Vector3(right.x, TOP_Y, INTERIOR_JOIN_Z),
		Vector3(left.x, BASE_Y, INTERIOR_JOIN_Z),
		Vector3(left.x, BASE_Y, left.y),
		Vector3(right.x, BASE_Y, right.y),
		Vector3(right.x, BASE_Y, INTERIOR_JOIN_Z),
	])
	var collision := CollisionShape3D.new()
	collision.name = shape_name
	collision.shape = shape
	body.add_child(collision)


static func _add_vertex(
	surface: SurfaceTool,
	vertex: Vector3,
	normal: Vector3,
	uv: Vector2
) -> void:
	surface.set_normal(normal)
	surface.set_uv(uv)
	surface.add_vertex(vertex)


static func _sample_front_z(
	controls: PackedVector2Array,
	world_x: float
) -> float:
	if world_x <= controls[0].x:
		return controls[0].y
	if world_x >= controls[-1].x:
		return controls[-1].y
	for index: int in range(controls.size() - 1):
		var left: Vector2 = controls[index]
		var right: Vector2 = controls[index + 1]
		if world_x <= right.x:
			return lerpf(
				left.y,
				right.y,
				inverse_lerp(left.x, right.x, world_x)
			)
	return controls[-1].y


static func _build_voxel_samples(
	controls: PackedVector2Array,
	maximum_spacing: float
) -> PackedVector2Array:
	var minimum_x: float = controls[0].x
	var maximum_x: float = controls[-1].x
	var transition_xs := _get_voxel_transition_xs(controls)
	var anchors := PackedVector2Array()
	_append_distinct_point(anchors, controls[0])

	var first_transition_x: float = (
		transition_xs[0] if not transition_xs.is_empty() else maximum_x
	)
	var start_guard_x := minf(
		minimum_x + TRANSITION_HALF_X,
		lerpf(minimum_x, first_transition_x, 0.45)
	)
	if start_guard_x < maximum_x - 0.000001:
		_append_distinct_point(
			anchors,
			Vector2(start_guard_x, _snapped_front_z(controls, start_guard_x))
		)

	for transition_index: int in range(transition_xs.size()):
		var transition_x: float = transition_xs[transition_index]
		var previous_limit: float = (
			transition_xs[transition_index - 1]
			if transition_index > 0
			else minimum_x
		)
		var next_limit: float = (
			transition_xs[transition_index + 1]
			if transition_index + 1 < transition_xs.size()
			else maximum_x
		)
		var transition_half_width := minf(
			TRANSITION_HALF_X,
			minf(
				(transition_x - previous_limit) * 0.45,
				(next_limit - transition_x) * 0.45
			)
		)
		var transition_left_x := transition_x - transition_half_width
		var transition_right_x := transition_x + transition_half_width
		_append_distinct_point(
			anchors,
			Vector2(
				transition_left_x,
				_snapped_front_z(controls, transition_left_x)
			)
		)
		_append_distinct_point(
			anchors,
			Vector2(
				transition_right_x,
				_snapped_front_z(controls, transition_right_x)
			)
		)

	var last_transition_x: float = (
		transition_xs[-1] if not transition_xs.is_empty() else minimum_x
	)
	var end_guard_x := maxf(
		maximum_x - TRANSITION_HALF_X,
		lerpf(last_transition_x, maximum_x, 0.55)
	)
	if end_guard_x > minimum_x + 0.000001:
		_append_distinct_point(
			anchors,
			Vector2(end_guard_x, _snapped_front_z(controls, end_guard_x))
		)
	_append_distinct_point(anchors, controls[-1])

	var samples := PackedVector2Array()
	for anchor_index: int in range(anchors.size() - 1):
		var left: Vector2 = anchors[anchor_index]
		var right: Vector2 = anchors[anchor_index + 1]
		if samples.is_empty():
			samples.append(left)
		var interval_count := maxi(
			1,
			ceili((right.x - left.x) / maximum_spacing)
		)
		for interval_index: int in range(1, interval_count + 1):
			samples.append(
				left.lerp(right, float(interval_index) / float(interval_count))
			)
	return samples


static func _get_voxel_transition_xs(
	controls: PackedVector2Array
) -> PackedFloat32Array:
	var candidates := PackedFloat32Array()
	var minimum_x: float = controls[0].x
	var maximum_x: float = controls[-1].x
	for control_index: int in range(controls.size() - 1):
		var left: Vector2 = controls[control_index]
		var right: Vector2 = controls[control_index + 1]
		if is_equal_approx(left.y, right.y):
			continue
		var minimum_z := minf(left.y, right.y)
		var maximum_z := maxf(left.y, right.y)
		var first_level := floori(minimum_z / CELL_Z) - 1
		var last_level := ceili(maximum_z / CELL_Z) + 1
		for level_index: int in range(first_level, last_level + 1):
			var threshold_z := (
				CELL_Z_OFFSET
				+ (float(level_index) + 0.5) * CELL_Z
			)
			if threshold_z < minimum_z or threshold_z > maximum_z:
				continue
			var transition_x := lerpf(
				left.x,
				right.x,
				inverse_lerp(left.y, right.y, threshold_z)
			)
			if (
				transition_x > minimum_x + 0.000001
				and transition_x < maximum_x - 0.000001
			):
				candidates.append(transition_x)
	candidates.sort()

	var transitions := PackedFloat32Array()
	for candidate_x: float in candidates:
		if not transitions.is_empty() and is_equal_approx(transitions[-1], candidate_x):
			continue
		var probe_half_width := minf(0.001, minf(
			candidate_x - minimum_x,
			maximum_x - candidate_x
		))
		if is_equal_approx(
			_snapped_front_z(controls, candidate_x - probe_half_width),
			_snapped_front_z(controls, candidate_x + probe_half_width)
		):
			continue
		transitions.append(candidate_x)
	return transitions


static func _snapped_front_z(
	controls: PackedVector2Array,
	world_x: float
) -> float:
	return (
		snappedf(
			_sample_front_z(controls, world_x) - CELL_Z_OFFSET,
			CELL_Z
		)
		+ CELL_Z_OFFSET
	)


static func _append_distinct_point(
	points: PackedVector2Array,
	point: Vector2
) -> void:
	if not points.is_empty() and is_equal_approx(points[-1].x, point.x):
		points[-1] = point
		return
	points.append(point)

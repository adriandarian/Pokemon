extends Node

const PROMONTORY_FRONT: Script = preload(
	"res://features/homestead_3d/upper_promontory_front_3d.gd"
)
const RIVER_SHORE_PROFILE: Script = preload(
	"res://features/homestead_3d/river_shore_profile_3d.gd"
)
const SAMPLE_STEP := 0.5
const EPSILON := 0.0001
const MINIMUM_RIVER_CLEARANCE := 3.9
const LOWER_TERRAIN_TOP_Y := 0.085

var _failures: Array[String] = []


func _ready() -> void:
	var side_ids: PackedStringArray = PROMONTORY_FRONT.get_side_ids()
	_expect(side_ids == PackedStringArray([&"west", &"east"]), "The contour owns exactly one west and one east source polyline.")

	var first_samples: Dictionary = PROMONTORY_FRONT.sample_all(SAMPLE_STEP)
	var second_samples: Dictionary = PROMONTORY_FRONT.sample_all(SAMPLE_STEP)
	_expect(first_samples == second_samples, "Repeated contour sampling is deterministic.")
	_expect(is_equal_approx(PROMONTORY_FRONT.CELL_X, 1.0), "The contour uses one-meter voxel cells.")
	_expect(is_equal_approx(PROMONTORY_FRONT.CELL_Z, 1.0), "The contour snaps depth to calm one-meter courses.")
	_expect(is_equal_approx(PROMONTORY_FRONT.CELL_Z_OFFSET, 0.5), "The one-meter courses use the inward-safe half-meter depth phase.")
	_expect(is_equal_approx(PROMONTORY_FRONT.TRANSITION_HALF_X, 0.02), "Voxel steps use the authored 0.02-meter transition half-width.")
	_expect(PROMONTORY_FRONT.FACE_UV_SCALE.is_equal_approx(Vector3(0.12, 0.1836547, 1.0)), "The contour face maps its full height once and limits horizontal repetition.")
	_expect(PROMONTORY_FRONT.FACE_ALBEDO_TINT.is_equal_approx(Color("#a2acc2")), "The contour face retains the measured shared cliff tint while owning its UV cadence.")

	var plateau_segment_count := 0
	var transition_segment_count := 0
	var minimum_river_clearance := INF
	for side: StringName in side_ids:
		var controls: PackedVector2Array = PROMONTORY_FRONT.get_control_polyline(side)
		var samples: PackedVector2Array = first_samples[side] as PackedVector2Array
		_expect(controls.size() >= 2, "%s owns at least two authored controls." % side)
		_expect(samples.size() >= controls.size(), "%s derives a detailed voxel stream from its authored controls." % side)
		_expect(samples[0].is_equal_approx(controls[0]), "%s preserves its first authored endpoint exactly." % side)
		_expect(samples[-1].is_equal_approx(controls[-1]), "%s preserves its last authored endpoint exactly." % side)
		for control: Vector2 in controls:
			_expect(
				is_equal_approx(PROMONTORY_FRONT.sample_front_z(side, control.x), control.y),
				"%s preserves authored control %s exactly." % [side, control]
			)
		for index: int in range(1, samples.size()):
			var delta_x: float = samples[index].x - samples[index - 1].x
			_expect(delta_x > 0.0, "%s sample x is strictly monotonic at %d." % [side, index])
			_expect(delta_x <= SAMPLE_STEP + EPSILON, "%s never exceeds the half-meter sample step." % side)
			if is_equal_approx(samples[index].y, samples[index - 1].y):
				plateau_segment_count += 1
			else:
				transition_segment_count += 1
		for sample: Vector2 in samples:
			_expect(
				absf(sample.y - PROMONTORY_FRONT.sample_front_z(side, sample.x))
				<= PROMONTORY_FRONT.MAX_SNAP_ERROR + EPSILON,
				"%s voxel sample remains within the half-course snap bound." % side
			)
			_expect(
				is_equal_approx(
					PROMONTORY_FRONT.sample_voxel_front_z(side, sample.x, SAMPLE_STEP),
					sample.y
				),
				"%s support lookup consumes the same voxel stream as rendering." % side
			)
			_expect(
				PROMONTORY_FRONT.contains_top_support_xz(
					Vector2(
						sample.x,
						lerpf(PROMONTORY_FRONT.INTERIOR_JOIN_Z, sample.y, 0.5)
					)
				),
				"%s sampled cap center reports collision-backed support." % side
			)
			var north_shore_z: float = RIVER_SHORE_PROFILE.sample_effective_shores(sample.x).x
			minimum_river_clearance = minf(minimum_river_clearance, north_shore_z - sample.y)
	_expect(plateau_segment_count >= 30, "The derived profile contains broad voxel plateaus.")
	_expect(transition_segment_count >= 14, "The derived profile contains a restrained set of visible terraced depth changes.")
	_expect(transition_segment_count <= 19, "The one-meter stream avoids a mechanically repeated transition at every former 0.75-meter course.")
	_expect(
		minimum_river_clearance >= MINIMUM_RIVER_CLEARANCE,
		"Voxelization keeps at least 3.9 meters between the promontory and north river shore."
	)

	var gap_bounds: Vector2 = PROMONTORY_FRONT.get_stair_gap_bounds()
	_expect(gap_bounds.is_equal_approx(Vector2(-4.8, -1.2)), "The authored stair gap remains exactly -4.8 through -1.2 world x.")
	_expect(
		not PROMONTORY_FRONT.contains_top_support_xz(Vector2((gap_bounds.x + gap_bounds.y) * 0.5, 4.0)),
		"The stair opening is a genuine unsupported gap between contour owners."
	)

	var metrics: Dictionary = PROMONTORY_FRONT.get_validation_metrics(SAMPLE_STEP)
	_expect(metrics["side_count"] == 2, "Validation reports both contour sides.")
	_expect(metrics["monotonic_x"], "Validation reports monotonic sampled x.")
	_expect(metrics["maximum_sample_spacing"] <= SAMPLE_STEP + EPSILON, "Validation reports at most half-meter spacing.")
	_expect(metrics["minimum_sample_spacing"] > 0.0, "Validation reports positive segment spacing.")
	_expect(
		metrics["maximum_snap_error"] <= PROMONTORY_FRONT.MAX_SNAP_ERROR + EPSILON,
		"Validation reports no more than half a depth-course of profile displacement."
	)
	_expect(is_equal_approx(metrics["stair_gap_width"], 3.6), "Validation reports the 3.6-meter stair opening.")
	_expect(is_equal_approx(metrics["top_y"], 4.015), "The top surface remains at y=4.015.")
	_expect(is_equal_approx(metrics["base_y"], -1.43), "The cliff face and collision base extend to y=-1.43.")
	_expect(
		LOWER_TERRAIN_TOP_Y - PROMONTORY_FRONT.BASE_Y >= 1.5,
		"The contour prisms overlap at least 1.5 meters beneath the lower terrain surface."
	)
	_expect(is_equal_approx(metrics["interior_join_z"], -4.0), "The cap joins broad interior support at z=-4.0.")
	_expect(metrics["minimum_cap_depth"] >= 1.0, "Every voxel cap retains at least one meter of depth back to the interior support seam.")

	var source_face_material := StandardMaterial3D.new()
	var source_face_texture := ImageTexture.new()
	source_face_material.albedo_color = Color("#a2acc2")
	source_face_material.albedo_texture = source_face_texture
	source_face_material.roughness = 0.83
	source_face_material.uv1_scale = Vector3(0.18, 0.18, 0.18)
	source_face_material.uv1_triplanar = true
	source_face_material.uv1_world_triplanar = true
	var contour_root: Node3D = PROMONTORY_FRONT.create_contour_root(
		null,
		source_face_material,
		SAMPLE_STEP
	)
	add_child(contour_root)
	var top_instance := contour_root.get_node_or_null("PromontoryContourTop") as MeshInstance3D
	var face_instance := contour_root.get_node_or_null("PromontoryContourFace") as MeshInstance3D
	var collision_body := contour_root.get_node_or_null("PromontoryContourCollision") as StaticBody3D
	_expect(top_instance != null and top_instance.mesh is ArrayMesh, "The top is an ArrayMesh derived from contour samples.")
	_expect(face_instance != null and face_instance.mesh is ArrayMesh, "The cliff face is an ArrayMesh derived from contour samples.")
	_expect(collision_body != null, "The contour owns a StaticBody3D collision authority.")
	if face_instance != null:
		var isolated_face_material := face_instance.material_override as StandardMaterial3D
		_expect(isolated_face_material != null, "The contour retains a StandardMaterial3D face override.")
		if isolated_face_material != null:
			_expect(isolated_face_material != source_face_material, "The contour duplicates rather than mutates the shared cliff material.")
			_expect(not isolated_face_material.uv1_triplanar, "The isolated face material disables triplanar projection.")
			_expect(not isolated_face_material.uv1_world_triplanar, "The isolated face material disables world-triplanar projection.")
			_expect(isolated_face_material.uv1_scale.is_equal_approx(PROMONTORY_FRONT.FACE_UV_SCALE), "The isolated face material uses the full-height authored UV scale.")
			_expect(isolated_face_material.albedo_color.is_equal_approx(PROMONTORY_FRONT.FACE_ALBEDO_TINT), "The isolated face material lifts only the shaded contour tint.")
			_expect(isolated_face_material.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC, "The isolated face material preserves crisp masonry texels through mip levels.")
			_expect(is_equal_approx(isolated_face_material.roughness, source_face_material.roughness), "Material isolation preserves the shared cliff roughness.")
			_expect(isolated_face_material.albedo_texture == source_face_texture, "Material isolation preserves the shared cliff texture.")
		_expect(source_face_material.uv1_triplanar, "The shared cliff material remains triplanar.")
		_expect(source_face_material.uv1_world_triplanar, "The shared cliff material remains world-triplanar.")
		_expect(source_face_material.uv1_scale.is_equal_approx(Vector3(0.18, 0.18, 0.18)), "The shared cliff material retains its original UV scale.")
	if collision_body != null:
		_expect(collision_body.collision_layer == 2, "Contour collision uses terrain layer 2.")
		_expect(collision_body.collision_mask == 1, "Contour collision observes player layer 1.")
		_expect(
			collision_body.get_child_count() == metrics["collision_prism_count"],
			"There is exactly one collision prism per sampled contour segment."
		)
		_validate_collision_prisms(collision_body)
	if top_instance != null and top_instance.mesh is ArrayMesh:
		_validate_mesh(top_instance.mesh as ArrayMesh, metrics["top_triangle_count"], "top")
	if face_instance != null and face_instance.mesh is ArrayMesh:
		_validate_mesh(face_instance.mesh as ArrayMesh, metrics["face_triangle_count"], "face")
	if (
		top_instance != null
		and top_instance.mesh is ArrayMesh
		and face_instance != null
		and face_instance.mesh is ArrayMesh
		and collision_body != null
	):
		_validate_shared_sample_stream(
			top_instance.mesh as ArrayMesh,
			face_instance.mesh as ArrayMesh,
			collision_body,
			first_samples,
			side_ids
		)

	_expect(
		PROMONTORY_FRONT.supports_top_point(Vector3(-9.0, 4.015, -2.0)),
		"The 3D support query accepts a point on the west cap."
	)
	_expect(
		not PROMONTORY_FRONT.supports_top_point(Vector3(-9.0, 3.5, -0.35)),
		"The 3D support query rejects a point below the top plane."
	)

	print(
		"UPPER_PROMONTORY_FRONT_METRICS: samples=%d segments=%d prisms=%d plateaus=%d transitions=%d max_spacing=%.3f max_snap=%.3f river_clearance=%.3f gap=%.3f"
		% [
			metrics["sample_count"],
			metrics["segment_count"],
			metrics["collision_prism_count"],
			plateau_segment_count,
			transition_segment_count,
			metrics["maximum_sample_spacing"],
			metrics["maximum_snap_error"],
			minimum_river_clearance,
			metrics["stair_gap_width"],
		]
	)
	_finish()


func _validate_collision_prisms(body: StaticBody3D) -> void:
	for child: Node in body.get_children():
		var collision := child as CollisionShape3D
		_expect(collision != null, "Every collision-body child is a CollisionShape3D.")
		if collision == null:
			continue
		var shape := collision.shape as ConvexPolygonShape3D
		_expect(shape != null, "%s uses a ConvexPolygonShape3D." % collision.name)
		if shape == null:
			continue
		_expect(shape.points.size() == 8, "%s is an eight-corner contour prism." % collision.name)
		var top_points: Array[Vector3] = []
		var base_points: Array[Vector3] = []
		for point: Vector3 in shape.points:
			if is_equal_approx(point.y, PROMONTORY_FRONT.TOP_Y):
				top_points.append(point)
			elif is_equal_approx(point.y, PROMONTORY_FRONT.BASE_Y):
				base_points.append(point)
		_expect(
			top_points.size() == 4 and base_points.size() == 4,
			"%s owns four top and four deep-base corners." % collision.name
		)
		for top_point: Vector3 in top_points:
			var matching_base := Vector3(
				top_point.x,
				PROMONTORY_FRONT.BASE_Y,
				top_point.z
			)
			_expect(
				base_points.has(matching_base),
				"%s keeps every deep collision column vertical and nondegenerate."
				% collision.name
			)


func _validate_mesh(mesh: ArrayMesh, expected_triangle_count: int, label: String) -> void:
	_expect(mesh.get_surface_count() == 1, "The %s ArrayMesh owns one deterministic surface." % label)
	if mesh.get_surface_count() != 1:
		return
	var arrays: Array = mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	_expect(
		vertices.size() == expected_triangle_count * 3,
		"The %s ArrayMesh has exactly three vertices per reported triangle." % label
	)


func _validate_shared_sample_stream(
	top_mesh: ArrayMesh,
	face_mesh: ArrayMesh,
	collision_body: StaticBody3D,
	samples_by_side: Dictionary,
	side_ids: PackedStringArray
) -> void:
	var top_vertices: PackedVector3Array = top_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var face_vertices: PackedVector3Array = face_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var segment_index := 0
	for side: StringName in side_ids:
		var samples: PackedVector2Array = samples_by_side[side] as PackedVector2Array
		for sample_index: int in range(samples.size() - 1):
			var left: Vector2 = samples[sample_index]
			var right: Vector2 = samples[sample_index + 1]
			var expected_left := Vector3(left.x, PROMONTORY_FRONT.TOP_Y, left.y)
			var expected_right := Vector3(right.x, PROMONTORY_FRONT.TOP_Y, right.y)
			var expected_left_base := Vector3(left.x, PROMONTORY_FRONT.BASE_Y, left.y)
			var expected_right_base := Vector3(right.x, PROMONTORY_FRONT.BASE_Y, right.y)
			var vertex_offset := segment_index * 6
			_expect(
				top_vertices[vertex_offset + 2].is_equal_approx(expected_left)
				and top_vertices[vertex_offset + 1].is_equal_approx(expected_right),
				"Top segment %d follows the shared voxel endpoints." % segment_index
			)
			_expect(
				face_vertices[vertex_offset].is_equal_approx(expected_left)
					and face_vertices[vertex_offset + 4].is_equal_approx(expected_right)
					and face_vertices[vertex_offset + 2].is_equal_approx(expected_left_base)
					and face_vertices[vertex_offset + 1].is_equal_approx(expected_right_base)
					and face_vertices[vertex_offset + 5].is_equal_approx(expected_right_base),
				"Face segment %d follows the shared voxel endpoints through the deep base."
				% segment_index
			)
			var collision := collision_body.get_child(segment_index) as CollisionShape3D
			var shape := collision.shape as ConvexPolygonShape3D
			_expect(
				shape.points.has(expected_left) and shape.points.has(expected_right),
				"Collision prism %d follows the shared voxel endpoints." % segment_index
			)
			segment_index += 1


func _finish() -> void:
	if _failures.is_empty():
		print("UPPER_PROMONTORY_FRONT_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("UPPER_PROMONTORY_FRONT_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

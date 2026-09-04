extends Node

const TrailRibbon: Script = preload("res://features/homestead_3d/trail_ribbon_3d.gd")
const EPSILON := 0.0001
const MINIMUM_PROJECTED_TRIANGLE_AREA := 0.000001

var _failures: Array[String] = []


func _ready() -> void:
	var courtyard_points := PackedVector3Array([
		Vector3(0.0, 4.092, -0.25),
		Vector3(-1.636912, 4.092, -0.114733),
		Vector3(2.500111, 4.092, 2.991638),
		Vector3(4.710259, 4.092, 2.528328),
		Vector3(6.313698, 4.092, 1.661376),
	])
	_validate_ribbon("courtyard sweep", courtyard_points, 3.38)

	var sharp_turn_points := PackedVector3Array([
		Vector3(-7.0, 0.1, -1.0),
		Vector3(-1.0, 0.3, -0.8),
		Vector3(-2.1, 0.5, -0.1),
		Vector3(5.5, 0.8, 4.8),
		Vector3(7.0, 1.0, 2.1),
	])
	_validate_ribbon("sharp long turn", sharp_turn_points, 2.8)
	_finish()


func _validate_ribbon(label: String, points: PackedVector3Array, width: float) -> void:
	var source_material := StandardMaterial3D.new()
	var ribbon := TrailRibbon.new() as TrailRibbon3D
	ribbon.configure(points, width, source_material)
	add_child(ribbon)

	_expect(ribbon.get_start_point().is_equal_approx(points[0]), "%s preserves its exact start point." % label)
	_expect(ribbon.get_end_point().is_equal_approx(points[-1]), "%s preserves its exact end point." % label)
	_expect(is_equal_approx(ribbon.route_width, width), "%s preserves the configured full-width semantic." % label)
	var render_points: PackedVector3Array = ribbon.get_render_points()
	_expect(render_points[0].is_equal_approx(points[0]), "%s rendering begins at the authored endpoint." % label)
	_expect(render_points[-1].is_equal_approx(points[-1]), "%s rendering ends at the authored endpoint." % label)
	for control: Vector3 in points:
		_expect(render_points.has(control), "%s bounded curve passes through authored control %s." % [label, control])
	_validate_centerline(render_points, label)

	var array_mesh := ribbon.mesh as ArrayMesh
	_expect(array_mesh != null and array_mesh.get_surface_count() == 1, "%s produces one mesh surface." % label)
	if array_mesh == null or array_mesh.get_surface_count() != 1:
		return
	var arrays: Array = array_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	_expect(vertices.size() >= 3 and vertices.size() % 3 == 0, "%s contains complete triangles." % label)
	_expect(normals.size() == vertices.size(), "%s has one generated normal per vertex." % label)
	_expect(uvs.size() == vertices.size(), "%s has one UV per vertex." % label)
	_validate_triangles(vertices, normals, label)
	_validate_uvs(vertices, uvs, label)
	_validate_flat_caps(vertices, render_points, width, label)
	_validate_determinism(points, width, vertices, uvs, label)


func _validate_centerline(points: PackedVector3Array, label: String) -> void:
	for index: int in range(points.size() - 1):
		var segment_length := Vector2(points[index].x, points[index].z).distance_to(
			Vector2(points[index + 1].x, points[index + 1].z)
		)
		_expect(segment_length > EPSILON, "%s has no duplicate render stations at %d." % [label, index])
	for first_index: int in range(points.size() - 1):
		var first_a := Vector2(points[first_index].x, points[first_index].z)
		var first_b := Vector2(points[first_index + 1].x, points[first_index + 1].z)
		for second_index: int in range(first_index + 2, points.size() - 1):
			if second_index == first_index + 1:
				continue
			var second_a := Vector2(points[second_index].x, points[second_index].z)
			var second_b := Vector2(points[second_index + 1].x, points[second_index + 1].z)
			_expect(
				not _segments_cross_strictly(first_a, first_b, second_a, second_b),
				"%s centerline does not self-cross at segments %d and %d." % [label, first_index, second_index]
			)


func _validate_triangles(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	label: String
) -> void:
	var triangles: Array[PackedVector2Array] = []
	for index: int in range(0, vertices.size(), 3):
		var a: Vector3 = vertices[index]
		var b: Vector3 = vertices[index + 1]
		var c: Vector3 = vertices[index + 2]
		var projected_area: float = (b - a).cross(c - a).dot(Vector3.UP)
		_expect(
			projected_area < -MINIMUM_PROJECTED_TRIANGLE_AREA,
			"%s triangle %d has non-degenerate clockwise top-face winding." % [label, index / 3]
		)
		_expect(
			normals[index].dot(Vector3.UP) > 0.0
			and normals[index + 1].dot(Vector3.UP) > 0.0
			and normals[index + 2].dot(Vector3.UP) > 0.0,
			"%s triangle %d exposes its lit face upward." % [label, index / 3]
		)
		triangles.append(PackedVector2Array([
			Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z),
		]))

	for first_index: int in range(triangles.size()):
		for second_index: int in range(first_index + 1, triangles.size()):
			var intersections: Array[PackedVector2Array] = Geometry2D.intersect_polygons(
				triangles[first_index], triangles[second_index]
			)
			var overlap_area := 0.0
			for intersection: PackedVector2Array in intersections:
				overlap_area += absf(_polygon_area(intersection))
			_expect(
				overlap_area <= MINIMUM_PROJECTED_TRIANGLE_AREA,
				"%s triangles %d and %d do not overlap in their interiors." % [label, first_index, second_index]
			)


func _validate_uvs(
	vertices: PackedVector3Array,
	uvs: PackedVector2Array,
	label: String
) -> void:
	var uv_by_position: Dictionary = {}
	for index: int in range(vertices.size()):
		var vertex: Vector3 = vertices[index]
		var expected_uv := Vector2(vertex.x, vertex.z)
		_expect(uvs[index].is_equal_approx(expected_uv), "%s uses continuous world-space UVs." % label)
		var key := "%0.5f,%0.5f,%0.5f" % [vertex.x, vertex.y, vertex.z]
		if uv_by_position.has(key):
			_expect(
				(uv_by_position[key] as Vector2).is_equal_approx(uvs[index]),
				"%s gives shared vertices identical UVs." % label
			)
		else:
			uv_by_position[key] = uvs[index]


func _validate_flat_caps(
	vertices: PackedVector3Array,
	render_points: PackedVector3Array,
	width: float,
	label: String
) -> void:
	var start_direction := Vector2(
		render_points[1].x - render_points[0].x,
		render_points[1].z - render_points[0].z
	).normalized()
	var end_direction := Vector2(
		render_points[-1].x - render_points[-2].x,
		render_points[-1].z - render_points[-2].z
	).normalized()
	var start_side := Vector2(-start_direction.y, start_direction.x) * width * 0.5
	var end_side := Vector2(-end_direction.y, end_direction.x) * width * 0.5
	var start := Vector2(render_points[0].x, render_points[0].z)
	var finish := Vector2(render_points[-1].x, render_points[-1].z)
	_expect(_covers_xz(vertices, start + start_side), "%s start cap reaches positive nominal half-width." % label)
	_expect(_covers_xz(vertices, start - start_side), "%s start cap reaches negative nominal half-width." % label)
	_expect(_covers_xz(vertices, finish + end_side), "%s end cap reaches positive nominal half-width." % label)
	_expect(_covers_xz(vertices, finish - end_side), "%s end cap reaches negative nominal half-width." % label)


func _validate_determinism(
	points: PackedVector3Array,
	width: float,
	expected_vertices: PackedVector3Array,
	expected_uvs: PackedVector2Array,
	label: String
) -> void:
	var repeated := TrailRibbon.new() as TrailRibbon3D
	repeated.configure(points, width, StandardMaterial3D.new())
	var repeated_mesh := repeated.mesh as ArrayMesh
	var arrays: Array = repeated_mesh.surface_get_arrays(0)
	_expect(arrays[Mesh.ARRAY_VERTEX] == expected_vertices, "%s vertices are deterministic." % label)
	_expect(arrays[Mesh.ARRAY_TEX_UV] == expected_uvs, "%s UVs are deterministic." % label)
	repeated.free()


func _covers_xz(vertices: PackedVector3Array, expected: Vector2) -> bool:
	for vertex: Vector3 in vertices:
		if Vector2(vertex.x, vertex.z).distance_to(expected) <= EPSILON:
			return true
	for index: int in range(0, vertices.size(), 3):
		var triangle := PackedVector2Array([
			Vector2(vertices[index].x, vertices[index].z),
			Vector2(vertices[index + 1].x, vertices[index + 1].z),
			Vector2(vertices[index + 2].x, vertices[index + 2].z),
		])
		if Geometry2D.is_point_in_polygon(expected, triangle):
			return true
	return false


func _segments_cross_strictly(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var ab_c: float = (b - a).cross(c - a)
	var ab_d: float = (b - a).cross(d - a)
	var cd_a: float = (d - c).cross(a - c)
	var cd_b: float = (d - c).cross(b - c)
	return ab_c * ab_d < -EPSILON and cd_a * cd_b < -EPSILON


func _polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for index: int in range(polygon.size()):
		area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	return area * 0.5


func _finish() -> void:
	if _failures.is_empty():
		print("TRAIL_RIBBON_3D_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("TRAIL_RIBBON_3D_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

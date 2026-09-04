class_name TrailRibbon3D
extends MeshInstance3D

const VISUAL_SURFACE_LIFT := Vector3(0.0, 0.035, 0.0)
const TONAL_VALUE_SEED := 3107
const TONAL_HUE_SEED := 7919
const TONAL_VALUE_FREQUENCY := 0.18
const TONAL_HUE_FREQUENCY := 0.31
const TONAL_VALUE_STRENGTH := 0.115
const TONAL_HUE_STRENGTH := 0.045
const TONAL_FACTOR_MIN := 0.84
const TONAL_FACTOR_MAX := 1.16
const CURVE_TANGENT_SCALE := 0.42
const SEGMENT_TANGENT_LIMIT := 0.5
const MINIMUM_TRIANGLE_AREA := 0.000001

var route_points: PackedVector3Array = PackedVector3Array()
var route_width: float = 1.8
var _value_noise := FastNoiseLite.new()
var _hue_noise := FastNoiseLite.new()


func _init() -> void:
	_value_noise.seed = TONAL_VALUE_SEED
	_value_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_value_noise.frequency = TONAL_VALUE_FREQUENCY
	_value_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_value_noise.fractal_octaves = 2
	_value_noise.fractal_gain = 0.45
	_hue_noise.seed = TONAL_HUE_SEED
	_hue_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_hue_noise.frequency = TONAL_HUE_FREQUENCY
	_hue_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_hue_noise.fractal_octaves = 2
	_hue_noise.fractal_gain = 0.4


func configure(points: PackedVector3Array, width: float, material: Material) -> void:
	route_points = points
	route_width = width
	material_override = _make_local_variation_material(material)
	mesh = _build_ribbon()


func get_start_point() -> Vector3:
	return route_points[0] if not route_points.is_empty() else Vector3.ZERO


func get_end_point() -> Vector3:
	return route_points[-1] if not route_points.is_empty() else Vector3.ZERO


func get_render_points(samples_per_segment: int = 5) -> PackedVector3Array:
	return _build_smoothed_points(maxi(samples_per_segment, 1))


func _build_ribbon() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if route_points.size() < 2:
		return surface.commit()
	var render_points := get_render_points()
	if render_points.size() < 2 or route_width <= 0.0:
		return surface.commit()

	# Geometry2D's offset operation resolves acute joins and centerline overlaps into
	# simple outlines before triangulation. Building a left/right triangle strip
	# directly is unsafe here: a tight turn can reverse the two rails and create
	# overlapping, downward-facing triangles.
	var centerline_2d := PackedVector2Array()
	for point: Vector3 in render_points:
		centerline_2d.append(Vector2(point.x, point.z))
	var footprints: Array[PackedVector2Array] = Geometry2D.offset_polyline(
		centerline_2d,
		route_width * 0.5,
		Geometry2D.JOIN_ROUND,
		Geometry2D.END_BUTT
	)
	for footprint: PackedVector2Array in footprints:
		var triangle_indices: PackedInt32Array = Geometry2D.triangulate_polygon(footprint)
		for triangle_index: int in range(0, triangle_indices.size(), 3):
			var point_a := _surface_point(footprint[triangle_indices[triangle_index]], render_points)
			var point_b := _surface_point(footprint[triangle_indices[triangle_index + 1]], render_points)
			var point_c := _surface_point(footprint[triangle_indices[triangle_index + 2]], render_points)
			_add_upward_triangle(surface, point_a, point_b, point_c)
	surface.generate_normals()
	return surface.commit()


func _build_smoothed_points(samples_per_segment: int) -> PackedVector3Array:
	var smoothed := PackedVector3Array()
	if route_points.is_empty():
		return smoothed
	var control_tangents := PackedVector3Array()
	for control_index: int in range(route_points.size()):
		control_tangents.append(_control_tangent(control_index))
	for segment: int in range(route_points.size() - 1):
		var p1: Vector3 = route_points[segment]
		var p2: Vector3 = route_points[segment + 1]
		var segment_length: float = p1.distance_to(p2)
		if segment_length <= 0.00001:
			if smoothed.is_empty() or not smoothed[-1].is_equal_approx(p1):
				smoothed.append(p1)
			continue
		var tangent_limit: float = segment_length * SEGMENT_TANGENT_LIMIT
		var start_tangent: Vector3 = control_tangents[segment].limit_length(tangent_limit)
		var end_tangent: Vector3 = control_tangents[segment + 1].limit_length(tangent_limit)
		for sample: int in range(samples_per_segment):
			var t: float = float(sample) / float(samples_per_segment)
			var t2: float = t * t
			var t3: float = t2 * t
			var point: Vector3 = \
				(2.0 * t3 - 3.0 * t2 + 1.0) * p1 \
				+ (t3 - 2.0 * t2 + t) * start_tangent \
				+ (-2.0 * t3 + 3.0 * t2) * p2 \
				+ (t3 - t2) * end_tangent
			smoothed.append(point)
	if smoothed.is_empty() or not smoothed[-1].is_equal_approx(route_points[-1]):
		smoothed.append(route_points[-1])
	return smoothed


func _control_tangent(index: int) -> Vector3:
	if route_points.size() < 2:
		return Vector3.ZERO
	if index == 0:
		return (route_points[1] - route_points[0]) * CURVE_TANGENT_SCALE
	if index == route_points.size() - 1:
		return (route_points[-1] - route_points[-2]) * CURVE_TANGENT_SCALE

	var incoming: Vector3 = route_points[index] - route_points[index - 1]
	var outgoing: Vector3 = route_points[index + 1] - route_points[index]
	var incoming_length: float = incoming.length()
	var outgoing_length: float = outgoing.length()
	if incoming_length <= 0.00001:
		return outgoing * CURVE_TANGENT_SCALE
	if outgoing_length <= 0.00001:
		return incoming * CURVE_TANGENT_SCALE
	var direction: Vector3 = incoming / incoming_length + outgoing / outgoing_length
	if direction.is_zero_approx():
		return Vector3.ZERO
	return direction.normalized() * minf(incoming_length, outgoing_length) * CURVE_TANGENT_SCALE


func _surface_point(point: Vector2, render_points: PackedVector3Array) -> Vector3:
	var nearest_distance_squared := INF
	var nearest_height: float = render_points[0].y
	for index: int in range(render_points.size() - 1):
		var start_2d := Vector2(render_points[index].x, render_points[index].z)
		var end_2d := Vector2(render_points[index + 1].x, render_points[index + 1].z)
		var segment := end_2d - start_2d
		var length_squared: float = segment.length_squared()
		if length_squared <= 0.0000001:
			continue
		var t: float = clampf((point - start_2d).dot(segment) / length_squared, 0.0, 1.0)
		var projected: Vector2 = start_2d + segment * t
		var distance_squared: float = point.distance_squared_to(projected)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_height = lerpf(render_points[index].y, render_points[index + 1].y, t)
	return Vector3(point.x, nearest_height, point.y)


func _add_upward_triangle(
	surface: SurfaceTool,
	point_a: Vector3,
	point_b: Vector3,
	point_c: Vector3
) -> void:
	var normal: Vector3 = (point_b - point_a).cross(point_c - point_a)
	if absf(normal.dot(Vector3.UP)) <= MINIMUM_TRIANGLE_AREA:
		return
	# Godot treats clockwise winding as the front face. On the XZ ground plane
	# that winding has a negative cross-product Y while generate_normals() yields
	# the desired upward lighting normal.
	if normal.dot(Vector3.UP) > 0.0:
		var swap := point_b
		point_b = point_c
		point_c = swap
	# Planar world-space UVs remain single-valued even where a hairpin's buffered
	# footprint merges with itself. Path-distance UVs necessarily split there.
	_add_vertex(surface, point_a, Vector2(point_a.x, point_a.z), _sample_tone(point_a))
	_add_vertex(surface, point_b, Vector2(point_b.x, point_b.z), _sample_tone(point_b))
	_add_vertex(surface, point_c, Vector2(point_c.x, point_c.z), _sample_tone(point_c))


func _sample_tone(point: Vector3) -> Color:
	var value_offset: float = _value_noise.get_noise_2d(point.x, point.z) * TONAL_VALUE_STRENGTH
	var hue_offset: float = _hue_noise.get_noise_2d(point.x, point.z) * TONAL_HUE_STRENGTH
	return Color(
		clampf(1.0 + value_offset + hue_offset, TONAL_FACTOR_MIN, TONAL_FACTOR_MAX),
		clampf(1.0 + value_offset + hue_offset * 0.15, TONAL_FACTOR_MIN, TONAL_FACTOR_MAX),
		clampf(1.0 + value_offset - hue_offset, TONAL_FACTOR_MIN, TONAL_FACTOR_MAX),
		1.0
	)


func _make_local_variation_material(source_material: Material) -> Material:
	if source_material == null:
		return null
	var local_material := source_material.duplicate() as Material
	if local_material is BaseMaterial3D:
		(local_material as BaseMaterial3D).vertex_color_use_as_albedo = true
	return local_material


func _add_vertex(surface: SurfaceTool, point: Vector3, uv: Vector2, tone: Color) -> void:
	surface.set_uv(uv)
	surface.set_color(tone)
	surface.add_vertex(point + VISUAL_SURFACE_LIFT)

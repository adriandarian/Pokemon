class_name TrailRibbon3D
extends MeshInstance3D

var route_points: PackedVector3Array = PackedVector3Array()
var route_width: float = 1.8


func configure(points: PackedVector3Array, width: float, material: Material) -> void:
	route_points = points
	route_width = width
	material_override = material
	mesh = _build_ribbon()


func get_start_point() -> Vector3:
	return route_points[0] if not route_points.is_empty() else Vector3.ZERO


func get_end_point() -> Vector3:
	return route_points[-1] if not route_points.is_empty() else Vector3.ZERO


func _build_ribbon() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if route_points.size() < 2:
		return surface.commit()
	var render_points := _build_smoothed_points(5)

	var left_edges: PackedVector3Array = PackedVector3Array()
	var right_edges: PackedVector3Array = PackedVector3Array()
	for index: int in range(render_points.size()):
		var previous: Vector3 = render_points[maxi(index - 1, 0)]
		var following: Vector3 = render_points[mini(index + 1, render_points.size() - 1)]
		var tangent := following - previous
		tangent.y = 0.0
		if tangent.is_zero_approx():
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()
		var edge_variation: float = 0.5 + sin(float(index) * 1.73) * 0.035
		if index == 0 or index == render_points.size() - 1:
			edge_variation = 0.5
		var side := Vector3(-tangent.z, 0.0, tangent.x) * route_width * edge_variation
		left_edges.append(render_points[index] + side)
		right_edges.append(render_points[index] - side)

	var travelled: float = 0.0
	for index: int in range(render_points.size() - 1):
		if index > 0:
			travelled += render_points[index - 1].distance_to(render_points[index])
		var next_distance: float = travelled + render_points[index].distance_to(render_points[index + 1])
		_add_vertex(surface, left_edges[index], Vector2(0.0, travelled))
		_add_vertex(surface, right_edges[index], Vector2(1.0, travelled))
		_add_vertex(surface, right_edges[index + 1], Vector2(1.0, next_distance))
		_add_vertex(surface, left_edges[index], Vector2(0.0, travelled))
		_add_vertex(surface, right_edges[index + 1], Vector2(1.0, next_distance))
		_add_vertex(surface, left_edges[index + 1], Vector2(0.0, next_distance))
	surface.generate_normals()
	return surface.commit()


func _build_smoothed_points(samples_per_segment: int) -> PackedVector3Array:
	var smoothed := PackedVector3Array()
	for segment: int in range(route_points.size() - 1):
		var p0: Vector3 = route_points[maxi(segment - 1, 0)]
		var p1: Vector3 = route_points[segment]
		var p2: Vector3 = route_points[segment + 1]
		var p3: Vector3 = route_points[mini(segment + 2, route_points.size() - 1)]
		for sample: int in range(samples_per_segment):
			var t: float = float(sample) / float(samples_per_segment)
			var t2: float = t * t
			var t3: float = t2 * t
			var point: Vector3 = 0.5 * (
				2.0 * p1
				+ (-p0 + p2) * t
				+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
				+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
			)
			smoothed.append(point)
	smoothed.append(route_points[-1])
	return smoothed


func _add_vertex(surface: SurfaceTool, point: Vector3, uv: Vector2) -> void:
	surface.set_uv(uv)
	surface.add_vertex(point)

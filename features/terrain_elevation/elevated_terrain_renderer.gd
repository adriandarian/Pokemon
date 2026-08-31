class_name ElevatedTerrainRenderer
extends Node2D

const ElevationMap = preload("res://features/terrain_elevation/terrain_elevation_map.gd")
const GRASS_TOP: Texture2D = preload("res://assets/voxel/terrain_grass_top_v3.png")
const CLIFF_FACE: Texture2D = preload("res://assets/voxel/terrain_cliff_face_v2.png")


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()


func _draw() -> void:
	_draw_base_ground()
	_draw_terrace(
		ElevationMap.RIDGE_FOOTPRINT,
		ElevationMap.RIDGE_FRONT_SEGMENTS,
		ElevationMap.RIDGE_LEVEL,
		Color(0.46, 0.56, 0.4, 0.92)
	)
	_draw_terrace(
		ElevationMap.VILLAGE_FOOTPRINT,
		ElevationMap.VILLAGE_FRONT_SEGMENTS,
		ElevationMap.VILLAGE_LEVEL,
		Color(0.62, 0.72, 0.51, 0.94)
	)
	_draw_terrace(
		ElevationMap.WILDS_FOOTPRINT,
		ElevationMap.WILDS_FRONT_SEGMENTS,
		ElevationMap.WILDS_LEVEL,
		Color(0.4, 0.57, 0.36, 0.93)
	)
	_draw_lodge_foundation()


func _draw_base_ground() -> void:
	draw_rect(ElevationMap.WORLD_RECT, Color("557a50"))
	draw_texture_rect(GRASS_TOP, ElevationMap.WORLD_RECT, true, Color(0.52, 0.62, 0.46, 0.86))
	draw_rect(ElevationMap.WORLD_RECT, Color(0.09, 0.2, 0.14, 0.18))


func _draw_terrace(
	footprint: PackedVector2Array,
	front_segments: Array[PackedVector2Array],
	level: float,
	top_tint: Color
) -> void:
	for segment: PackedVector2Array in front_segments:
		_draw_cliff_face(segment, level)

	var projected: PackedVector2Array = ElevationMap.project_points(footprint, level)
	var uv := PackedVector2Array()
	for point: Vector2 in footprint:
		uv.append(point * 0.72)
	draw_colored_polygon(projected, Color("6f965c"))
	draw_polygon(projected, PackedColorArray([top_tint]), uv, GRASS_TOP)
	var outline := projected.duplicate()
	outline.append(projected[0])
	draw_polyline(outline, Color(0.25, 0.38, 0.27, 0.6), 3.0, true)
	draw_polyline(outline, Color(0.68, 0.78, 0.5, 0.34), 1.0, true)


func _draw_cliff_face(segment: PackedVector2Array, level: float) -> void:
	if segment.size() < 2:
		return
	var height_pixels: float = level * ElevationMap.PIXELS_PER_LEVEL
	var face := PackedVector2Array()
	var uv := PackedVector2Array()
	var distance_along: float = 0.0
	for index: int in range(segment.size()):
		if index > 0:
			distance_along += segment[index - 1].distance_to(segment[index])
		face.append(ElevationMap.to_view(segment[index], level))
		uv.append(Vector2(distance_along * 1.4, 0.0))
	for reverse_index: int in range(segment.size() - 1, -1, -1):
		var bottom_point: Vector2 = segment[reverse_index]
		var reverse_distance: float = 0.0
		for distance_index: int in range(reverse_index):
			reverse_distance += segment[distance_index].distance_to(segment[distance_index + 1])
		face.append(bottom_point)
		uv.append(Vector2(reverse_distance * 1.4, height_pixels * 7.0))
	draw_colored_polygon(face, Color("4b5948"))
	draw_polygon(face, PackedColorArray([Color(0.72, 0.76, 0.63, 0.9)]), uv, CLIFF_FACE)
	draw_polyline(segment, Color(0.12, 0.18, 0.14, 0.32), 2.0, true)


func _draw_lodge_foundation() -> void:
	var foundation: PackedVector2Array = ElevationMap.project_points(
		ElevationMap.LODGE_FOUNDATION,
		ElevationMap.VILLAGE_LEVEL
	)
	draw_colored_polygon(foundation, Color(0.19, 0.25, 0.19, 0.22))
	draw_line(foundation[3], foundation[2], Color(0.14, 0.2, 0.16, 0.42), 3.0, true)

class_name BattleBackdrop
extends Control

const GRASS_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_grass.png")


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("bdd8c7"))

	# Layered horizon planes keep the battle flat while matching the voxel world.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, size.y * 0.31), Vector2(size.x * 0.12, size.y * 0.24),
		Vector2(size.x * 0.26, size.y * 0.28), Vector2(size.x * 0.40, size.y * 0.20),
		Vector2(size.x * 0.58, size.y * 0.25), Vector2(size.x * 0.76, size.y * 0.18),
		Vector2(size.x, size.y * 0.23), Vector2(size.x, size.y * 0.48),
		Vector2(0.0, size.y * 0.54),
	]), Color("567d5d"))

	var terrain_rect := Rect2(0.0, size.y * 0.22, size.x, size.y * 0.78)
	draw_texture_rect(GRASS_TEXTURE, terrain_rect, false, Color(0.58, 0.69, 0.50, 0.84))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, size.y * 0.39), Vector2(size.x * 0.23, size.y * 0.32),
		Vector2(size.x * 0.48, size.y * 0.37), Vector2(size.x * 0.73, size.y * 0.29),
		Vector2(size.x, size.y * 0.34), Vector2(size.x, size.y), Vector2(0.0, size.y),
	]), Color(0.19, 0.40, 0.23, 0.27))
	draw_polyline(PackedVector2Array([
		Vector2(0.0, size.y * 0.39), Vector2(size.x * 0.23, size.y * 0.32),
		Vector2(size.x * 0.48, size.y * 0.37), Vector2(size.x * 0.73, size.y * 0.29),
		Vector2(size.x, size.y * 0.34),
	]), Color(0.72, 0.84, 0.51, 0.43), 8.0, true)

	for index: int in range(12):
		var x: float = size.x * (0.02 + float(index) * 0.09)
		var y: float = size.y * (0.31 - float(index % 3) * 0.035)
		_draw_voxel_tree(Vector2(x, y), 0.78 + float(index % 2) * 0.16)

	_draw_platform(Vector2(size.x * 0.73, size.y * 0.49), Vector2(size.x * 0.15, 48.0))
	_draw_platform(Vector2(size.x * 0.46, size.y * 0.64), Vector2(size.x * 0.18, 54.0))

	for index: int in range(18):
		var grass_x: float = size.x * (0.52 + float(index % 9) * 0.052)
		var grass_y: float = size.y * (0.60 + float(index / 9) * 0.075)
		_draw_grass_cluster(Vector2(grass_x, grass_y), 0.72 + float(index % 3) * 0.08)


func _draw_voxel_tree(base: Vector2, scale_factor: float) -> void:
	var trunk_size := Vector2(22.0, 72.0) * scale_factor
	draw_rect(Rect2(base.x - trunk_size.x * 0.5, base.y - trunk_size.y, trunk_size.x, trunk_size.y), Color("5d4430"))
	var block: float = 48.0 * scale_factor
	_draw_canopy_block(base + Vector2(-block * 0.4, -trunk_size.y - block * 0.16), block, Color("3f7548"))
	_draw_canopy_block(base + Vector2(block * 0.36, -trunk_size.y - block * 0.38), block, Color("527f50"))
	_draw_canopy_block(base + Vector2(0.0, -trunk_size.y - block * 0.92), block, Color("639258"))


func _draw_canopy_block(center: Vector2, block: float, color: Color) -> void:
	var radii := Vector2(block * 0.72, block * 0.42)
	var top := PackedVector2Array([
		center + Vector2(-radii.x, 0.0), center + Vector2(0.0, -radii.y),
		center + Vector2(radii.x, 0.0), center + Vector2(0.0, radii.y),
	])
	draw_colored_polygon(top, color.lightened(0.08))
	draw_colored_polygon(PackedVector2Array([
		top[0], top[3], top[3] + Vector2(0.0, block * 0.34), top[0] + Vector2(0.0, block * 0.34),
	]), color.darkened(0.18))
	draw_colored_polygon(PackedVector2Array([
		top[3], top[2], top[2] + Vector2(0.0, block * 0.34), top[3] + Vector2(0.0, block * 0.34),
	]), color.darkened(0.3))


func _draw_platform(center: Vector2, radii: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radii.x, 0.0), center + Vector2(0.0, -radii.y),
		center + Vector2(radii.x, 0.0), center + Vector2(0.0, radii.y),
	])
	draw_colored_polygon(PackedVector2Array([
		points[0] + Vector2(0.0, 8.0), points[3] + Vector2(0.0, 16.0),
		points[2] + Vector2(0.0, 8.0), points[3],
	]), Color(0.08, 0.19, 0.11, 0.27))
	draw_colored_polygon(points, Color(0.33, 0.54, 0.27, 0.34))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2]]), Color(0.78, 0.9, 0.58, 0.42), 5.0, true)


func _draw_grass_cluster(base: Vector2, scale_factor: float) -> void:
	var height: float = 27.0 * scale_factor
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-8.0, 0.0), base + Vector2(-6.0, -height),
		base + Vector2(0.0, -height - 5.0), base + Vector2(0.0, 0.0),
	]), Color("2f6f3d"))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(2.0, 0.0), base + Vector2(5.0, -height * 0.72),
		base + Vector2(12.0, -height * 0.9), base + Vector2(11.0, 0.0),
	]), Color("69a052"))

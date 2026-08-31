class_name AdventureWorldCanvas
extends Node2D

const GRASS_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_grass.png")
const WORLD_RECT := Rect2(0.0, 0.0, 2200.0, 1300.0)
static var WILD_POLYGON := PackedVector2Array([
	Vector2(1230.0, 246.0), Vector2(1435.0, 220.0), Vector2(1775.0, 234.0),
	Vector2(2010.0, 290.0), Vector2(2044.0, 510.0), Vector2(2020.0, 785.0),
	Vector2(1935.0, 960.0), Vector2(1605.0, 982.0), Vector2(1320.0, 930.0),
	Vector2(1202.0, 768.0),
])


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()


func _draw() -> void:
	_draw_continuous_ground()
	_draw_northern_ridge()
	_draw_land_contours()
	_draw_wild_preserve()
	_draw_trail()
	_draw_world_details()
	_draw_fence()


func _draw_continuous_ground() -> void:
	draw_rect(WORLD_RECT, Color("668e5d"))
	draw_texture_rect(GRASS_TEXTURE, WORLD_RECT, false, Color(0.68, 0.76, 0.61, 0.82))
	draw_rect(WORLD_RECT, Color(0.16, 0.28, 0.19, 0.13))


func _draw_northern_ridge() -> void:
	var ridge_face := PackedVector2Array([
		Vector2(0.0, 64.0), Vector2(142.0, 44.0), Vector2(286.0, 70.0),
		Vector2(448.0, 30.0), Vector2(630.0, 58.0), Vector2(820.0, 24.0),
		Vector2(1020.0, 54.0), Vector2(1220.0, 28.0), Vector2(1430.0, 62.0),
		Vector2(1660.0, 32.0), Vector2(1885.0, 56.0), Vector2(2200.0, 18.0),
		Vector2(2200.0, 220.0), Vector2(0.0, 220.0),
	])
	draw_colored_polygon(ridge_face, Color(0.16, 0.31, 0.23, 0.82))
	draw_polyline(PackedVector2Array([
		Vector2(0.0, 202.0), Vector2(325.0, 194.0), Vector2(670.0, 210.0),
		Vector2(1035.0, 188.0), Vector2(1410.0, 205.0), Vector2(1760.0, 191.0),
		Vector2(2200.0, 204.0),
	]), Color("779d65"), 28.0, true)
	draw_polyline(PackedVector2Array([
		Vector2(0.0, 215.0), Vector2(325.0, 207.0), Vector2(670.0, 223.0),
		Vector2(1035.0, 201.0), Vector2(1410.0, 218.0), Vector2(1760.0, 204.0),
		Vector2(2200.0, 217.0),
	]), Color("294e42"), 12.0, true)
	for index: int in range(17):
		var center := Vector2(52.0 + float(index) * 136.0, 188.0 + float(index % 3) * 7.0)
		_draw_voxel_top(center, Vector2(44.0, 16.0), Color("86aa6b"), Color("426c50"))


func _draw_land_contours() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(318.0, 352.0), Vector2(545.0, 252.0), Vector2(905.0, 272.0),
		Vector2(1190.0, 410.0), Vector2(1208.0, 744.0), Vector2(1000.0, 982.0),
		Vector2(585.0, 1055.0), Vector2(332.0, 898.0),
	]), Color(0.62, 0.76, 0.48, 0.18))
	draw_polyline(PackedVector2Array([
		Vector2(338.0, 378.0), Vector2(552.0, 292.0), Vector2(887.0, 304.0),
		Vector2(1144.0, 426.0),
	]), Color(0.83, 0.9, 0.6, 0.18), 8.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(920.0, 1010.0), Vector2(1220.0, 926.0), Vector2(1535.0, 1015.0),
		Vector2(1705.0, 1300.0), Vector2(760.0, 1300.0),
	]), Color(0.2, 0.38, 0.24, 0.13))


func _draw_wild_preserve() -> void:
	draw_colored_polygon(WILD_POLYGON, Color(0.12, 0.34, 0.18, 0.54))
	var closed_outline := WILD_POLYGON.duplicate()
	closed_outline.append(WILD_POLYGON[0])
	draw_polyline(closed_outline, Color("305f3d"), 26.0, true)
	draw_polyline(closed_outline, Color(0.56, 0.73, 0.39, 0.54), 7.0, true)

	for row: int in range(9):
		for column: int in range(13):
			var jitter_x: float = float((row * 31 + column * 17) % 29) - 14.0
			var jitter_y: float = float((row * 13 + column * 23) % 21) - 10.0
			var base := Vector2(1270.0 + float(column) * 59.0 + jitter_x, 300.0 + float(row) * 72.0 + jitter_y)
			if not Geometry2D.is_point_in_polygon(base, WILD_POLYGON):
				continue
			_draw_grass_cluster(base, 0.82 + float((row + column) % 3) * 0.11)


func _draw_trail() -> void:
	var path: PackedVector2Array = _build_trail_curve()
	draw_polyline(path, Color("8e714b"), 172.0, true)
	draw_polyline(path, Color("cbb371"), 156.0, true)
	draw_polyline(_offset_points(path, Vector2(-7.0, -8.0)), Color(0.96, 0.86, 0.56, 0.48), 9.0, true)

	for index: int in range(4, path.size() - 4, 9):
		var center: Vector2 = path[index]
		var accent := Color("b0925f") if index % 2 == 0 else Color("dfc982")
		_draw_voxel_top(center + Vector2(float(index % 3 - 1) * 26.0, 0.0), Vector2(14.0, 6.0), accent, Color("917146"))


func _build_trail_curve() -> PackedVector2Array:
	var anchors: Array[Vector2] = [
		Vector2(334.0, 1178.0), Vector2(548.0, 1020.0), Vector2(682.0, 786.0),
		Vector2(964.0, 698.0), Vector2(1235.0, 721.0), Vector2(1548.0, 574.0),
		Vector2(1825.0, 502.0), Vector2(2160.0, 470.0),
	]
	var curve := Curve2D.new()
	curve.bake_interval = 8.0
	for index: int in range(anchors.size()):
		var previous: Vector2 = anchors[maxi(0, index - 1)]
		var following: Vector2 = anchors[mini(anchors.size() - 1, index + 1)]
		var tangent: Vector2 = (following - previous) * 0.19
		curve.add_point(anchors[index], -tangent, tangent)
	return curve.get_baked_points()


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for point: Vector2 in points:
		shifted.append(point + offset)
	return shifted


func _draw_world_details() -> void:
	for index: int in range(42):
		var point := Vector2(356.0 + float((index * 149) % 1732), 255.0 + float((index * 97) % 940))
		if Geometry2D.is_point_in_polygon(point, WILD_POLYGON):
			continue
		var flower_color := Color("f1d46b") if index % 3 != 0 else Color("ef8176")
		_draw_voxel_top(point, Vector2(5.0, 3.0), flower_color, Color("47784a"))
		draw_rect(Rect2(point + Vector2(-2.0, 3.0), Vector2(4.0, 9.0)), Color("3b7044"))

	for index: int in range(18):
		var base := Vector2(430.0 + float((index * 113) % 1480), 320.0 + float((index * 191) % 820))
		if Geometry2D.is_point_in_polygon(base, WILD_POLYGON):
			continue
		_draw_grass_cluster(base, 0.58)


func _draw_fence() -> void:
	var rail_start := Vector2(430.0, 1208.0)
	var rail_end := Vector2(2160.0, 1208.0)
	draw_line(rail_start, rail_end, Color("5a3d2d"), 22.0, true)
	draw_line(rail_start + Vector2(0.0, -7.0), rail_end + Vector2(0.0, -7.0), Color("9b6840"), 10.0, true)
	for x: int in range(430, 2161, 120):
		var base := Vector2(float(x), 1236.0)
		draw_rect(Rect2(base + Vector2(-9.0, -58.0), Vector2(18.0, 58.0)), Color("59402f"))
		draw_rect(Rect2(base + Vector2(-5.0, -55.0), Vector2(10.0, 51.0)), Color("8c5e38"))
		_draw_voxel_top(base + Vector2(0.0, -58.0), Vector2(12.0, 6.0), Color("bd8550"), Color("6f4930"))


func _draw_grass_cluster(base: Vector2, scale_factor: float) -> void:
	var stem_height: float = 26.0 * scale_factor
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-8.0, 0.0), base + Vector2(-6.0, -stem_height),
		base + Vector2(1.0, -stem_height - 7.0), base + Vector2(0.0, 0.0),
	]), Color("2f6b3d"))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(2.0, 0.0), base + Vector2(5.0, -stem_height * 0.78),
		base + Vector2(12.0, -stem_height * 0.92), base + Vector2(11.0, 0.0),
	]), Color("76a554"))
	_draw_voxel_top(base + Vector2(-2.0, -stem_height), Vector2(7.0, 4.0), Color("94ba64"), Color("4d8348"))


func _draw_voxel_top(center: Vector2, radii: Vector2, top_color: Color, side_color: Color) -> void:
	var top := PackedVector2Array([
		center + Vector2(-radii.x, 0.0), center + Vector2(0.0, -radii.y),
		center + Vector2(radii.x, 0.0), center + Vector2(0.0, radii.y),
	])
	draw_colored_polygon(top, top_color)
	draw_colored_polygon(PackedVector2Array([
		top[0], top[3], top[3] + Vector2(0.0, 4.0), top[0] + Vector2(0.0, 4.0),
	]), side_color)

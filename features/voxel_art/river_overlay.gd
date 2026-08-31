class_name RiverOverlay
extends Node2D

const PIER_LANDING_CENTER := Vector2(379.0, 1043.0)

static var BANK_POINTS := PackedVector2Array([
	Vector2(286.0, -160.0), Vector2(282.0, 32.0), Vector2(296.0, 144.0),
	Vector2(276.0, 280.0), Vector2(278.0, 404.0), Vector2(292.0, 492.0), Vector2(276.0, 585.0),
	Vector2(298.0, 682.0), Vector2(282.0, 780.0), Vector2(304.0, 878.0),
	Vector2(286.0, 974.0), Vector2(306.0, 1072.0), Vector2(288.0, 1170.0),
	Vector2(300.0, 1460.0),
])


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_polyline(BANK_POINTS, Color("315f4c"), 34.0, true)
	draw_polyline(BANK_POINTS, Color("9abb79"), 21.0, true)
	draw_polyline(_offset_points(BANK_POINTS, Vector2(-4.0, -2.0)), Color(0.78, 0.91, 0.62, 0.72), 6.0, true)
	for index: int in range(1, BANK_POINTS.size() - 1, 2):
		_draw_bank_block(BANK_POINTS[index] + Vector2(-5.0, 0.0), index % 4 == 1)
	_draw_bridge()


func _offset_points(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var shifted := PackedVector2Array()
	for point: Vector2 in points:
		shifted.append(point + offset)
	return shifted


func _draw_bank_block(center: Vector2, bright: bool) -> void:
	var top_color := Color("b4c986") if bright else Color("7fa066")
	var points := PackedVector2Array([
		center + Vector2(-14.0, 0.0), center + Vector2(0.0, -7.0),
		center + Vector2(14.0, 0.0), center + Vector2(0.0, 7.0),
	])
	draw_colored_polygon(points, top_color)
	draw_colored_polygon(PackedVector2Array([
		points[0], points[3], points[3] + Vector2(0.0, 7.0), points[0] + Vector2(0.0, 7.0),
	]), Color("466b50"))


func _draw_bridge() -> void:
	var west_top := Vector2(20.0, 1049.0)
	var west_bottom := Vector2(142.0, 1118.0)
	var east_top := Vector2(320.0, 1008.0)
	var east_bottom := Vector2(438.0, 1077.0)
	draw_colored_polygon(PackedVector2Array([west_top, east_top, east_bottom, west_bottom]), Color("49352a"))

	const PLANK_COUNT: int = 11
	for index: int in range(PLANK_COUNT):
		var start_t: float = float(index) / float(PLANK_COUNT)
		var end_t: float = float(index + 1) / float(PLANK_COUNT) - 0.012
		var plank := PackedVector2Array([
			west_top.lerp(east_top, start_t), west_top.lerp(east_top, end_t),
			west_bottom.lerp(east_bottom, end_t), west_bottom.lerp(east_bottom, start_t),
		])
		var plank_color := Color("bd8048") if index % 2 == 0 else Color("a86e40")
		draw_colored_polygon(plank, plank_color)
		draw_polyline(PackedVector2Array([plank[0], plank[1]]), Color("d8a05a"), 3.0, true)

	draw_line(west_top, east_top, Color("3e3028"), 8.0, true)
	draw_line(west_bottom, east_bottom, Color("3e3028"), 8.0, true)
	for progress: float in [0.06, 0.5, 0.94]:
		_draw_bridge_post(west_top.lerp(east_top, progress))
		_draw_bridge_post(west_bottom.lerp(east_bottom, progress))


func _draw_bridge_post(base: Vector2) -> void:
	draw_rect(Rect2(base + Vector2(-5.0, -31.0), Vector2(10.0, 31.0)), Color("4a3429"))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-8.0, -31.0), base + Vector2(0.0, -36.0),
		base + Vector2(8.0, -31.0), base + Vector2(0.0, -26.0),
	]), Color("bb7a45"))

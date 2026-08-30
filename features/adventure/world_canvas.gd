class_name AdventureWorldCanvas
extends Node2D

const WORLD_RECT := Rect2(0.0, 0.0, 2200.0, 1300.0)
const WILD_RECT := Rect2(1260.0, 250.0, 720.0, 700.0)

var _wild_style_box := StyleBoxFlat.new()


func _ready() -> void:
	_wild_style_box.bg_color = Color("5f914f")
	_wild_style_box.border_color = Color("3e6e3e")
	_wild_style_box.set_border_width_all(10)
	_wild_style_box.set_corner_radius_all(70)
	queue_redraw()


func _draw() -> void:
	draw_rect(WORLD_RECT, Color("7fae68"))
	draw_rect(Rect2(0.0, 0.0, 2200.0, 210.0), Color("648f61"))

	# Distant tree line and soft parallax-like hill bands.
	for index: int in range(18):
		var x: float = 50.0 + float(index) * 128.0
		var height: float = 75.0 + float(index % 4) * 18.0
		draw_circle(Vector2(x, 185.0), height, Color("4f7957"))
		draw_circle(Vector2(x + 44.0, 165.0), height * 0.68, Color("5d8b5d"))

	# River and shallows.
	draw_rect(Rect2(0.0, 420.0, 310.0, 880.0), Color("4d9ca2"))
	draw_rect(Rect2(280.0, 420.0, 34.0, 880.0), Color(0.7, 0.9, 0.75, 0.45))
	for y: float in range(455, 1280, 72):
		draw_line(Vector2(38.0, y), Vector2(222.0, y - 20.0), Color(0.75, 0.96, 0.9, 0.35), 4.0, true)

	# Village path with a diagonal perspective-friendly route to the wilds.
	var trail := PackedVector2Array([
		Vector2(355.0, 1160.0), Vector2(560.0, 1000.0), Vector2(690.0, 770.0),
		Vector2(970.0, 700.0), Vector2(1240.0, 720.0), Vector2(1530.0, 590.0),
	])
	draw_polyline(trail, Color("d7c083"), 155.0, true)
	draw_polyline(trail, Color(0.92, 0.84, 0.58, 0.35), 118.0, true)

	# Bridge planks.
	draw_rect(Rect2(245.0, 1015.0, 170.0, 150.0), Color("8f6840"))
	for x: float in range(252, 410, 22):
		draw_line(Vector2(x, 1022.0), Vector2(x, 1158.0), Color("c49758"), 15.0)
	draw_line(Vector2(250.0, 1024.0), Vector2(410.0, 1024.0), Color("4f3828"), 8.0)
	draw_line(Vector2(250.0, 1156.0), Vector2(410.0, 1156.0), Color("4f3828"), 8.0)

	# Wild preserve, darker and denser than the village lawn.
	draw_style_box(_wild_style_box, WILD_RECT)
	for row: int in range(9):
		for column: int in range(11):
			var offset_x: float = float((row * 37 + column * 19) % 35)
			var base := Vector2(1300.0 + float(column) * 60.0 + offset_x, 300.0 + float(row) * 70.0)
			draw_line(base, base + Vector2(-7.0, -22.0), Color("417c42"), 5.0, true)
			draw_line(base, base + Vector2(8.0, -27.0), Color("5c9b4c"), 5.0, true)

	# Trail stones and flower flecks establish scale.
	for index: int in range(36):
		var point := Vector2(380.0 + float((index * 139) % 1660), 250.0 + float((index * 83) % 930))
		if WILD_RECT.has_point(point):
			continue
		var flower_color := Color("f2d766") if index % 2 == 0 else Color("f3a0a6")
		draw_circle(point, 4.0, flower_color)

	# Perimeter fence communicates a finite authored slice.
	for x: float in range(430, 2160, 120):
		draw_rect(Rect2(x, 1190.0, 10.0, 54.0), Color("65482f"))
		draw_line(Vector2(x, 1205.0), Vector2(x + 120.0, 1205.0), Color("8d6841"), 8.0)

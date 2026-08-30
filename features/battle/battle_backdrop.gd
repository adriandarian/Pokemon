class_name BattleBackdrop
extends Control


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("b8d9bc"))
	# Flat layers make the combat mode intentionally read as a 2D stage.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, size.y * 0.42), Vector2(size.x, size.y * 0.2),
		Vector2(size.x, size.y), Vector2(0.0, size.y),
	]), Color("6e9f65"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, size.y * 0.55), Vector2(size.x, size.y * 0.35),
		Vector2(size.x, size.y), Vector2(0.0, size.y),
	]), Color("8ab66c"))
	for index: int in range(9):
		var x: float = size.x * (0.05 + float(index) * 0.12)
		var y: float = size.y * (0.32 - float(index % 3) * 0.04)
		draw_circle(Vector2(x, y), 75.0, Color("527a55"))
		draw_circle(Vector2(x + 45.0, y - 22.0), 55.0, Color("62895d"))
	# Perspective platforms.
	draw_ellipse(Vector2(size.x * 0.73, size.y * 0.46), Vector2(size.x * 0.15, 38.0), Color(0.2, 0.36, 0.2, 0.34))
	draw_ellipse(Vector2(size.x * 0.46, size.y * 0.62), Vector2(size.x * 0.17, 42.0), Color(0.2, 0.36, 0.2, 0.34))
	for index: int in range(18):
		var grass_x: float = size.x * (0.52 + float(index % 9) * 0.052)
		var grass_y: float = size.y * (0.58 + float(index / 9) * 0.075)
		draw_line(Vector2(grass_x, grass_y), Vector2(grass_x - 7.0, grass_y - 25.0), Color("3e7542"), 5.0, true)
		draw_line(Vector2(grass_x, grass_y), Vector2(grass_x + 9.0, grass_y - 30.0), Color("4f8847"), 5.0, true)


func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(32):
		var angle: float = TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

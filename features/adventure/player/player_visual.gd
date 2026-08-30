class_name PlayerVisual
extends Node2D

var movement_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var _time: float = 0.0


func set_motion(direction: Vector2, moving: bool) -> void:
	if not direction.is_zero_approx():
		movement_direction = direction.normalized()
	is_moving = moving


func _process(delta: float) -> void:
	_time += delta * (9.0 if is_moving else 3.0)
	queue_redraw()


func _draw() -> void:
	var bob: float = sin(_time) * 2.2 if is_moving and not SettingsService.reduced_motion else 0.0
	var step: float = sin(_time) * 5.0 if is_moving else 0.0
	var face_x: float = signf(movement_direction.x)

	# Ground-contact shadow sells height in the faux-2.5D view.
	draw_ellipse(Vector2(0.0, 5.0), Vector2(25.0, 10.0), Color(0.06, 0.12, 0.08, 0.34))

	# Legs and boots remain anchored while the body bobs.
	draw_line(Vector2(-8.0, -2.0), Vector2(-9.0 + step * 0.35, 15.0), Color("273d43"), 8.0, true)
	draw_line(Vector2(8.0, -2.0), Vector2(9.0 - step * 0.35, 15.0), Color("273d43"), 8.0, true)
	draw_circle(Vector2(-10.0 + step * 0.35, 16.0), 6.0, Color("3b2f2a"))
	draw_circle(Vector2(10.0 - step * 0.35, 16.0), 6.0, Color("3b2f2a"))

	var body_y: float = -22.0 + bob
	draw_polygon(PackedVector2Array([
		Vector2(-20.0, body_y - 18.0), Vector2(20.0, body_y - 18.0),
		Vector2(16.0, body_y + 18.0), Vector2(-16.0, body_y + 18.0),
	]), PackedColorArray([Color("cf6b32")]))
	draw_line(Vector2(-17.0, body_y), Vector2(17.0, body_y), Color("f1c35b"), 5.0)

	# Backpack reads clearly when travelling upward/sideways.
	if movement_direction.y <= 0.25:
		draw_rect(Rect2(-21.0 - face_x * 2.0, body_y - 12.0, 42.0, 25.0), Color("355b48"), true)

	# Head, hair, face, and directional nose.
	var head := Vector2(0.0, body_y - 35.0)
	draw_circle(head, 19.0, Color("e9b98b"))
	draw_arc(head, 18.5, PI, TAU, 18, Color("342c2a"), 9.0, true)
	draw_circle(head + Vector2(face_x * 7.0, 1.0), 2.3, Color("2d3434"))
	if movement_direction.y > -0.65:
		draw_circle(head + Vector2(-6.0, 1.0), 2.0, Color("2d3434"))
		draw_circle(head + Vector2(6.0, 1.0), 2.0, Color("2d3434"))

	# Long scarf tail gives motion direction without borrowed character design.
	var tail_direction := -movement_direction.normalized() if not movement_direction.is_zero_approx() else Vector2.LEFT
	draw_line(Vector2(0.0, body_y - 16.0), Vector2(0.0, body_y - 16.0) + tail_direction * (25.0 + absf(step)), Color("f2cb55"), 7.0, true)


func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(24):
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

class_name CreatureVisual
extends Node2D

@export var species_id: StringName = &"kindlehorn"
@export_range(0.25, 4.0, 0.05) var visual_scale: float = 1.0
@export var facing_left: bool = false

var active: bool = true
var _time: float = 0.0


func _ready() -> void:
	SettingsService.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func set_species(value: StringName) -> void:
	species_id = value
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	queue_redraw()


func _on_settings_changed() -> void:
	set_process(active and not SettingsService.reduced_motion)
	queue_redraw()


func _draw() -> void:
	var bob: float = sin(_time * 2.8) * 3.0 if not SettingsService.reduced_motion else 0.0
	draw_set_transform(Vector2(0.0, bob), 0.0, Vector2(-visual_scale if facing_left else visual_scale, visual_scale))
	match species_id:
		&"rillip":
			_draw_rillip()
		&"brambit":
			_draw_brambit()
		_:
			_draw_kindlehorn()


func _draw_kindlehorn() -> void:
	draw_ellipse(Vector2.ZERO, Vector2(38.0, 15.0), Color(0.03, 0.07, 0.05, 0.25))
	draw_circle(Vector2(0.0, -35.0), 32.0, Color("df6f35"))
	draw_polygon(PackedVector2Array([Vector2(-24.0, -52.0), Vector2(-32.0, -82.0), Vector2(-8.0, -61.0)]), PackedColorArray([Color("b84f2d")]))
	draw_polygon(PackedVector2Array([Vector2(20.0, -54.0), Vector2(31.0, -83.0), Vector2(8.0, -62.0)]), PackedColorArray([Color("b84f2d")]))
	draw_circle(Vector2(0.0, -29.0), 21.0, Color("f3b066"))
	draw_circle(Vector2(-10.0, -39.0), 3.5, Color("2b302e"))
	draw_circle(Vector2(10.0, -39.0), 3.5, Color("2b302e"))
	draw_circle(Vector2(0.0, -25.0), 4.0, Color("59352b"))
	draw_polygon(PackedVector2Array([Vector2(-4.0, -67.0), Vector2(0.0, -102.0), Vector2(7.0, -67.0)]), PackedColorArray([Color("f9d25d")]))
	draw_circle(Vector2(0.0, -96.0), 6.0, Color(1.0, 0.71, 0.18, 0.65))
	draw_line(Vector2(-23.0, -13.0), Vector2(-27.0, 7.0), Color("7c3b2d"), 9.0, true)
	draw_line(Vector2(23.0, -13.0), Vector2(27.0, 7.0), Color("7c3b2d"), 9.0, true)


func _draw_rillip() -> void:
	draw_ellipse(Vector2.ZERO, Vector2(42.0, 15.0), Color(0.03, 0.07, 0.07, 0.24))
	draw_circle(Vector2(0.0, -34.0), 39.0, Color("4e9fc5"))
	draw_circle(Vector2(-24.0, -58.0), 17.0, Color("70bdd1"))
	draw_circle(Vector2(24.0, -58.0), 17.0, Color("70bdd1"))
	draw_circle(Vector2(-24.0, -59.0), 6.0, Color("183b49"))
	draw_circle(Vector2(24.0, -59.0), 6.0, Color("183b49"))
	draw_arc(Vector2(0.0, -29.0), 18.0, 0.25, PI - 0.25, 18, Color("d8f2e7"), 4.0, true)
	draw_circle(Vector2(-31.0, -25.0), 7.0, Color(0.94, 0.55, 0.55, 0.5))
	draw_circle(Vector2(31.0, -25.0), 7.0, Color(0.94, 0.55, 0.55, 0.5))
	draw_line(Vector2(-27.0, -3.0), Vector2(-35.0, 8.0), Color("367fa5"), 10.0, true)
	draw_line(Vector2(27.0, -3.0), Vector2(35.0, 8.0), Color("367fa5"), 10.0, true)


func _draw_brambit() -> void:
	draw_ellipse(Vector2.ZERO, Vector2(43.0, 15.0), Color(0.03, 0.07, 0.04, 0.25))
	draw_circle(Vector2(0.0, -31.0), 38.0, Color("9c7044"))
	draw_circle(Vector2(0.0, -28.0), 27.0, Color("c69a61"))
	draw_circle(Vector2(-11.0, -37.0), 3.6, Color("253229"))
	draw_circle(Vector2(11.0, -37.0), 3.6, Color("253229"))
	draw_circle(Vector2(0.0, -24.0), 5.0, Color("60432f"))
	draw_polygon(PackedVector2Array([Vector2(-25.0, -58.0), Vector2(-18.0, -86.0), Vector2(-2.0, -59.0)]), PackedColorArray([Color("438c49")]))
	draw_polygon(PackedVector2Array([Vector2(-4.0, -63.0), Vector2(5.0, -94.0), Vector2(17.0, -60.0)]), PackedColorArray([Color("5aa552")]))
	draw_polygon(PackedVector2Array([Vector2(12.0, -58.0), Vector2(28.0, -82.0), Vector2(29.0, -52.0)]), PackedColorArray([Color("397a43")]))
	draw_line(Vector2(-26.0, -8.0), Vector2(-31.0, 7.0), Color("775338"), 11.0, true)
	draw_line(Vector2(26.0, -8.0), Vector2(31.0, 7.0), Color("775338"), 11.0, true)


func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(28):
		var angle: float = TAU * float(index) / 28.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

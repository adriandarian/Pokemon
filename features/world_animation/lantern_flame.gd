class_name LanternFlame
extends Node2D

var _wind_source: AmbientWind


func _ready() -> void:
	var additive_material := CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive_material
	SettingsService.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()
	queue_redraw()


func set_wind_source(source: AmbientWind) -> void:
	_wind_source = source
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _on_settings_changed() -> void:
	set_process(not SettingsService.reduced_motion)
	queue_redraw()


func _draw() -> void:
	var time: float = _wind_source.get_time() if _wind_source != null else 0.0
	var wind: Vector2 = _wind_source.sample(global_position) if _wind_source != null else Vector2.ZERO
	var flutter: float = sin(time * 7.4) * 1.8 + sin(time * 12.7) * 0.7
	var sway: float = wind.x * 8.0 + flutter
	var pulse: float = 1.0 + sin(time * 6.1) * 0.08

	draw_circle(Vector2(sway * 0.18, -7.0), 29.0 * pulse, Color(1.0, 0.56, 0.12, 0.12))
	_draw_flame_layer(Vector2.ZERO, sway, 21.0 * pulse, 10.0, Color(1.0, 0.31, 0.05, 0.86))
	_draw_flame_layer(Vector2(0.0, 1.5), sway * 0.68, 15.0 * pulse, 7.0, Color(1.0, 0.68, 0.12, 0.94))
	_draw_flame_layer(Vector2(0.0, 3.0), sway * 0.34, 9.5 * pulse, 4.2, Color(1.0, 0.95, 0.62, 1.0))

	for ember_index: int in range(3):
		var life: float = fposmod(time * (0.72 + float(ember_index) * 0.11) + float(ember_index) * 0.31, 1.0)
		var ember := Vector2(sway * life + sin(float(ember_index) + time * 4.0) * 2.0, -12.0 - life * 20.0)
		var size: float = 1.2 + float(ember_index) * 0.35
		draw_rect(Rect2(ember - Vector2.ONE * size * 0.5, Vector2.ONE * size), Color(1.0, 0.68, 0.18, (1.0 - life) * 0.72))


func _draw_flame_layer(base: Vector2, sway: float, height: float, half_width: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-half_width, 1.0),
		base + Vector2(-half_width * 0.62, -height * 0.55),
		base + Vector2(sway, -height),
		base + Vector2(half_width * 0.62, -height * 0.55),
		base + Vector2(half_width, 1.0),
	]), color)

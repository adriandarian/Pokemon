class_name WindMotes
extends Node2D

const WORLD_SIZE := Vector2(2200.0, 1300.0)

var _wind_source: AmbientWind


func _ready() -> void:
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
	for index: int in range(24):
		var drift_speed: float = 27.0 + float(index % 5) * 7.0
		var x: float = fposmod(83.0 + float(index * 191) + time * drift_speed, WORLD_SIZE.x + 90.0) - 45.0
		var y: float = fposmod(120.0 + float(index * 113) - time * (4.0 + float(index % 3)), WORLD_SIZE.y)
		var flutter: float = sin(time * (2.2 + float(index % 4) * 0.37) + float(index))
		var point := Vector2(x, y + flutter * 8.0)
		var color := Color(0.75, 0.86, 0.48, 0.32)
		if index % 7 == 0:
			color = Color(0.94, 0.58, 0.38, 0.38)
		var size: float = 2.0 + float(index % 3)
		draw_colored_polygon(PackedVector2Array([
			point + Vector2(-size, 0.0), point + Vector2(0.0, -size * 0.55),
			point + Vector2(size, 0.0), point + Vector2(0.0, size * 0.55),
		]), color)
		if index % 4 == 0:
			draw_line(point - Vector2(11.0, -2.0), point - Vector2(3.0, -0.5), Color(color, color.a * 0.42), 1.0, true)

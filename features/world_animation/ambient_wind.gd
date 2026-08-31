class_name AmbientWind
extends Node

const BASE_DIRECTION := Vector2(1.0, -0.18)

var _time: float = 0.0


func _ready() -> void:
	SettingsService.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func _process(delta: float) -> void:
	_time += delta


func get_time() -> float:
	return _time


func sample(world_position: Vector2) -> Vector2:
	var spatial_phase: float = world_position.x * 0.0043 + world_position.y * 0.0021
	var long_gust: float = sin(_time * 0.72 + spatial_phase) * 0.28
	var quick_gust: float = sin(_time * 1.93 - spatial_phase * 0.47) * 0.12
	var strength: float = clampf(0.58 + long_gust + quick_gust, 0.16, 0.98)
	return BASE_DIRECTION.normalized() * strength


func _on_settings_changed() -> void:
	set_process(not SettingsService.reduced_motion)

class_name ShorelineWaves
extends Node2D

static var BANK_POINTS := PackedVector2Array([
	Vector2(278.0, 404.0), Vector2(292.0, 492.0), Vector2(276.0, 585.0),
	Vector2(298.0, 682.0), Vector2(282.0, 780.0), Vector2(304.0, 878.0),
	Vector2(286.0, 974.0), Vector2(306.0, 1072.0), Vector2(288.0, 1170.0),
	Vector2(300.0, 1300.0),
])

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
	for crest_index: int in range(3):
		var travel: float = fposmod(time * 0.34 + float(crest_index) * 0.34, 1.0)
		var distance: float = lerpf(78.0, 3.0, smoothstep(0.0, 1.0, travel))
		var fade_in: float = smoothstep(0.02, 0.22, travel)
		var fade_out: float = 1.0 - smoothstep(0.82, 1.0, travel)
		var alpha: float = fade_in * fade_out
		var front: PackedVector2Array = _build_wave_front(distance, time + float(crest_index) * 1.7)
		draw_polyline(front, Color(0.69, 0.94, 0.86, alpha * 0.72), 3.0 + travel * 3.0, true)
		if travel > 0.64:
			_draw_crash_foam(front, smoothstep(0.64, 0.9, travel) * fade_out, crest_index)


func _build_wave_front(distance: float, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	const STEPS_PER_SEGMENT: int = 7
	for segment_index: int in range(BANK_POINTS.size() - 1):
		var start: Vector2 = BANK_POINTS[segment_index]
		var finish: Vector2 = BANK_POINTS[segment_index + 1]
		var tangent: Vector2 = (finish - start).normalized()
		var water_normal := Vector2(-tangent.y, tangent.x)
		if water_normal.x > 0.0:
			water_normal = -water_normal
		for step: int in range(STEPS_PER_SEGMENT):
			var amount: float = float(step) / float(STEPS_PER_SEGMENT)
			var ripple: float = sin(float(segment_index * STEPS_PER_SEGMENT + step) * 1.37 + phase * 2.2) * 2.8
			points.append(start.lerp(finish, amount) + water_normal * (distance + ripple))
	points.append(BANK_POINTS[BANK_POINTS.size() - 1] + Vector2(-distance, 0.0))
	return points


func _draw_crash_foam(front: PackedVector2Array, amount: float, crest_index: int) -> void:
	for index: int in range(2 + crest_index, front.size(), 9):
		var center: Vector2 = front[index]
		var size: float = 3.0 + float((index + crest_index) % 3)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-size, 0.0), center + Vector2(0.0, -size * 0.55),
			center + Vector2(size, 0.0), center + Vector2(0.0, size * 0.55),
		]), Color(0.86, 0.98, 0.9, amount * 0.8))

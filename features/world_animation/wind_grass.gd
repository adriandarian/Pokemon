class_name WindGrass
extends Node2D

static var WILD_POLYGON := PackedVector2Array([
	Vector2(1230.0, 246.0), Vector2(1435.0, 220.0), Vector2(1775.0, 234.0),
	Vector2(2010.0, 290.0), Vector2(2044.0, 510.0), Vector2(2020.0, 785.0),
	Vector2(1935.0, 960.0), Vector2(1605.0, 982.0), Vector2(1320.0, 930.0),
	Vector2(1202.0, 768.0),
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
	for row: int in range(9):
		for column: int in range(13):
			var jitter_x: float = float((row * 31 + column * 17) % 29) - 14.0
			var jitter_y: float = float((row * 13 + column * 23) % 21) - 10.0
			var base := Vector2(1270.0 + float(column) * 59.0 + jitter_x, 300.0 + float(row) * 72.0 + jitter_y)
			if Geometry2D.is_point_in_polygon(base, WILD_POLYGON):
				_draw_grass_cluster(base, 0.82 + float((row + column) % 3) * 0.11)

	for index: int in range(18):
		var base := Vector2(430.0 + float((index * 113) % 1480), 320.0 + float((index * 191) % 820))
		if not Geometry2D.is_point_in_polygon(base, WILD_POLYGON):
			_draw_grass_cluster(base, 0.58)


func _draw_grass_cluster(base: Vector2, scale_factor: float) -> void:
	var stem_height: float = 26.0 * scale_factor
	var wind: Vector2 = _wind_source.sample(base) if _wind_source != null else Vector2.ZERO
	var bend := Vector2(wind.x * (9.0 + scale_factor * 4.0), wind.y * 3.0)
	var dark_tip := base + Vector2(-5.0, -stem_height - 5.0) + bend
	var light_tip := base + Vector2(7.0, -stem_height * 0.88) + bend * 1.15

	draw_colored_polygon(PackedVector2Array([
		base + Vector2(-8.0, 0.0), base + Vector2(-5.0, -stem_height * 0.48) + bend * 0.32,
		dark_tip, base + Vector2(0.0, 0.0),
	]), Color("2f6b3d"))
	draw_colored_polygon(PackedVector2Array([
		base + Vector2(1.0, 0.0), base + Vector2(5.0, -stem_height * 0.45) + bend * 0.38,
		light_tip, base + Vector2(11.0, 0.0),
	]), Color("76a554"))
	_draw_voxel_top(dark_tip + Vector2(2.0, 0.0), Vector2(7.0, 4.0), Color("94ba64"), Color("4d8348"))


func _draw_voxel_top(center: Vector2, radii: Vector2, top_color: Color, side_color: Color) -> void:
	var top := PackedVector2Array([
		center + Vector2(-radii.x, 0.0), center + Vector2(0.0, -radii.y),
		center + Vector2(radii.x, 0.0), center + Vector2(0.0, radii.y),
	])
	draw_colored_polygon(top, top_color)
	draw_colored_polygon(PackedVector2Array([
		top[0], top[3], top[3] + Vector2(0.0, 4.0), top[0] + Vector2(0.0, 4.0),
	]), side_color)

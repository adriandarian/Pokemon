class_name VoxelWaterSurface
extends Polygon2D

const WATER_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_water.png")
const WATER_SHADER: Shader = preload("res://features/voxel_art/voxel_water.gdshader")

static var RIVER_POLYGON := PackedVector2Array([
	# Both caps live beyond the camera limits, so traversal can never reveal a
	# rectangular edge where the river texture begins or ends.
	Vector2(0.0, -160.0), Vector2(286.0, -160.0), Vector2(282.0, 32.0),
	Vector2(296.0, 144.0), Vector2(276.0, 280.0), Vector2(278.0, 404.0), Vector2(292.0, 492.0),
	Vector2(276.0, 585.0), Vector2(298.0, 682.0), Vector2(282.0, 780.0),
	Vector2(304.0, 878.0), Vector2(286.0, 974.0), Vector2(306.0, 1072.0),
	Vector2(288.0, 1170.0), Vector2(300.0, 1700.0), Vector2(284.0, 2140.0),
	Vector2(306.0, 2620.0), Vector2(292.0, 3260.0), Vector2(0.0, 3260.0),
])


func _ready() -> void:
	polygon = RIVER_POLYGON
	uv = _build_uvs()
	texture = WATER_TEXTURE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var water_material := ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	material = water_material
	SettingsService.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func _build_uvs() -> PackedVector2Array:
	var coordinates := PackedVector2Array()
	for point: Vector2 in RIVER_POLYGON:
		coordinates.append(point * Vector2(1.45, 1.18))
	return coordinates


func _on_settings_changed() -> void:
	var water_material := material as ShaderMaterial
	if water_material != null:
		water_material.set_shader_parameter("motion_amount", 0.0 if SettingsService.reduced_motion else 1.0)

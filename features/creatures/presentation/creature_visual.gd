class_name CreatureVisual
extends Node2D

const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")
const GroundShadow = preload("res://features/voxel_art/grounding_shadow.gd")
const DISPLAY_SIZE := Vector2(138.0, 138.0)

@export var species_id: StringName = &"kindlehorn"
@export_range(0.25, 4.0, 0.05) var visual_scale: float = 1.0
@export var facing_left: bool = false

var active: bool = true
var _time: float = 0.0
var _ground_elevation_pixels: float = 0.0


func _ready() -> void:
	material = VoxelAssets.create_chroma_material()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	SettingsService.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func set_species(value: StringName) -> void:
	species_id = value
	queue_redraw()


func set_ground_elevation_pixels(value: float) -> void:
	if is_equal_approx(_ground_elevation_pixels, value):
		return
	_ground_elevation_pixels = value
	queue_redraw()


func get_ground_elevation_pixels() -> float:
	return _ground_elevation_pixels


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
	var flip_x: float = -visual_scale if facing_left else visual_scale
	GroundShadow.draw(
		self,
		Vector2(25.0, 5.5) * visual_scale,
		Vector2(0.0, -visual_scale - _ground_elevation_pixels)
	)
	draw_set_transform(
		Vector2(0.0, bob - _ground_elevation_pixels),
		0.0,
		Vector2(flip_x, visual_scale)
	)
	var texture: Texture2D = VoxelAssets.get_species_texture(species_id)
	var source_rect: Rect2 = VoxelAssets.get_species_source_rect(texture, species_id)
	var destination_rect: Rect2 = VoxelAssets.fit_bottom_centered(source_rect, DISPLAY_SIZE, 1.0)
	draw_texture_rect_region(texture, destination_rect, source_rect)

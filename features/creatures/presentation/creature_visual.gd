class_name CreatureVisual
extends Node2D

const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")
const DISPLAY_SIZE := Vector2(138.0, 138.0)

@export var species_id: StringName = &"kindlehorn"
@export_range(0.25, 4.0, 0.05) var visual_scale: float = 1.0
@export var facing_left: bool = false

var active: bool = true
var _time: float = 0.0


func _ready() -> void:
	material = VoxelAssets.create_chroma_material()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
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
	var flip_x: float = -visual_scale if facing_left else visual_scale
	draw_colored_polygon(PackedVector2Array([
		Vector2(-43.0, 0.0), Vector2(-15.0, -10.0),
		Vector2(43.0, 0.0), Vector2(15.0, 13.0),
	]), Color(0.03, 0.07, 0.05, 0.28))
	draw_set_transform(Vector2(0.0, bob), 0.0, Vector2(flip_x, visual_scale))
	var texture: Texture2D = VoxelAssets.get_species_texture(species_id)
	var source_rect: Rect2 = VoxelAssets.get_species_source_rect(texture, species_id)
	var destination_rect: Rect2 = VoxelAssets.fit_bottom_centered(source_rect, DISPLAY_SIZE)
	draw_texture_rect_region(texture, destination_rect, source_rect)

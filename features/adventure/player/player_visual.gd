class_name PlayerVisual
extends Node2D

const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")
const DISPLAY_SIZE := Vector2(116.0, 142.0)

var movement_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var _time: float = 0.0


func _ready() -> void:
	material = VoxelAssets.create_chroma_material()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func set_motion(direction: Vector2, moving: bool) -> void:
	if not direction.is_zero_approx():
		movement_direction = direction.normalized()
	is_moving = moving


func _process(delta: float) -> void:
	_time += delta * (9.0 if is_moving else 3.0)
	queue_redraw()


func _draw() -> void:
	var moving_with_motion: bool = is_moving and not SettingsService.reduced_motion
	var bob: float = sin(_time) * 2.6 if moving_with_motion else 0.0
	var lean: float = sin(_time) * 0.025 if moving_with_motion else 0.0
	var facing_away: bool = movement_direction.y < -0.25
	var flip_x: float = -1.0 if movement_direction.x < -0.12 else 1.0

	draw_colored_polygon(PackedVector2Array([
		Vector2(-29.0, 3.0), Vector2(-8.0, -6.0),
		Vector2(29.0, 3.0), Vector2(8.0, 12.0),
	]), Color(0.04, 0.08, 0.06, 0.34))

	draw_set_transform(Vector2(0.0, bob), lean, Vector2(flip_x, 1.0))
	var texture: Texture2D = VoxelAssets.get_player_texture(facing_away)
	var source_rect: Rect2 = VoxelAssets.get_player_source_rect(texture, facing_away)
	var destination_rect: Rect2 = VoxelAssets.fit_bottom_centered(source_rect, DISPLAY_SIZE)
	draw_texture_rect_region(texture, destination_rect, source_rect)

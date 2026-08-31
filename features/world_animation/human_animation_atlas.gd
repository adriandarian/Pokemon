class_name HumanAnimationAtlas
extends RefCounted

const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")

const IDLE_SEQUENCE: Array[int] = [0, 1, 0, 2, 0]
const IDLE_DURATIONS: Array[float] = [4.2, 0.14, 0.38, 1.15, 2.35]
const WALK_SEQUENCE: Array[int] = [3, 4, 5, 4]
const WALK_DURATIONS: Array[float] = [1.0, 0.72, 1.0, 0.72]
const RUN_SEQUENCE: Array[int] = [6, 7, 8, 7]
const RUN_DURATIONS: Array[float] = [0.9, 0.62, 0.9, 0.62]


static func create_player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for facing_away: bool in [false, true]:
		var prefix: String = "back" if facing_away else "front"
		_add_player_animation(frames, StringName(prefix + "_idle"), facing_away, IDLE_SEQUENCE, IDLE_DURATIONS, 1.0)
		_add_player_animation(frames, StringName(prefix + "_walk"), facing_away, WALK_SEQUENCE, WALK_DURATIONS, 7.0)
		_add_player_animation(frames, StringName(prefix + "_run"), facing_away, RUN_SEQUENCE, RUN_DURATIONS, 10.5)
	return frames


static func create_ranger_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_ranger_animation(frames, &"idle", IDLE_SEQUENCE, IDLE_DURATIONS, 1.0)
	_add_ranger_animation(frames, &"walk", WALK_SEQUENCE, WALK_DURATIONS, 6.2)
	_add_ranger_animation(frames, &"run", RUN_SEQUENCE, RUN_DURATIONS, 9.4)
	return frames


static func _add_player_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	facing_away: bool,
	sequence: Array[int],
	durations: Array[float],
	speed: float
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, speed)
	var texture: Texture2D = VoxelAssets.get_player_animation_texture(facing_away)
	for index: int in range(sequence.size()):
		var frame_index: int = sequence[index]
		frames.add_frame(
			animation_name,
			_create_atlas_frame(texture, VoxelAssets.get_player_animation_frame_rect(frame_index, facing_away)),
			durations[index]
		)


static func _add_ranger_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	sequence: Array[int],
	durations: Array[float],
	speed: float
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, speed)
	var texture: Texture2D = VoxelAssets.get_ranger_animation_texture()
	for index: int in range(sequence.size()):
		var frame_index: int = sequence[index]
		frames.add_frame(
			animation_name,
			_create_atlas_frame(texture, VoxelAssets.get_ranger_animation_frame_rect(frame_index)),
			durations[index]
		)


static func _create_atlas_frame(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = region
	return frame

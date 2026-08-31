class_name AdventureNpcVisual
extends Node2D

const GroundShadow = preload("res://features/voxel_art/grounding_shadow.gd")
const HumanAtlas = preload("res://features/world_animation/human_animation_atlas.gd")
const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")

enum Locomotion {
	IDLE,
	WALK,
	RUN,
}

const DISPLAY_SIZE := Vector2(104.0, 136.0)
const BASE_SPRITE_POSITION := Vector2(0.0, -DISPLAY_SIZE.y * 0.5 + 1.0)

var _locomotion: Locomotion = Locomotion.IDLE
var _direction: Vector2 = Vector2.RIGHT
var _phase: float = 0.0
var _wind_source: AmbientWind
var _sprite: AnimatedSprite2D
var _sprite_scale: float = 1.0


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "AnimatedSprite2D"
	_sprite.sprite_frames = HumanAtlas.create_ranger_frames()
	_sprite.material = VoxelAssets.create_chroma_material()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.position = BASE_SPRITE_POSITION
	_sprite_scale = DISPLAY_SIZE.y / VoxelAssets.get_ranger_animation_cell_height()
	_sprite.scale = Vector2.ONE * _sprite_scale
	add_child(_sprite)
	SettingsService.settings_changed.connect(_on_settings_changed)
	_play_requested_animation()


func set_wind_source(source: AmbientWind) -> void:
	_wind_source = source


func set_motion(direction: Vector2, speed: float, running: bool) -> void:
	if not direction.is_zero_approx():
		_direction = direction.normalized()
	var next_locomotion := Locomotion.IDLE
	if speed > 5.0:
		next_locomotion = Locomotion.RUN if running else Locomotion.WALK
	if next_locomotion != _locomotion:
		_locomotion = next_locomotion
	_play_requested_animation()


func get_locomotion_state_name() -> StringName:
	match _locomotion:
		Locomotion.WALK:
			return &"walk"
		Locomotion.RUN:
			return &"run"
		_:
			return &"idle"


func _process(delta: float) -> void:
	if not SettingsService.reduced_motion:
		var phase_speed: float = 1.55
		if _locomotion == Locomotion.WALK:
			phase_speed = 6.2
		elif _locomotion == Locomotion.RUN:
			phase_speed = 9.4
		_phase += delta * phase_speed

	var bob: float = 0.0
	var lean: float = 0.0
	var representative_frame: int = 0
	if _locomotion == Locomotion.WALK:
		representative_frame = 3
	elif _locomotion == Locomotion.RUN:
		representative_frame = 6
	var crop_center_offset: float = VoxelAssets.get_ranger_animation_center_offset(representative_frame) * _sprite_scale
	if not SettingsService.reduced_motion:
		match _locomotion:
			Locomotion.IDLE:
				bob = sin(_phase) * 0.45
				if _wind_source != null:
					lean = _wind_source.sample(global_position).x * 0.003
			Locomotion.WALK:
				bob = sin(_phase) * 0.8
				lean = sin(_phase) * 0.008
			Locomotion.RUN:
				bob = sin(_phase) * 1.2
				lean = sin(_phase) * 0.012 + _direction.x * 0.01
	_sprite.position = BASE_SPRITE_POSITION + Vector2(0.0, bob + crop_center_offset)
	_sprite.rotation = lean
	queue_redraw()


func _draw() -> void:
	var pulse: float = 1.0
	if not SettingsService.reduced_motion and _locomotion != Locomotion.IDLE:
		pulse += sin(_phase * 2.0) * (0.03 if _locomotion == Locomotion.WALK else 0.05)
	GroundShadow.draw(self, Vector2(19.0, 4.5) * pulse, Vector2(0.0, -1.0))


func _play_requested_animation() -> void:
	if _sprite == null:
		return
	var animation_name: StringName = get_locomotion_state_name()
	# Ranger Sela's atlas shares the player's native left-facing orientation.
	if absf(_direction.x) > 0.08:
		_sprite.flip_h = _direction.x > 0.0
	if _sprite.animation != animation_name:
		_sprite.play(animation_name)
	_apply_reduced_motion()


func _on_settings_changed() -> void:
	_apply_reduced_motion()


func _apply_reduced_motion() -> void:
	if _sprite == null:
		return
	if SettingsService.reduced_motion:
		_sprite.pause()
		_sprite.frame = 0 if _locomotion == Locomotion.IDLE else 1
	else:
		_sprite.play()

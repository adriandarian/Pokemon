class_name HomesteadPlayer3D
extends CharacterBody3D

const HumanAtlas = preload("res://features/world_animation/human_animation_atlas.gd")
const PLAYER_CHROMA_SHADER = preload("res://features/homestead_3d/player_chroma_3d.gdshader")
const MAX_WALKABLE_SLOPE_DEGREES := 65.0
const STEEP_STAIR_MAX_SLOPE_DEGREES := 72.0

signal interact_requested(origin: Vector3, facing: Vector3)
signal navigation_finished(reached: bool)
signal navigation_cancelled
signal manual_movement_started

@export var move_speed: float = 5.4
@export var run_speed: float = 8.2
@export var acceleration: float = 30.0
@export var friction: float = 38.0

var movement_enabled: bool = true
var facing: Vector3 = Vector3.BACK
var running: bool = false
var last_safe_position: Vector3
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float
var _current_animation: StringName
var _sprite_material: ShaderMaterial
var _navigation_active: bool = false
var _navigation_target: Vector3
var _manual_input_active: bool = false
var _steep_stair_traversal_active: bool = false

@onready var sprite: AnimatedSprite3D = %AnimatedSprite3D
@onready var navigation_agent: NavigationAgent3D = %NavigationAgent3D


func _ready() -> void:
	floor_snap_length = 0.65
	floor_max_angle = deg_to_rad(MAX_WALKABLE_SLOPE_DEGREES)
	floor_block_on_wall = false
	sprite.sprite_frames = HumanAtlas.create_player_frames()
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite_material = ShaderMaterial.new()
	_sprite_material.shader = PLAYER_CHROMA_SHADER
	sprite.material_override = _sprite_material
	sprite.frame_changed.connect(_sync_shader_texture)
	last_safe_position = global_position
	_play_requested_animation()
	_sync_shader_texture()
	SettingsService.settings_changed.connect(_apply_reduced_motion)


func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	if movement_enabled:
		input_direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if not input_direction.is_zero_approx():
		if not _manual_input_active:
			manual_movement_started.emit()
		_manual_input_active = true
		cancel_navigation()
	else:
		_manual_input_active = false
	var direction := Vector3(input_direction.x, 0.0, input_direction.y)
	if direction.is_zero_approx() and movement_enabled and _navigation_active:
		direction = _get_navigation_direction()
	if not direction.is_zero_approx():
		direction = direction.normalized()
		facing = direction
		running = not _navigation_active and Input.is_action_pressed(&"sprint")
		var target_speed: float = run_speed if running else move_speed
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		running = false
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		last_safe_position = global_position
	move_and_slide()
	_play_requested_animation()
	if global_position.y < -3.0:
		teleport_to(last_safe_position)


func _unhandled_input(event: InputEvent) -> void:
	if movement_enabled and event.is_action_pressed(&"interact"):
		interact_requested.emit(global_position, facing)
		get_viewport().set_input_as_handled()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		cancel_navigation()
		velocity = Vector3.ZERO
		running = false


func set_steep_stair_traversal_active(active: bool) -> void:
	if _steep_stair_traversal_active == active:
		return
	_steep_stair_traversal_active = active
	floor_max_angle = deg_to_rad(
		STEEP_STAIR_MAX_SLOPE_DEGREES if active else MAX_WALKABLE_SLOPE_DEGREES
	)


func is_steep_stair_traversal_active() -> bool:
	return _steep_stair_traversal_active


func teleport_to(next_position: Vector3) -> void:
	cancel_navigation()
	global_position = next_position
	velocity = Vector3.ZERO
	last_safe_position = next_position
	reset_physics_interpolation()


func get_current_animation_name() -> StringName:
	return _current_animation


func navigate_to(world_position: Vector3) -> bool:
	if not movement_enabled:
		return false
	_navigation_target = world_position
	_navigation_active = true
	navigation_agent.target_position = world_position
	return true


func cancel_navigation() -> void:
	if not _navigation_active:
		return
	_navigation_active = false
	navigation_cancelled.emit()


func is_navigating() -> bool:
	return _navigation_active


func get_navigation_target() -> Vector3:
	return _navigation_target


func get_navigation_map() -> RID:
	return navigation_agent.get_navigation_map()


func get_current_navigation_path() -> PackedVector3Array:
	return navigation_agent.get_current_navigation_path()


func _get_navigation_direction() -> Vector3:
	if navigation_agent.is_navigation_finished():
		_finish_navigation()
		return Vector3.ZERO
	var next_position: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = next_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return Vector3.ZERO
	return direction.normalized()


func _finish_navigation() -> void:
	var reached: bool = navigation_agent.is_target_reachable() \
		and global_position.distance_to(navigation_agent.get_final_position()) \
			<= navigation_agent.target_desired_distance + 0.35
	_navigation_active = false
	navigation_finished.emit(reached)


func _play_requested_animation() -> void:
	if sprite == null:
		return
	var locomotion := "idle"
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	if planar_speed > 0.25:
		locomotion = "run" if running else "walk"
	var prefix := "back" if facing.z < -0.2 else "front"
	var requested := StringName(prefix + "_" + locomotion)
	if absf(facing.x) > 0.12:
		sprite.flip_h = facing.x > 0.0
	if requested != _current_animation:
		_current_animation = requested
		sprite.play(requested)
		_sync_shader_texture()
	_apply_reduced_motion()


func _sync_shader_texture() -> void:
	if _sprite_material == null or sprite == null or sprite.sprite_frames == null:
		return
	var frame_texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	_sprite_material.set_shader_parameter("sprite_texture", frame_texture)


func _apply_reduced_motion() -> void:
	if sprite == null:
		return
	if SettingsService.reduced_motion:
		sprite.pause()
		sprite.frame = 0
	else:
		sprite.play()

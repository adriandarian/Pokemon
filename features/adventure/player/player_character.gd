class_name PlayerCharacter
extends CharacterBody2D

const Scale = preload("res://features/adventure/adventure_scale.gd")

signal interact_requested(origin: Vector2, facing: Vector2)

@export var move_speed: float = 165.0
@export var run_speed: float = 255.0
@export var acceleration: float = 1500.0
@export var friction: float = 1900.0

var movement_enabled: bool = true
var facing: Vector2 = Vector2.DOWN
var running: bool = false
var visual: PlayerVisual
var _missing_visual_reported: bool = false
var _ground_elevation_pixels: float = 0.0


func _ready() -> void:
	_resolve_visual()
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.zoom = Scale.EXPLORATION_CAMERA_ZOOM
		_sync_camera_projection(camera)


func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	if movement_enabled:
		input_direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if not input_direction.is_zero_approx():
		facing = input_direction.normalized()
		running = Input.is_action_pressed(&"sprint")
		var target_speed: float = run_speed if running else move_speed
		velocity = velocity.move_toward(facing * target_speed, acceleration * delta)
	else:
		running = false
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	var current_visual: PlayerVisual = _resolve_visual()
	if current_visual != null:
		current_visual.set_motion(facing, velocity.length(), running)


func _unhandled_input(event: InputEvent) -> void:
	if movement_enabled and event.is_action_pressed(&"interact"):
		interact_requested.emit(global_position, facing)
		get_viewport().set_input_as_handled()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		running = false


func get_visual() -> PlayerVisual:
	return _resolve_visual()


func set_ground_elevation_pixels(value: float) -> void:
	if is_equal_approx(_ground_elevation_pixels, value):
		return
	_ground_elevation_pixels = value
	var current_visual: PlayerVisual = _resolve_visual()
	if current_visual != null:
		current_visual.set_ground_elevation_pixels(value)
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		_sync_camera_projection(camera)


func get_ground_elevation_pixels() -> float:
	return _ground_elevation_pixels


func set_world_bounds(bounds: Rect2) -> void:
	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = floori(bounds.position.x)
	camera.limit_top = floori(bounds.position.y)
	camera.limit_right = ceili(bounds.end.x)
	camera.limit_bottom = ceili(bounds.end.y)


func _sync_camera_projection(camera: Camera2D) -> void:
	camera.position = Scale.EXPLORATION_CAMERA_OFFSET + Vector2.UP * _ground_elevation_pixels


func _resolve_visual() -> PlayerVisual:
	if is_instance_valid(visual):
		return visual
	visual = get_node_or_null("PlayerVisual") as PlayerVisual
	if visual == null:
		if not _missing_visual_reported:
			push_error("PlayerCharacter requires a PlayerVisual child with player_visual.gd attached.")
			_missing_visual_reported = true
		return null
	_missing_visual_reported = false
	return visual

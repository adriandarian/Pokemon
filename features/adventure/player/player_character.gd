class_name PlayerCharacter
extends CharacterBody2D

signal interact_requested(origin: Vector2, facing: Vector2)

@export var move_speed: float = 230.0
@export var acceleration: float = 1500.0
@export var friction: float = 1900.0

@onready var visual: PlayerVisual = %PlayerVisual

var movement_enabled: bool = true
var facing: Vector2 = Vector2.DOWN


func _physics_process(delta: float) -> void:
	var input_direction := Vector2.ZERO
	if movement_enabled:
		input_direction = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if not input_direction.is_zero_approx():
		facing = input_direction.normalized()
		velocity = velocity.move_toward(facing * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()
	visual.set_motion(facing, velocity.length_squared() > 36.0)


func _unhandled_input(event: InputEvent) -> void:
	if movement_enabled and event.is_action_pressed(&"interact"):
		interact_requested.emit(global_position, facing)
		get_viewport().set_input_as_handled()


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO

class_name AdventureNpc
extends CharacterBody2D

const NpcVisual = preload("res://features/adventure/npc/adventure_npc_visual.gd")

@export var walk_speed: float = 52.0
@export var run_speed: float = 104.0
@export var acceleration: float = 360.0

var interaction_title: String = ""
var interaction_text: String = ""

var _home_position: Vector2
var _patrol_offsets: Array[Vector2] = [
	Vector2.ZERO,
	Vector2(116.0, -22.0),
	Vector2(42.0, 38.0),
]
var _target_index: int = 1
var _completed_segments: int = 0
var _idle_remaining: float = 2.4
var _visual: AdventureNpcVisual


func configure(title: String, text: String) -> void:
	interaction_title = title
	interaction_text = text


func _ready() -> void:
	collision_layer = 2
	collision_mask = 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group(&"interactable")
	_home_position = global_position
	_add_collision()
	_visual = NpcVisual.new()
	_visual.name = "AdventureNpcVisual"
	add_child(_visual)


func set_wind_source(source: AmbientWind) -> void:
	if _visual != null:
		_visual.set_wind_source(source)


func get_interaction() -> Dictionary:
	return {"title": interaction_title, "text": interaction_text}


func get_prompt() -> String:
	return "Talk"


func get_visual() -> AdventureNpcVisual:
	return _visual


func get_locomotion_state_name() -> StringName:
	return _visual.get_locomotion_state_name() if _visual != null else &"idle"


func _physics_process(delta: float) -> void:
	if _idle_remaining > 0.0:
		_idle_remaining = maxf(0.0, _idle_remaining - delta)
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		_visual.set_motion(Vector2.ZERO, velocity.length(), false)
		return

	var target: Vector2 = _home_position + _patrol_offsets[_target_index]
	var offset: Vector2 = target - global_position
	if offset.length_squared() <= 18.0:
		global_position = target
		velocity = Vector2.ZERO
		_completed_segments += 1
		_target_index = (_target_index + 1) % _patrol_offsets.size()
		_idle_remaining = 1.2 + float(_completed_segments % 3) * 0.45
		_visual.set_motion(Vector2.ZERO, 0.0, false)
		return

	var running: bool = _completed_segments % 3 == 2
	var direction: Vector2 = offset.normalized()
	var target_speed: float = run_speed if running else walk_speed
	velocity = velocity.move_toward(direction * target_speed, acceleration * delta)
	move_and_slide()
	_visual.set_motion(direction, velocity.length(), running)


func _add_collision() -> void:
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	collision.position = Vector2(0.0, -5.0)
	collision.shape = circle
	add_child(collision)

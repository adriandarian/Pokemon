class_name Faux2DCameraRig
extends Node3D

@export var target: Node3D
@export var follow_smoothing: float = 7.0
@export var gameplay_size: float = 21.0
@export var overview_size: float = 40.5
@export var min_gameplay_size: float = 12.0
@export var max_gameplay_size: float = 34.0
@export var zoom_step: float = 1.5
@export var orbit_sensitivity: float = 0.006
@export_range(20.0, 55.0, 1.0) var min_pitch_degrees: float = 28.0
@export_range(35.0, 75.0, 1.0) var max_pitch_degrees: float = 58.0

@onready var camera: Camera3D = $Camera3D

var _overview_enabled: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _orbit_distance: float = 1.0
var _gameplay_zoom_size: float


func _ready() -> void:
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_gameplay_zoom_size = clampf(gameplay_size, min_gameplay_size, max_gameplay_size)
	camera.size = _gameplay_zoom_size
	camera.current = true
	camera.position = Vector3(0.0, 26.0, 40.0)
	_orbit_distance = camera.position.length()
	_pitch = asin(camera.position.y / _orbit_distance)
	_yaw = atan2(camera.position.x, camera.position.z)
	_apply_orbit()
	_snap_to_target()


func _process(delta: float) -> void:
	if _overview_enabled or target == null:
		return
	var desired := Vector3(target.global_position.x, 0.0, target.global_position.z)
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_smoothing * delta))


func set_overview_enabled(enabled: bool) -> void:
	_overview_enabled = enabled
	camera.size = overview_size if enabled else _gameplay_zoom_size
	if enabled:
		global_position = Vector3(0.0, 0.0, -12.5)
	else:
		_snap_to_target()


func orbit_by(mouse_delta: Vector2) -> void:
	if _overview_enabled:
		return
	_yaw = wrapf(_yaw - mouse_delta.x * orbit_sensitivity, -PI, PI)
	_pitch = clampf(
		_pitch - mouse_delta.y * orbit_sensitivity,
		deg_to_rad(min_pitch_degrees),
		deg_to_rad(max_pitch_degrees)
	)
	_apply_orbit()


func zoom_by_steps(wheel_steps: float) -> void:
	if _overview_enabled:
		return
	_gameplay_zoom_size = clampf(
		_gameplay_zoom_size - wheel_steps * zoom_step,
		min_gameplay_size,
		max_gameplay_size
	)
	camera.size = _gameplay_zoom_size


func get_camera() -> Camera3D:
	return camera


func get_orbit_angles() -> Vector2:
	return Vector2(_yaw, _pitch)


func get_gameplay_zoom_size() -> float:
	return _gameplay_zoom_size


func _apply_orbit() -> void:
	var horizontal_distance: float = _orbit_distance * cos(_pitch)
	camera.position = Vector3(
		horizontal_distance * sin(_yaw),
		_orbit_distance * sin(_pitch),
		horizontal_distance * cos(_yaw)
	)
	camera.look_at(global_position, Vector3.UP)


func _snap_to_target() -> void:
	if target != null:
		global_position = Vector3(target.global_position.x, 0.0, target.global_position.z)

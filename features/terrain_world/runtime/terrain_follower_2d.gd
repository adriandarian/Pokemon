class_name TerrainFollower2D
extends Node

signal terrain_sample_changed(sample: TerrainSample)

var _query: TerrainQuery
var _target: Node2D
var _continuous: bool = true
var _last_cell: Vector2i = Vector2i(-2147483648, -2147483648)
var _last_sample: TerrainSample


func configure(query: TerrainQuery, target: Node2D, continuous: bool = true) -> void:
	_query = query
	_target = target
	_continuous = continuous
	set_physics_process(_continuous)
	sync_now()


func _ready() -> void:
	set_physics_process(_continuous)
	sync_now()


func _physics_process(_delta: float) -> void:
	sync_now()


func sync_now() -> void:
	if _query == null or not is_instance_valid(_target):
		return
	var sample: TerrainSample = _query.sample_at(_target.global_position)
	if not sample.valid:
		return
	var elevation_changed: bool = (
		_last_sample == null
		or not is_equal_approx(_last_sample.elevation_pixels, sample.elevation_pixels)
	)
	var cell_changed: bool = sample.cell != _last_cell
	if not elevation_changed and not cell_changed:
		return
	_last_cell = sample.cell
	_last_sample = sample
	if _target.has_method("set_ground_elevation_pixels"):
		_target.call("set_ground_elevation_pixels", sample.elevation_pixels)
	terrain_sample_changed.emit(sample)


func get_last_sample() -> TerrainSample:
	return _last_sample


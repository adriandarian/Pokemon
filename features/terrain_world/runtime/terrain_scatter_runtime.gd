class_name TerrainScatterRuntime
extends Node

signal prop_activated(prop: AdventureProp)
signal prop_deactivated(prop: AdventureProp)

var _profile: TerrainScatterProfile
var _terrain_world: TerrainWorld
var _props_root: Node2D
var _wind_source: AmbientWind
var _active_props_by_chunk: Dictionary[Vector2i, Array] = {}


func configure(
	profile: TerrainScatterProfile,
	terrain_world: TerrainWorld,
	props_root: Node2D,
	wind_source: AmbientWind
) -> bool:
	if profile == null or terrain_world == null or props_root == null:
		push_error("TerrainScatterRuntime requires a profile, terrain world, and props root.")
		return false
	_disconnect_terrain_signals()
	_clear_active_props()
	_profile = profile
	_terrain_world = terrain_world
	_props_root = props_root
	_wind_source = wind_source
	_terrain_world.chunk_activated.connect(_on_chunk_activated)
	_terrain_world.chunk_deactivated.connect(_on_chunk_deactivated)
	for chunk_coord: Vector2i in _terrain_world.get_active_chunk_coords():
		_activate_chunk(chunk_coord)
	return true


func get_active_prop_count() -> int:
	var count: int = 0
	for props: Array in _active_props_by_chunk.values():
		count += props.size()
	return count


func get_chunk_prop_count(chunk_coord: Vector2i) -> int:
	var props: Array = _active_props_by_chunk.get(chunk_coord, []) as Array
	return props.size()


func _exit_tree() -> void:
	_disconnect_terrain_signals()
	_clear_active_props()


func _activate_chunk(chunk_coord: Vector2i) -> void:
	if _active_props_by_chunk.has(chunk_coord):
		return
	var placements: Array[TerrainScatterPlacement] = TerrainScatterGenerator.generate_chunk(
		_profile,
		_terrain_world.region,
		_terrain_world.get_query(),
		chunk_coord
	)
	var props: Array[AdventureProp] = []
	for index: int in range(placements.size()):
		var placement: TerrainScatterPlacement = placements[index]
		var kind: AdventureProp.Kind = _kind_for_visual_id(placement.visual_id)
		if kind < 0:
			continue
		var prop := AdventureProp.new()
		prop.name = "%s_%d_%d_%d" % [
			placement.scatter_id,
			chunk_coord.x,
			chunk_coord.y,
			index,
		]
		prop.configure(kind)
		prop.position = placement.world_position
		_props_root.add_child(prop)
		prop.set_wind_source(_wind_source)
		_terrain_world.attach_follower(prop, false)
		props.append(prop)
		prop_activated.emit(prop)
	_active_props_by_chunk[chunk_coord] = props


func _on_chunk_activated(chunk_coord: Vector2i) -> void:
	_activate_chunk(chunk_coord)


func _on_chunk_deactivated(chunk_coord: Vector2i) -> void:
	var props: Array = _active_props_by_chunk.get(chunk_coord, []) as Array
	_active_props_by_chunk.erase(chunk_coord)
	for prop: AdventureProp in props:
		if not is_instance_valid(prop):
			continue
		prop_deactivated.emit(prop)
		prop.queue_free()


func _clear_active_props() -> void:
	for props: Array in _active_props_by_chunk.values():
		for prop_value in props:
			if not is_instance_valid(prop_value):
				continue
			var prop := prop_value as AdventureProp
			prop_deactivated.emit(prop)
			prop.queue_free()
	_active_props_by_chunk.clear()


func _disconnect_terrain_signals() -> void:
	if _terrain_world == null:
		return
	if _terrain_world.chunk_activated.is_connected(_on_chunk_activated):
		_terrain_world.chunk_activated.disconnect(_on_chunk_activated)
	if _terrain_world.chunk_deactivated.is_connected(_on_chunk_deactivated):
		_terrain_world.chunk_deactivated.disconnect(_on_chunk_deactivated)


func _kind_for_visual_id(visual_id: StringName) -> AdventureProp.Kind:
	match visual_id:
		&"tree":
			return AdventureProp.Kind.TREE
		&"rock":
			return AdventureProp.Kind.ROCK
		_:
			push_error("Unknown terrain scatter visual ID: %s" % visual_id)
			return -1 as AdventureProp.Kind

class_name SettlementRuntime
extends Node

signal prop_activated(prop: AdventureProp)
signal prop_deactivated(prop: AdventureProp)

var _definition: SettlementDefinition
var _terrain_world: TerrainWorld
var _props_root: Node2D
var _wind_source: AmbientWind
var _definitions_by_chunk: Dictionary[Vector2i, Array] = {}
var _active_props_by_id: Dictionary[StringName, AdventureProp] = {}


func configure(
	definition: SettlementDefinition,
	terrain_world: TerrainWorld,
	props_root: Node2D,
	wind_source: AmbientWind
) -> bool:
	if definition == null or terrain_world == null or props_root == null:
		push_error("SettlementRuntime requires a definition, terrain world, and props root.")
		return false
	_disconnect_terrain_signals()
	_clear_active_props()
	_definition = definition
	_terrain_world = terrain_world
	_props_root = props_root
	_wind_source = wind_source
	_index_definitions()
	_terrain_world.chunk_activated.connect(_on_chunk_activated)
	_terrain_world.chunk_deactivated.connect(_on_chunk_deactivated)
	for chunk_coord: Vector2i in _terrain_world.get_active_chunk_coords():
		_activate_chunk(chunk_coord)
	return true


func get_active_prop_count() -> int:
	return _active_props_by_id.size()


func get_active_prop(prop_id: StringName) -> AdventureProp:
	return _active_props_by_id.get(prop_id) as AdventureProp


func get_definition() -> SettlementDefinition:
	return _definition


func _exit_tree() -> void:
	_disconnect_terrain_signals()
	_clear_active_props()


func _index_definitions() -> void:
	_definitions_by_chunk.clear()
	var seen_ids: Dictionary[StringName, bool] = {}
	for definition in _definition.props:
		if definition == null:
			continue
		if definition.prop_id == &"" or seen_ids.has(definition.prop_id):
			push_error("Settlement %s contains a missing or duplicate prop ID: %s" % [
				_definition.settlement_id,
				definition.prop_id,
			])
			continue
		seen_ids[definition.prop_id] = true
		var chunk_coord: Vector2i = _terrain_world.world_to_chunk(definition.world_position)
		if not _definitions_by_chunk.has(chunk_coord):
			_definitions_by_chunk[chunk_coord] = []
		(_definitions_by_chunk[chunk_coord] as Array).append(definition)


func _activate_chunk(chunk_coord: Vector2i) -> void:
	var definitions: Array = _definitions_by_chunk.get(chunk_coord, []) as Array
	for definition in definitions:
		if definition == null or _active_props_by_id.has(definition.prop_id):
			continue
		var prop := AdventureProp.new()
		prop.name = String(definition.prop_id).to_pascal_case()
		prop.configure(
			definition.kind,
			definition.interaction_title,
			definition.interaction_text
		)
		prop.position = definition.world_position
		_props_root.add_child(prop)
		prop.set_wind_source(_wind_source)
		_terrain_world.attach_follower(prop, false)
		_active_props_by_id[definition.prop_id] = prop
		prop_activated.emit(prop)


func _on_chunk_activated(chunk_coord: Vector2i) -> void:
	_activate_chunk(chunk_coord)


func _on_chunk_deactivated(chunk_coord: Vector2i) -> void:
	var definitions: Array = _definitions_by_chunk.get(chunk_coord, []) as Array
	for definition in definitions:
		if definition == null:
			continue
		var prop: AdventureProp = _active_props_by_id.get(definition.prop_id) as AdventureProp
		if prop == null:
			continue
		_active_props_by_id.erase(definition.prop_id)
		prop_deactivated.emit(prop)
		prop.queue_free()


func _clear_active_props() -> void:
	for prop_value in _active_props_by_id.values():
		if not is_instance_valid(prop_value):
			continue
		var prop := prop_value as AdventureProp
		prop_deactivated.emit(prop)
		prop.queue_free()
	_active_props_by_id.clear()


func _disconnect_terrain_signals() -> void:
	if _terrain_world == null:
		return
	if _terrain_world.chunk_activated.is_connected(_on_chunk_activated):
		_terrain_world.chunk_activated.disconnect(_on_chunk_activated)
	if _terrain_world.chunk_deactivated.is_connected(_on_chunk_deactivated):
		_terrain_world.chunk_deactivated.disconnect(_on_chunk_deactivated)

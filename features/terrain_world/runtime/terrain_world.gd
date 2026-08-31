class_name TerrainWorld
extends Node2D

signal terrain_ready
signal chunk_activated(chunk_coord: Vector2i)
signal chunk_deactivated(chunk_coord: Vector2i)
signal streaming_settled

@export var region: TerrainRegionDefinition
@export var compiled_chunks: Array[TerrainChunkData] = []
@export var materialize_all_on_ready: bool = true
@export_range(1, 8, 1) var max_chunk_activations_per_frame: int = 2

var _query := TerrainQuery.new()
var _chunks_root: Node2D
var _road_renderer: TerrainRoadRenderer
var _chunk_data_by_coord: Dictionary[Vector2i, TerrainChunkData] = {}
var _active_chunks: Dictionary[Vector2i, TerrainChunk] = {}
var _streaming_focus: Node2D
var _streaming_radius_chunks: int = 1
var _last_focus_chunk := Vector2i(-2147483648, -2147483648)
var _pending_activation_coords: Array[Vector2i] = []
var _peak_activation_batch_usec: int = 0


func _ready() -> void:
	if not _query.configure(region, compiled_chunks):
		push_error("TerrainWorld failed to configure its compiled region.")
		return
	_chunks_root = Node2D.new()
	_chunks_root.name = "Chunks"
	add_child(_chunks_root)
	var ordered_chunks: Array[TerrainChunkData] = compiled_chunks.duplicate()
	ordered_chunks.sort_custom(func(a: TerrainChunkData, b: TerrainChunkData) -> bool:
		return a.chunk_coord.y < b.chunk_coord.y or (
			a.chunk_coord.y == b.chunk_coord.y and a.chunk_coord.x < b.chunk_coord.x
		)
	)
	for chunk_data: TerrainChunkData in ordered_chunks:
		_chunk_data_by_coord[chunk_data.chunk_coord] = chunk_data
		if materialize_all_on_ready:
			_activate_chunk(chunk_data.chunk_coord)
	_road_renderer = TerrainRoadRenderer.new()
	_road_renderer.name = "RoadRenderer"
	_road_renderer.configure(region, _query)
	add_child(_road_renderer)
	_sync_road_renderer()
	set_physics_process(false)
	terrain_ready.emit()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_streaming_focus):
		_streaming_focus = null
		_last_focus_chunk = Vector2i(-2147483648, -2147483648)
		_pending_activation_coords.clear()
		set_physics_process(false)
		return
	var focus_chunk: Vector2i = world_to_chunk(_streaming_focus.global_position)
	if focus_chunk != _last_focus_chunk:
		_last_focus_chunk = focus_chunk
		_refresh_streamed_chunks(focus_chunk)
	_drain_activation_queue()


func get_query() -> TerrainQuery:
	return _query


func get_world_bounds() -> Rect2:
	return _query.get_world_bounds()


func get_active_chunk_count() -> int:
	return _active_chunks.size()


func get_pending_activation_count() -> int:
	return _pending_activation_coords.size()


func is_streaming_settled() -> bool:
	return _pending_activation_coords.is_empty()


func get_peak_activation_batch_usec() -> int:
	return _peak_activation_batch_usec


func get_active_chunk_coords() -> Array[Vector2i]:
	var result: Array[Vector2i] = _active_chunks.keys()
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return result


func world_to_chunk(world_position: Vector2) -> Vector2i:
	var cell: Vector2i = _query.world_to_cell(world_position)
	return Vector2i(
		floori(float(cell.x) / float(region.chunk_size_cells.x)),
		floori(float(cell.y) / float(region.chunk_size_cells.y))
	)


func get_collision_shape_count() -> int:
	var count: int = 0
	for chunk: TerrainChunk in _active_chunks.values():
		count += chunk.get_collision_shape_count()
	return count


func enable_streaming(focus: Node2D, radius_chunks: int = 1) -> void:
	if focus == null:
		disable_streaming()
		return
	_streaming_focus = focus
	_streaming_radius_chunks = maxi(0, radius_chunks)
	_last_focus_chunk = world_to_chunk(focus.global_position)
	set_physics_process(true)
	_refresh_streamed_chunks(_last_focus_chunk)
	_drain_activation_queue()


func disable_streaming() -> void:
	_streaming_focus = null
	_last_focus_chunk = Vector2i(-2147483648, -2147483648)
	_pending_activation_coords.clear()
	set_physics_process(false)
	for chunk_coord: Vector2i in _chunk_data_by_coord:
		_activate_chunk(chunk_coord)
	_sync_road_renderer()


func attach_follower(target: Node2D, continuous: bool = true) -> TerrainFollower2D:
	if target == null:
		return null
	var existing := target.get_node_or_null("TerrainFollower2D") as TerrainFollower2D
	if existing != null:
		existing.configure(_query, target, continuous)
		return existing
	var follower := TerrainFollower2D.new()
	follower.name = "TerrainFollower2D"
	follower.configure(_query, target, continuous)
	target.add_child(follower)
	return follower


func _refresh_streamed_chunks(focus_chunk: Vector2i) -> void:
	var desired: Dictionary[Vector2i, bool] = {}
	for offset_y: int in range(-_streaming_radius_chunks, _streaming_radius_chunks + 1):
		for offset_x: int in range(-_streaming_radius_chunks, _streaming_radius_chunks + 1):
			var chunk_coord := focus_chunk + Vector2i(offset_x, offset_y)
			if _chunk_data_by_coord.has(chunk_coord):
				desired[chunk_coord] = true
	var active_snapshot: Array[Vector2i] = _active_chunks.keys()
	for chunk_coord: Vector2i in active_snapshot:
		if not desired.has(chunk_coord):
			_deactivate_chunk(chunk_coord)
	_pending_activation_coords.clear()
	var desired_coords: Array[Vector2i] = desired.keys()
	desired_coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var a_distance: int = a.distance_squared_to(focus_chunk)
		var b_distance: int = b.distance_squared_to(focus_chunk)
		return a_distance < b_distance or (
			a_distance == b_distance
			and (a.y < b.y or (a.y == b.y and a.x < b.x))
		)
	)
	for chunk_coord: Vector2i in desired_coords:
		if not _active_chunks.has(chunk_coord):
			_pending_activation_coords.append(chunk_coord)
	_sync_road_renderer()


func _drain_activation_queue() -> void:
	if _pending_activation_coords.is_empty():
		return
	var batch_started: int = Time.get_ticks_usec()
	var activation_count: int = mini(
		max_chunk_activations_per_frame,
		_pending_activation_coords.size()
	)
	for _index: int in range(activation_count):
		_activate_chunk(_pending_activation_coords.pop_front())
	var batch_usec: int = Time.get_ticks_usec() - batch_started
	_peak_activation_batch_usec = maxi(_peak_activation_batch_usec, batch_usec)
	_sync_road_renderer()
	if _pending_activation_coords.is_empty():
		streaming_settled.emit()


func _activate_chunk(chunk_coord: Vector2i) -> void:
	if _active_chunks.has(chunk_coord):
		return
	var chunk_data: TerrainChunkData = _chunk_data_by_coord.get(chunk_coord) as TerrainChunkData
	if chunk_data == null:
		return
	var chunk := TerrainChunk.new()
	chunk.name = "TerrainChunk_%d_%d" % [chunk_coord.x, chunk_coord.y]
	chunk.configure(chunk_data, region, _query)
	_chunks_root.add_child(chunk)
	_active_chunks[chunk_coord] = chunk
	chunk_activated.emit(chunk_coord)


func _deactivate_chunk(chunk_coord: Vector2i) -> void:
	var chunk: TerrainChunk = _active_chunks.get(chunk_coord) as TerrainChunk
	if chunk == null:
		return
	_active_chunks.erase(chunk_coord)
	_chunks_root.remove_child(chunk)
	chunk.queue_free()
	chunk_deactivated.emit(chunk_coord)


func _sync_road_renderer() -> void:
	if _road_renderer == null:
		return
	var active_coords: Array[Vector2i] = _active_chunks.keys()
	_road_renderer.set_active_chunk_coords(active_coords)

class_name TerrainQuery
extends RefCounted

const MAX_OPEN_ELEVATION_DELTA: float = 0.34

var _region: TerrainRegionDefinition
var _chunks: Dictionary[Vector2i, TerrainChunkData] = {}


func configure(region: TerrainRegionDefinition, chunks: Array[TerrainChunkData]) -> bool:
	_region = region
	_chunks.clear()
	if _region == null:
		push_error("TerrainQuery requires a TerrainRegionDefinition.")
		return false
	for chunk: TerrainChunkData in chunks:
		if chunk == null or not chunk.has_valid_array_sizes():
			push_error("TerrainQuery received missing or malformed chunk data.")
			return false
		if (
			chunk.chunk_coord.x < 0
			or chunk.chunk_coord.y < 0
			or chunk.chunk_coord.x >= _region.chunk_count.x
			or chunk.chunk_coord.y >= _region.chunk_count.y
		):
			push_error("Terrain chunk coordinate lies outside region bounds: %s" % chunk.chunk_coord)
			return false
		if chunk.region_id != _region.region_id or chunk.compiler_version != _region.compiler_version:
			push_error("Terrain chunk metadata does not match region %s." % _region.region_id)
			return false
		if (
			chunk.chunk_size_cells != _region.chunk_size_cells
			or not is_equal_approx(chunk.cell_size, _region.cell_size)
			or not is_equal_approx(chunk.elevation_step_pixels, _region.elevation_step_pixels)
		):
			push_error("Terrain chunk scale does not match region %s." % _region.region_id)
			return false
		if _chunks.has(chunk.chunk_coord):
			push_error("Duplicate terrain chunk coordinate: %s" % chunk.chunk_coord)
			return false
		_chunks[chunk.chunk_coord] = chunk
	var expected_count: int = _region.chunk_count.x * _region.chunk_count.y
	if _chunks.size() != expected_count:
		push_error("TerrainQuery expected %d chunks but received %d." % [expected_count, _chunks.size()])
		return false
	return true


func get_region() -> TerrainRegionDefinition:
	return _region


func get_chunk_data(chunk_coord: Vector2i) -> TerrainChunkData:
	return _chunks.get(chunk_coord) as TerrainChunkData


func get_world_bounds() -> Rect2:
	return _region.get_world_bounds() if _region != null else Rect2()


func world_to_cell(world_position: Vector2) -> Vector2i:
	if _region == null:
		return Vector2i.ZERO
	return Vector2i(
		floori(world_position.x / _region.cell_size),
		floori(world_position.y / _region.cell_size)
	)


func cell_to_world_center(cell: Vector2i) -> Vector2:
	if _region == null:
		return Vector2.ZERO
	return (Vector2(cell) + Vector2(0.5, 0.5)) * _region.cell_size


func sample_at(world_position: Vector2) -> TerrainSample:
	var sample := sample_cell(world_to_cell(world_position))
	sample.world_position = world_position
	return sample


func sample_cell(cell: Vector2i) -> TerrainSample:
	var sample := TerrainSample.new()
	sample.cell = cell
	if _region == null or not _contains_cell(cell):
		return sample
	var chunk_size: Vector2i = _region.chunk_size_cells
	var chunk_coord := Vector2i(
		floori(float(cell.x) / float(chunk_size.x)),
		floori(float(cell.y) / float(chunk_size.y))
	)
	var chunk: TerrainChunkData = get_chunk_data(chunk_coord)
	if chunk == null:
		return sample
	var local_cell := Vector2i(posmod(cell.x, chunk_size.x), posmod(cell.y, chunk_size.y))
	sample.valid = true
	sample.chunk_coord = chunk_coord
	sample.local_cell = local_cell
	sample.world_position = cell_to_world_center(cell)
	sample.elevation_level = chunk.get_elevation(local_cell)
	sample.elevation_pixels = sample.elevation_level * chunk.elevation_step_pixels
	sample.surface = chunk.get_surface(local_cell)
	sample.biome_index = chunk.get_biome_index(local_cell)
	sample.traversal_flags = chunk.get_flags(local_cell)
	return sample


func elevation_pixels_at(world_position: Vector2) -> float:
	return sample_at(world_position).elevation_pixels


func is_cell_walkable(cell: Vector2i) -> bool:
	return sample_cell(cell).is_walkable()


func can_traverse_cells(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if from_cell.distance_squared_to(to_cell) != 1:
		return false
	var from_sample := sample_cell(from_cell)
	var to_sample := sample_cell(to_cell)
	if not from_sample.is_walkable() or not to_sample.is_walkable():
		return false
	return absf(from_sample.elevation_level - to_sample.elevation_level) <= MAX_OPEN_ELEVATION_DELTA


func is_edge_blocked(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	return not can_traverse_cells(from_cell, to_cell)


func to_view(world_position: Vector2) -> Vector2:
	return world_position + Vector2.UP * elevation_pixels_at(world_position)


func _contains_cell(cell: Vector2i) -> bool:
	var total: Vector2i = _region.get_total_size_cells()
	return cell.x >= 0 and cell.y >= 0 and cell.x < total.x and cell.y < total.y

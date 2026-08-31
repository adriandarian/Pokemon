class_name TerrainCompiler
extends RefCounted

const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN,
]


static func compile_region(region: TerrainRegionDefinition) -> Array[TerrainChunkData]:
	var empty_result: Array[TerrainChunkData] = []
	if not _validate_definition(region):
		return empty_result

	var total_size: Vector2i = region.get_total_size_cells()
	var cell_count: int = total_size.x * total_size.y
	var elevations: Array[float] = []
	var surfaces: Array[int] = []
	var biomes: Array[int] = []
	var flags: Array[int] = []
	elevations.resize(cell_count)
	surfaces.resize(cell_count)
	biomes.resize(cell_count)
	flags.resize(cell_count)

	var elevation_noise := FastNoiseLite.new()
	elevation_noise.seed = region.seed
	elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	elevation_noise.frequency = region.elevation_frequency
	elevation_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	elevation_noise.fractal_octaves = 3

	var moisture_noise := FastNoiseLite.new()
	moisture_noise.seed = region.seed + 7919
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	moisture_noise.frequency = region.moisture_frequency
	moisture_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	moisture_noise.fractal_octaves = 2

	for y: int in range(total_size.y):
		for x: int in range(total_size.x):
			var cell := Vector2i(x, y)
			var index: int = _global_index(cell, total_size)
			var height_value: float = elevation_noise.get_noise_2d(float(x), float(y))
			var moisture_value: float = moisture_noise.get_noise_2d(float(x), float(y))
			elevations[index] = 1.0 if height_value > region.raised_ground_threshold else 0.0
			surfaces[index] = TerrainChunkData.Surface.GRASS
			biomes[index] = _proposed_biome_index(region, elevations[index], moisture_value)
			flags[index] = TerrainChunkData.FLAG_WALKABLE

	for stamp: TerrainStampDefinition in region.stamps:
		_apply_stamp(region, stamp, elevations, surfaces, biomes, flags)

	if not _validate_required_routes(region, elevations, flags):
		return empty_result

	var chunks: Array[TerrainChunkData] = []
	for chunk_y: int in range(region.chunk_count.y):
		for chunk_x: int in range(region.chunk_count.x):
			var chunk_coord := Vector2i(chunk_x, chunk_y)
			chunks.append(_extract_chunk(region, chunk_coord, elevations, surfaces, biomes, flags))
	return chunks


static func _validate_definition(region: TerrainRegionDefinition) -> bool:
	if region == null:
		push_error("TerrainCompiler requires a region definition.")
		return false
	if region.region_id == &"" or region.compiler_version <= 0:
		push_error("Terrain region requires a stable ID and positive compiler version.")
		return false
	if region.chunk_count.x <= 0 or region.chunk_count.y <= 0:
		push_error("Terrain region chunk_count must be positive.")
		return false
	if region.chunk_size_cells.x <= 0 or region.chunk_size_cells.y <= 0:
		push_error("Terrain chunk_size_cells must be positive.")
		return false
	if region.cell_size <= 0.0 or region.elevation_step_pixels <= 0.0:
		push_error("Terrain cell and elevation scales must be positive.")
		return false
	if region.biomes.is_empty():
		push_error("Terrain region requires at least one biome definition.")
		return false
	var total: Vector2i = region.get_total_size_cells()
	var region_bounds := Rect2i(Vector2i.ZERO, total)
	for stamp: TerrainStampDefinition in region.stamps:
		if stamp == null or stamp.bounds.size.x <= 0 or stamp.bounds.size.y <= 0:
			push_error("Terrain region contains a missing or empty stamp.")
			return false
		if not region_bounds.encloses(stamp.bounds):
			push_error("Terrain stamp %s lies outside region bounds." % stamp.stamp_id)
			return false
		if stamp.biome_index >= region.biomes.size():
			push_error("Terrain stamp %s references an invalid biome index." % stamp.stamp_id)
			return false
	for point: Vector2i in region.required_route_points:
		if not region_bounds.has_point(point):
			push_error("Required terrain route point lies outside the region: %s" % point)
			return false
	return true


static func _proposed_biome_index(
	region: TerrainRegionDefinition,
	elevation: float,
	moisture: float
) -> int:
	if region.biomes.size() == 1:
		return 0
	if elevation >= 1.0 and region.biomes.size() >= 4:
		return 3
	if moisture > 0.28:
		return 0
	return mini(1, region.biomes.size() - 1)


static func _apply_stamp(
	region: TerrainRegionDefinition,
	stamp: TerrainStampDefinition,
	elevations: Array[float],
	surfaces: Array[int],
	biomes: Array[int],
	flags: Array[int]
) -> void:
	var total_size: Vector2i = region.get_total_size_cells()
	for y: int in range(stamp.bounds.position.y, stamp.bounds.end.y):
		for x: int in range(stamp.bounds.position.x, stamp.bounds.end.x):
			var cell := Vector2i(x, y)
			var index: int = _global_index(cell, total_size)
			match stamp.kind:
				TerrainStampDefinition.Kind.ELEVATION:
					elevations[index] = stamp.target_elevation
					flags[index] |= TerrainChunkData.FLAG_PROTECTED
				TerrainStampDefinition.Kind.BIOME:
					if stamp.biome_index >= 0:
						biomes[index] = stamp.biome_index
				TerrainStampDefinition.Kind.ROAD:
					if not _cell_is_near_road(stamp, cell):
						continue
					surfaces[index] = TerrainChunkData.Surface.PATH
					flags[index] = TerrainChunkData.FLAG_WALKABLE | TerrainChunkData.FLAG_PROTECTED
				TerrainStampDefinition.Kind.WATER:
					surfaces[index] = TerrainChunkData.Surface.WATER
					flags[index] = TerrainChunkData.FLAG_PROTECTED
				TerrainStampDefinition.Kind.PARCEL:
					elevations[index] = stamp.target_elevation
					surfaces[index] = TerrainChunkData.Surface.STONE
					flags[index] = TerrainChunkData.FLAG_WALKABLE | TerrainChunkData.FLAG_PROTECTED
					if stamp.biome_index >= 0:
						biomes[index] = stamp.biome_index
				TerrainStampDefinition.Kind.STAIR:
					elevations[index] = _connector_elevation(stamp, cell, true)
					surfaces[index] = TerrainChunkData.Surface.STAIR
					flags[index] = (
						TerrainChunkData.FLAG_WALKABLE
						| TerrainChunkData.FLAG_CONNECTOR
						| TerrainChunkData.FLAG_PROTECTED
					)
				TerrainStampDefinition.Kind.RAMP:
					elevations[index] = _connector_elevation(stamp, cell, false)
					surfaces[index] = TerrainChunkData.Surface.RAMP
					flags[index] = (
						TerrainChunkData.FLAG_WALKABLE
						| TerrainChunkData.FLAG_CONNECTOR
						| TerrainChunkData.FLAG_PROTECTED
					)
				TerrainStampDefinition.Kind.BRIDGE:
					elevations[index] = stamp.target_elevation
					surfaces[index] = TerrainChunkData.Surface.BRIDGE
					flags[index] = (
						TerrainChunkData.FLAG_WALKABLE
						| TerrainChunkData.FLAG_CONNECTOR
						| TerrainChunkData.FLAG_PROTECTED
					)
				_:
					push_error("Unsupported terrain stamp kind: %s" % stamp.kind)


static func _cell_is_near_road(stamp: TerrainStampDefinition, cell: Vector2i) -> bool:
	if stamp.path_points.size() < 2:
		return true
	var point := Vector2(cell) + Vector2(0.5, 0.5)
	var minor_cells: float = float(mini(stamp.bounds.size.x, stamp.bounds.size.y))
	var half_width: float = maxf(0.85, minor_cells * 0.24)
	for index: int in range(stamp.path_points.size() - 1):
		if _distance_to_segment(point, stamp.path_points[index], stamp.path_points[index + 1]) <= half_width:
			return true
	return false


static func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment: Vector2 = finish - start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= 0.0001:
		return point.distance_to(start)
	var amount: float = clampf((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(start + segment * amount)


static func _connector_elevation(stamp: TerrainStampDefinition, cell: Vector2i, stepped: bool) -> float:
	var length: int = stamp.bounds.size.x if stamp.axis == TerrainStampDefinition.Axis.X else stamp.bounds.size.y
	var offset: int = cell.x - stamp.bounds.position.x if stamp.axis == TerrainStampDefinition.Axis.X else cell.y - stamp.bounds.position.y
	var amount: float = float(offset) / float(maxi(1, length - 1))
	if stepped:
		var tread_count: int = maxi(1, length - 1)
		amount = roundf(amount * float(tread_count)) / float(tread_count)
	return lerpf(stamp.start_elevation, stamp.end_elevation, amount)


static func _extract_chunk(
	region: TerrainRegionDefinition,
	chunk_coord: Vector2i,
	elevations: Array[float],
	surfaces: Array[int],
	biomes: Array[int],
	flags: Array[int]
) -> TerrainChunkData:
	var chunk := TerrainChunkData.new()
	chunk.compiler_version = region.compiler_version
	chunk.region_id = region.region_id
	chunk.chunk_coord = chunk_coord
	chunk.chunk_size_cells = region.chunk_size_cells
	chunk.cell_size = region.cell_size
	chunk.elevation_step_pixels = region.elevation_step_pixels
	var local_count: int = region.chunk_size_cells.x * region.chunk_size_cells.y
	chunk.elevations.resize(local_count)
	chunk.surface_ids.resize(local_count)
	chunk.biome_indices.resize(local_count)
	chunk.traversal_flags.resize(local_count)
	var total_size: Vector2i = region.get_total_size_cells()
	var origin: Vector2i = chunk_coord * region.chunk_size_cells
	for local_y: int in range(region.chunk_size_cells.y):
		for local_x: int in range(region.chunk_size_cells.x):
			var local_cell := Vector2i(local_x, local_y)
			var global_cell: Vector2i = origin + local_cell
			var source_index: int = _global_index(global_cell, total_size)
			var target_index: int = local_y * region.chunk_size_cells.x + local_x
			chunk.elevations[target_index] = elevations[source_index]
			chunk.surface_ids[target_index] = surfaces[source_index]
			chunk.biome_indices[target_index] = biomes[source_index]
			chunk.traversal_flags[target_index] = flags[source_index]
	return chunk


static func _validate_required_routes(
	region: TerrainRegionDefinition,
	elevations: Array[float],
	flags: Array[int]
) -> bool:
	if region.required_route_points.is_empty():
		return true
	var total_size: Vector2i = region.get_total_size_cells()
	var start: Vector2i = region.required_route_points[0]
	if not _is_walkable(start, total_size, flags):
		push_error("Terrain required route starts on a blocked cell: %s" % start)
		return false
	var frontier: Array[Vector2i] = [start]
	var visited: Dictionary[Vector2i, bool] = {start: true}
	var cursor: int = 0
	while cursor < frontier.size():
		var current: Vector2i = frontier[cursor]
		cursor += 1
		for direction: Vector2i in CARDINAL_DIRECTIONS:
			var next: Vector2i = current + direction
			if visited.has(next) or not _contains_cell(next, total_size):
				continue
			if not _can_traverse(current, next, total_size, elevations, flags):
				continue
			visited[next] = true
			frontier.append(next)
	for point: Vector2i in region.required_route_points:
		if not visited.has(point):
			push_error("Terrain compiler found an unreachable required route point: %s" % point)
			return false
	return true


static func _can_traverse(
	from_cell: Vector2i,
	to_cell: Vector2i,
	total_size: Vector2i,
	elevations: Array[float],
	flags: Array[int]
) -> bool:
	if not _is_walkable(from_cell, total_size, flags) or not _is_walkable(to_cell, total_size, flags):
		return false
	var from_index: int = _global_index(from_cell, total_size)
	var to_index: int = _global_index(to_cell, total_size)
	return absf(elevations[from_index] - elevations[to_index]) <= TerrainQuery.MAX_OPEN_ELEVATION_DELTA


static func _is_walkable(cell: Vector2i, total_size: Vector2i, flags: Array[int]) -> bool:
	if not _contains_cell(cell, total_size):
		return false
	return (flags[_global_index(cell, total_size)] & TerrainChunkData.FLAG_WALKABLE) != 0


static func _contains_cell(cell: Vector2i, total_size: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < total_size.x and cell.y < total_size.y


static func _global_index(cell: Vector2i, total_size: Vector2i) -> int:
	return cell.y * total_size.x + cell.x

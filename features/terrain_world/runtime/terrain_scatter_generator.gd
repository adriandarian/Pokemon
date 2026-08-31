class_name TerrainScatterGenerator
extends RefCounted


static func generate_chunk(
	profile: TerrainScatterProfile,
	region: TerrainRegionDefinition,
	query: TerrainQuery,
	chunk_coord: Vector2i
) -> Array[TerrainScatterPlacement]:
	var placements: Array[TerrainScatterPlacement] = []
	if profile == null or region == null or query == null:
		return placements
	if (
		chunk_coord.x < 0
		or chunk_coord.y < 0
		or chunk_coord.x >= region.chunk_count.x
		or chunk_coord.y >= region.chunk_count.y
	):
		return placements
	var chunk_size_pixels: Vector2 = Vector2(region.chunk_size_cells) * region.cell_size
	var chunk_origin: Vector2 = Vector2(chunk_coord) * chunk_size_pixels
	for definition: TerrainScatterDefinition in profile.definitions:
		if definition == null or definition.visual_id == &"":
			continue
		var random := RandomNumberGenerator.new()
		random.seed = _scatter_seed(region.seed, chunk_coord, definition.seed_offset)
		var margin: float = definition.chunk_margin_cells * region.cell_size
		var available_size: Vector2 = chunk_size_pixels - Vector2.ONE * margin * 2.0
		if available_size.x <= 0.0 or available_size.y <= 0.0:
			continue
		var accepted_count: int = 0
		for _attempt: int in range(definition.attempts_per_chunk):
			if accepted_count >= definition.max_instances_per_chunk:
				break
			var candidate := chunk_origin + Vector2(
				margin + random.randf() * available_size.x,
				margin + random.randf() * available_size.y
			)
			if _is_excluded(profile, candidate):
				continue
			var sample: TerrainSample = query.sample_at(candidate)
			if (
				not sample.valid
				or not sample.is_walkable()
				or sample.surface != TerrainChunkData.Surface.GRASS
			):
				continue
			if not _biome_is_allowed(definition, region, sample.biome_index):
				continue
			if not _has_surface_clearance(query, sample.cell, definition.surface_clearance_cells):
				continue
			var spacing_pixels: float = definition.min_spacing_cells * region.cell_size
			if not _has_spacing(placements, candidate, spacing_pixels):
				continue
			var placement := TerrainScatterPlacement.new()
			placement.scatter_id = definition.scatter_id
			placement.visual_id = definition.visual_id
			placement.world_position = candidate
			placement.spacing_pixels = spacing_pixels
			placements.append(placement)
			accepted_count += 1
	placements.sort_custom(func(a: TerrainScatterPlacement, b: TerrainScatterPlacement) -> bool:
		return a.world_position.y < b.world_position.y or (
			is_equal_approx(a.world_position.y, b.world_position.y)
			and a.world_position.x < b.world_position.x
		)
	)
	return placements


static func _scatter_seed(base_seed: int, chunk_coord: Vector2i, offset: int) -> int:
	return (
		base_seed
		^ (chunk_coord.x * 73856093)
		^ (chunk_coord.y * 19349663)
		^ (offset * 83492791)
	)


static func _is_excluded(profile: TerrainScatterProfile, position: Vector2) -> bool:
	for exclusion: Rect2 in profile.exclusion_rects:
		if exclusion.has_point(position):
			return true
	return false


static func _biome_is_allowed(
	definition: TerrainScatterDefinition,
	region: TerrainRegionDefinition,
	biome_index: int
) -> bool:
	if biome_index < 0 or biome_index >= region.biomes.size():
		return false
	if definition.allowed_biome_ids.is_empty():
		return true
	var biome: TerrainBiomeDefinition = region.biomes[biome_index]
	return biome != null and definition.allowed_biome_ids.has(biome.biome_id)


static func _has_surface_clearance(
	query: TerrainQuery,
	center_cell: Vector2i,
	clearance_cells: int
) -> bool:
	for offset_y: int in range(-clearance_cells, clearance_cells + 1):
		for offset_x: int in range(-clearance_cells, clearance_cells + 1):
			var sample: TerrainSample = query.sample_cell(center_cell + Vector2i(offset_x, offset_y))
			if not sample.valid or sample.surface != TerrainChunkData.Surface.GRASS:
				return false
	return true


static func _has_spacing(
	placements: Array[TerrainScatterPlacement],
	candidate: Vector2,
	spacing_pixels: float
) -> bool:
	for placement: TerrainScatterPlacement in placements:
		var required: float = maxf(spacing_pixels, placement.spacing_pixels)
		if candidate.distance_squared_to(placement.world_position) < required * required:
			return false
	return true


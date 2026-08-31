class_name TerrainRoadRenderer
extends Node2D

const SAMPLES_PER_SPAN: int = 12

var _region: TerrainRegionDefinition
var _query: TerrainQuery
var _active_chunk_coords: Dictionary[Vector2i, bool] = {}
var _active_filter_configured: bool = false


func configure(region: TerrainRegionDefinition, query: TerrainQuery) -> void:
	_region = region
	_query = query
	queue_redraw()


func _ready() -> void:
	queue_redraw()


func set_active_chunk_coords(chunk_coords: Array[Vector2i]) -> void:
	_active_filter_configured = true
	_active_chunk_coords.clear()
	for chunk_coord: Vector2i in chunk_coords:
		_active_chunk_coords[chunk_coord] = true
	queue_redraw()


func _draw() -> void:
	if _region == null or _query == null:
		return
	for stamp: TerrainStampDefinition in _region.stamps:
		if stamp.kind != TerrainStampDefinition.Kind.ROAD:
			continue
		var canonical_points: PackedVector2Array = _sample_centerline(stamp)
		if canonical_points.size() < 2:
			continue
		var minor_cells: int = mini(stamp.bounds.size.x, stamp.bounds.size.y)
		var road_width: float = maxf(
			_region.cell_size * 1.15,
			float(minor_cells) * _region.cell_size * 0.24
		)
		_draw_projected_segments(canonical_points, road_width)


func _sample_centerline(stamp: TerrainStampDefinition) -> PackedVector2Array:
	var controls: Array[Vector2] = stamp.path_points.duplicate()
	if controls.size() < 2:
		var bounds_center: Vector2 = Vector2(stamp.bounds.position) + Vector2(stamp.bounds.size) * 0.5
		if stamp.bounds.size.x >= stamp.bounds.size.y:
			controls = [
				Vector2(float(stamp.bounds.position.x), bounds_center.y),
				Vector2(float(stamp.bounds.end.x), bounds_center.y),
			]
		else:
			controls = [
				Vector2(bounds_center.x, float(stamp.bounds.position.y)),
				Vector2(bounds_center.x, float(stamp.bounds.end.y)),
			]
	var result := PackedVector2Array()
	for span: int in range(controls.size() - 1):
		var before: Vector2 = controls[maxi(0, span - 1)]
		var start: Vector2 = controls[span]
		var finish: Vector2 = controls[span + 1]
		var after: Vector2 = controls[mini(controls.size() - 1, span + 2)]
		for sample_index: int in range(SAMPLES_PER_SPAN):
			var amount: float = float(sample_index) / float(SAMPLES_PER_SPAN)
			var cell_point: Vector2 = start.cubic_interpolate(finish, before, after, amount)
			result.append(cell_point * _region.cell_size)
	result.append(controls.back() * _region.cell_size)
	return result


func _draw_projected_segments(canonical_points: PackedVector2Array, width: float) -> void:
	var current_segment := PackedVector2Array()
	var current_biome_index: int = 0
	for canonical_point: Vector2 in canonical_points:
		var sample: TerrainSample = _query.sample_at(canonical_point)
		var is_road_surface: bool = sample.valid and (
			sample.surface == TerrainChunkData.Surface.PATH
			or sample.surface == TerrainChunkData.Surface.RAMP
		) and (
			not _active_filter_configured
			or _active_chunk_coords.has(sample.chunk_coord)
		)
		if not is_road_surface:
			_draw_segment(current_segment, width, current_biome_index)
			current_segment = PackedVector2Array()
			continue
		if current_segment.is_empty():
			current_biome_index = sample.biome_index
		current_segment.append(canonical_point + Vector2.UP * sample.elevation_pixels)
	_draw_segment(current_segment, width, current_biome_index)


func _draw_segment(points: PackedVector2Array, width: float, biome_index: int) -> void:
	if points.size() < 2:
		return
	var biome: TerrainBiomeDefinition = _get_biome(biome_index)
	var edge_color: Color = biome.path_color.darkened(0.28)
	var path_color: Color = biome.path_color
	draw_polyline(points, edge_color, width + 18.0, true)
	draw_circle(points[0], (width + 18.0) * 0.5, edge_color)
	draw_circle(points[points.size() - 1], (width + 18.0) * 0.5, edge_color)
	draw_polyline(points, path_color, width, true)
	draw_circle(points[0], width * 0.5, path_color)
	draw_circle(points[points.size() - 1], width * 0.5, path_color)
	draw_polyline(points, Color(0.96, 0.87, 0.58, 0.28), maxf(3.0, width * 0.045), true)


func _get_biome(index: int) -> TerrainBiomeDefinition:
	if index >= 0 and index < _region.biomes.size() and _region.biomes[index] != null:
		return _region.biomes[index]
	return _region.biomes[0]

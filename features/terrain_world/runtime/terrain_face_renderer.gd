class_name TerrainFaceRenderer
extends Node2D

const CLIFF_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_cliff_face_v2.png")

var _data: TerrainChunkData
var _region: TerrainRegionDefinition
var _query: TerrainQuery


func configure(
	data: TerrainChunkData,
	region: TerrainRegionDefinition,
	query: TerrainQuery
) -> void:
	_data = data
	_region = region
	_query = query
	queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()


func _draw() -> void:
	if _data == null or _region == null or _query == null:
		return
	var origin_cells: Vector2i = _data.chunk_coord * _data.chunk_size_cells
	for local_y: int in range(_data.chunk_size_cells.y):
		for local_x: int in range(_data.chunk_size_cells.x):
			var local_cell := Vector2i(local_x, local_y)
			var global_cell: Vector2i = origin_cells + local_cell
			_draw_south_face(local_cell, global_cell)
			_draw_east_face(local_cell, global_cell)


func _draw_south_face(local_cell: Vector2i, global_cell: Vector2i) -> void:
	var current: TerrainSample = _query.sample_cell(global_cell)
	var south: TerrainSample = _query.sample_cell(global_cell + Vector2i.DOWN)
	var south_level: float = south.elevation_level if south.valid else 0.0
	var level_delta: float = current.elevation_level - south_level
	var is_stair_riser: bool = current.surface == TerrainChunkData.Surface.STAIR and level_delta > 0.01
	if is_stair_riser and _region.hide_stair_geometry_under_authored_art:
		return
	if not current.valid or (not is_stair_riser and level_delta <= TerrainQuery.MAX_OPEN_ELEVATION_DELTA):
		return
	var cell_size: float = _data.cell_size
	var top_y: float = (float(local_cell.y) + 1.0) * cell_size - current.elevation_pixels
	var height: float = level_delta * _data.elevation_step_pixels
	var face := Rect2(Vector2(float(local_cell.x) * cell_size, top_y), Vector2(cell_size + 0.75, height))
	var biome: TerrainBiomeDefinition = _get_biome(current.biome_index)
	if is_stair_riser:
		draw_rect(face, Color("666b5d"))
		draw_line(face.position, Vector2(face.end.x, face.position.y), Color("c3c1a6"), 2.0)
		return
	draw_rect(face, biome.cliff_color)
	draw_texture_rect_region(
		CLIFF_TEXTURE,
		face,
		Rect2(Vector2(global_cell) * 64.0, Vector2(face.size.x * 1.4, face.size.y * 3.2)),
		Color(0.75, 0.78, 0.66, 0.78)
	)
	draw_line(face.position, Vector2(face.end.x, face.position.y), biome.detail_color, 2.0)
	draw_line(Vector2(face.position.x, face.end.y), face.end, biome.cliff_color.darkened(0.34), 3.0)


func _draw_east_face(local_cell: Vector2i, global_cell: Vector2i) -> void:
	var current: TerrainSample = _query.sample_cell(global_cell)
	var east: TerrainSample = _query.sample_cell(global_cell + Vector2i.RIGHT)
	if (
		_region.hide_stair_geometry_under_authored_art
		and (
			current.surface == TerrainChunkData.Surface.STAIR
			or (east.valid and east.surface == TerrainChunkData.Surface.STAIR)
		)
	):
		return
	var east_level: float = east.elevation_level if east.valid else 0.0
	var level_delta: float = current.elevation_level - east_level
	if not current.valid or level_delta <= TerrainQuery.MAX_OPEN_ELEVATION_DELTA:
		return
	var cell_size: float = _data.cell_size
	var x: float = (float(local_cell.x) + 1.0) * cell_size
	var y: float = float(local_cell.y) * cell_size - current.elevation_pixels
	var drop: float = level_delta * _data.elevation_step_pixels
	var depth: float = minf(10.0, cell_size * 0.2)
	var face := PackedVector2Array([
		Vector2(x, y),
		Vector2(x, y + cell_size),
		Vector2(x + depth, y + cell_size + drop),
		Vector2(x + depth, y + drop),
	])
	var biome: TerrainBiomeDefinition = _get_biome(current.biome_index)
	draw_colored_polygon(face, biome.cliff_color.darkened(0.18))
	draw_polyline(PackedVector2Array([face[0], face[1], face[2]]), biome.cliff_color.lightened(0.08), 2.0)


func _get_biome(index: int) -> TerrainBiomeDefinition:
	if index >= 0 and index < _region.biomes.size() and _region.biomes[index] != null:
		return _region.biomes[index]
	return _region.biomes[0]

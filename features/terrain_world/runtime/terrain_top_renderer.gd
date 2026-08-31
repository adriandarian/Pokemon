class_name TerrainTopRenderer
extends Node2D

const GRASS_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_grass_top_v3.png")
const WATER_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_water.png")

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
	var cell_size: float = _data.cell_size
	var chunk_origin_cells: Vector2i = _data.chunk_coord * _data.chunk_size_cells
	for local_y: int in range(_data.chunk_size_cells.y):
		for local_x: int in range(_data.chunk_size_cells.x):
			var local_cell := Vector2i(local_x, local_y)
			var global_cell: Vector2i = chunk_origin_cells + local_cell
			var elevation: float = _data.get_elevation(local_cell)
			var elevation_pixels: float = elevation * _data.elevation_step_pixels
			var destination := Rect2(
				Vector2(float(local_x) * cell_size, float(local_y) * cell_size - elevation_pixels),
				Vector2.ONE * (cell_size + 0.75)
			)
			_draw_cell(global_cell, local_cell, destination)
	_draw_elevation_lips(chunk_origin_cells)


func _draw_cell(global_cell: Vector2i, local_cell: Vector2i, destination: Rect2) -> void:
	var surface: int = _data.get_surface(local_cell)
	var biome: TerrainBiomeDefinition = _get_biome(_data.get_biome_index(local_cell))
	match surface:
		TerrainChunkData.Surface.WATER:
			draw_rect(destination, Color("1f574f"))
			_draw_material_region(WATER_TEXTURE, destination, global_cell, Color(0.52, 0.82, 0.82, 0.78))
		TerrainChunkData.Surface.PATH:
			draw_rect(destination, biome.top_color)
			_draw_material_region(GRASS_TEXTURE, destination, global_cell, Color(0.62, 0.72, 0.38, 0.48))
		TerrainChunkData.Surface.STONE:
			_draw_stone_cell(destination, global_cell)
		TerrainChunkData.Surface.BRIDGE:
			if _region.hide_stair_geometry_under_authored_art:
				draw_rect(destination, Color("1f574f"))
				_draw_material_region(WATER_TEXTURE, destination, global_cell, Color(0.52, 0.82, 0.82, 0.78))
			else:
				_draw_bridge_cell(destination, global_cell)
		TerrainChunkData.Surface.STAIR:
			if _region.hide_stair_geometry_under_authored_art:
				# Traversal remains stair topology, while the active authored crossing
				# supplies the visible masonry. Keeping the connector bed grassy avoids
				# a second generic slab showing around the fitted stair asset.
				draw_rect(destination, biome.top_color)
				_draw_material_region(GRASS_TEXTURE, destination, global_cell, Color(0.58, 0.67, 0.31, 0.58))
			else:
				_draw_stair_cell(destination, biome.path_color)
		TerrainChunkData.Surface.RAMP:
			draw_rect(destination, biome.top_color)
			_draw_material_region(GRASS_TEXTURE, destination, global_cell, Color(0.82, 0.91, 0.76, 0.46))
		_:
			draw_rect(destination, biome.top_color)
			_draw_material_region(GRASS_TEXTURE, destination, global_cell, Color(0.58, 0.67, 0.31, 0.58))


func _draw_material_region(
	texture: Texture2D,
	destination: Rect2,
	global_cell: Vector2i,
	modulate: Color
) -> void:
	# Sample one continuous material field at a calmer scale than the logical
	# terrain cells. Cell boundaries must not become a visible editor grid.
	var source_scale: float = 0.62
	var source := Rect2(
		Vector2(global_cell) * _data.cell_size * source_scale,
		destination.size * source_scale
	)
	draw_texture_rect_region(texture, destination, source, modulate)


func _draw_stone_cell(destination: Rect2, global_cell: Vector2i) -> void:
	var base := Color("85866f")
	draw_rect(destination, base)
	var stone_hash: int = posmod(global_cell.x * 29 + global_cell.y * 17, 6)
	if stone_hash == 0:
		var joint_color := Color(0.35, 0.38, 0.32, 0.38)
		draw_line(
			destination.position + Vector2(6.0, destination.size.y * 0.63),
			destination.position + Vector2(destination.size.x - 5.0, destination.size.y * 0.63),
			joint_color,
			2.0
		)
	elif stone_hash == 3:
		draw_rect(destination.grow(-9.0), Color(0.78, 0.8, 0.66, 0.2), false, 2.0)


func _draw_bridge_cell(destination: Rect2, global_cell: Vector2i) -> void:
	var plank_color := Color("a96f3f") if posmod(global_cell.x, 2) == 0 else Color("bd8048")
	draw_rect(destination, plank_color)
	for offset: int in range(8, int(destination.size.x), 12):
		draw_line(
			destination.position + Vector2(float(offset), 2.0),
			destination.position + Vector2(float(offset), destination.size.y - 2.0),
			Color("64452f"),
			2.0
		)


func _draw_stair_cell(destination: Rect2, color: Color) -> void:
	draw_rect(destination, Color("878675"))
	draw_line(
		Vector2(destination.position.x, destination.end.y - 2.0),
		destination.end - Vector2(0.0, 2.0),
		Color("4e5147"),
		4.0
	)
	draw_line(
		destination.position + Vector2(0.0, 3.0),
		Vector2(destination.end.x, destination.position.y + 3.0),
		color.lightened(0.16),
		2.0
	)


func _draw_elevation_lips(chunk_origin_cells: Vector2i) -> void:
	var cell_size: float = _data.cell_size
	for local_y: int in range(_data.chunk_size_cells.y):
		for local_x: int in range(_data.chunk_size_cells.x):
			var local_cell := Vector2i(local_x, local_y)
			var global_cell: Vector2i = chunk_origin_cells + local_cell
			var sample: TerrainSample = _query.sample_cell(global_cell)
			if not sample.valid:
				continue
			var top_left := Vector2(float(local_x) * cell_size, float(local_y) * cell_size - sample.elevation_pixels)
			var south: TerrainSample = _query.sample_cell(global_cell + Vector2i.DOWN)
			if not south.valid or sample.elevation_level > south.elevation_level + TerrainQuery.MAX_OPEN_ELEVATION_DELTA:
				var lip_y: float = top_left.y + cell_size
				draw_line(Vector2(top_left.x, lip_y), Vector2(top_left.x + cell_size, lip_y), Color(0.77, 0.85, 0.58, 0.72), 2.0)
			var east: TerrainSample = _query.sample_cell(global_cell + Vector2i.RIGHT)
			if not east.valid or sample.elevation_level > east.elevation_level + TerrainQuery.MAX_OPEN_ELEVATION_DELTA:
				var edge_x: float = top_left.x + cell_size
				draw_line(Vector2(edge_x, top_left.y), Vector2(edge_x, top_left.y + cell_size), Color(0.28, 0.37, 0.27, 0.55), 2.0)


func _get_biome(index: int) -> TerrainBiomeDefinition:
	if index >= 0 and index < _region.biomes.size() and _region.biomes[index] != null:
		return _region.biomes[index]
	return _region.biomes[0]

class_name TerrainChunk
extends Node2D

const COLLISION_THICKNESS: float = 8.0

var data: TerrainChunkData
var region: TerrainRegionDefinition
var query: TerrainQuery
var _static_body: StaticBody2D


func configure(
	chunk_data: TerrainChunkData,
	region_definition: TerrainRegionDefinition,
	terrain_query: TerrainQuery
) -> void:
	data = chunk_data
	region = region_definition
	query = terrain_query
	position = Vector2(data.chunk_coord * data.chunk_size_cells) * data.cell_size


func _ready() -> void:
	if data == null or region == null or query == null or not data.has_valid_array_sizes():
		push_error("TerrainChunk cannot build without valid data, region, and query.")
		return
	_build_renderers()
	_build_collision()


func get_collision_shape_count() -> int:
	return _static_body.get_child_count() if _static_body != null else 0


func _build_renderers() -> void:
	var top_renderer := TerrainTopRenderer.new()
	top_renderer.name = "TopRenderer"
	top_renderer.z_index = 0
	top_renderer.configure(data, region, query)
	add_child(top_renderer)

	var face_renderer := TerrainFaceRenderer.new()
	face_renderer.name = "FaceRenderer"
	face_renderer.z_index = 5
	face_renderer.configure(data, region, query)
	add_child(face_renderer)


func _build_collision() -> void:
	_static_body = StaticBody2D.new()
	_static_body.name = "TerrainCollision"
	_static_body.collision_layer = 2
	_static_body.collision_mask = 0
	add_child(_static_body)

	var horizontal_edges: Array[Vector2i] = []
	var vertical_edges: Array[Vector2i] = []
	var origin_cells: Vector2i = data.chunk_coord * data.chunk_size_cells
	for local_y: int in range(data.chunk_size_cells.y):
		for local_x: int in range(data.chunk_size_cells.x):
			var global_cell: Vector2i = origin_cells + Vector2i(local_x, local_y)
			if data.chunk_coord.x == 0 and local_x == 0 and query.is_edge_blocked(global_cell, global_cell + Vector2i.LEFT):
				vertical_edges.append(Vector2i(global_cell.x, global_cell.y))
			if data.chunk_coord.y == 0 and local_y == 0 and query.is_edge_blocked(global_cell, global_cell + Vector2i.UP):
				horizontal_edges.append(Vector2i(global_cell.x, global_cell.y))
			if query.is_edge_blocked(global_cell, global_cell + Vector2i.RIGHT):
				vertical_edges.append(Vector2i(global_cell.x + 1, global_cell.y))
			if query.is_edge_blocked(global_cell, global_cell + Vector2i.DOWN):
				horizontal_edges.append(Vector2i(global_cell.x, global_cell.y + 1))
	_add_merged_horizontal_shapes(horizontal_edges, origin_cells)
	_add_merged_vertical_shapes(vertical_edges, origin_cells)


func _add_merged_horizontal_shapes(edges: Array[Vector2i], origin_cells: Vector2i) -> void:
	edges.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	var cursor: int = 0
	while cursor < edges.size():
		var start: Vector2i = edges[cursor]
		var length: int = 1
		while (
			cursor + length < edges.size()
			and edges[cursor + length].y == start.y
			and edges[cursor + length].x == start.x + length
		):
			length += 1
		var size := Vector2(float(length) * data.cell_size, COLLISION_THICKNESS)
		var center_global := Vector2(
			(float(start.x) + float(length) * 0.5) * data.cell_size,
			float(start.y) * data.cell_size
		)
		_add_rectangle_shape(center_global - Vector2(origin_cells) * data.cell_size, size)
		cursor += length


func _add_merged_vertical_shapes(edges: Array[Vector2i], origin_cells: Vector2i) -> void:
	edges.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)
	var cursor: int = 0
	while cursor < edges.size():
		var start: Vector2i = edges[cursor]
		var length: int = 1
		while (
			cursor + length < edges.size()
			and edges[cursor + length].x == start.x
			and edges[cursor + length].y == start.y + length
		):
			length += 1
		var size := Vector2(COLLISION_THICKNESS, float(length) * data.cell_size)
		var center_global := Vector2(
			float(start.x) * data.cell_size,
			(float(start.y) + float(length) * 0.5) * data.cell_size
		)
		_add_rectangle_shape(center_global - Vector2(origin_cells) * data.cell_size, size)
		cursor += length


func _add_rectangle_shape(local_center: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision.position = local_center
	collision.shape = rectangle
	_static_body.add_child(collision)


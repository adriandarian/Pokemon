class_name TerrainChunkData
extends Resource

enum Surface {
	GRASS,
	PATH,
	WATER,
	STONE,
	BRIDGE,
	STAIR,
	RAMP,
}

const FLAG_WALKABLE: int = 1
const FLAG_CONNECTOR: int = 2
const FLAG_PROTECTED: int = 4

@export var compiler_version: int = 1
@export var region_id: StringName
@export var chunk_coord: Vector2i
@export var chunk_size_cells: Vector2i = Vector2i(32, 32)
@export var cell_size: float = 48.0
@export var elevation_step_pixels: float = 48.0
@export var elevations: PackedFloat32Array
@export var surface_ids: PackedByteArray
@export var biome_indices: PackedByteArray
@export var traversal_flags: PackedByteArray


func get_cell_count() -> int:
	return chunk_size_cells.x * chunk_size_cells.y


func has_valid_array_sizes() -> bool:
	var expected: int = get_cell_count()
	return (
		elevations.size() == expected
		and surface_ids.size() == expected
		and biome_indices.size() == expected
		and traversal_flags.size() == expected
	)


func contains_local_cell(local_cell: Vector2i) -> bool:
	return (
		local_cell.x >= 0
		and local_cell.y >= 0
		and local_cell.x < chunk_size_cells.x
		and local_cell.y < chunk_size_cells.y
	)


func get_cell_index(local_cell: Vector2i) -> int:
	if not contains_local_cell(local_cell):
		return -1
	return local_cell.y * chunk_size_cells.x + local_cell.x


func get_elevation(local_cell: Vector2i) -> float:
	var index: int = get_cell_index(local_cell)
	return elevations[index] if index >= 0 and index < elevations.size() else 0.0


func get_surface(local_cell: Vector2i) -> int:
	var index: int = get_cell_index(local_cell)
	return int(surface_ids[index]) if index >= 0 and index < surface_ids.size() else Surface.WATER


func get_biome_index(local_cell: Vector2i) -> int:
	var index: int = get_cell_index(local_cell)
	return int(biome_indices[index]) if index >= 0 and index < biome_indices.size() else 0


func get_flags(local_cell: Vector2i) -> int:
	var index: int = get_cell_index(local_cell)
	return int(traversal_flags[index]) if index >= 0 and index < traversal_flags.size() else 0


func is_walkable(local_cell: Vector2i) -> bool:
	return (get_flags(local_cell) & FLAG_WALKABLE) != 0


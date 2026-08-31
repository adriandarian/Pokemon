class_name TerrainSample
extends RefCounted

var valid: bool = false
var world_position: Vector2 = Vector2.ZERO
var cell: Vector2i = Vector2i.ZERO
var chunk_coord: Vector2i = Vector2i.ZERO
var local_cell: Vector2i = Vector2i.ZERO
var elevation_level: float = 0.0
var elevation_pixels: float = 0.0
var surface: int = TerrainChunkData.Surface.WATER
var biome_index: int = 0
var traversal_flags: int = 0


func is_walkable() -> bool:
	return valid and (traversal_flags & TerrainChunkData.FLAG_WALKABLE) != 0


class_name TerrainRegionDefinition
extends Resource

@export var region_id: StringName = &"terrain_region"
@export var compiler_version: int = 1
@export var seed: int = 1

@export_group("Grid")
@export var chunk_count: Vector2i = Vector2i(2, 2)
@export var chunk_size_cells: Vector2i = Vector2i(32, 32)
@export_range(16.0, 128.0, 1.0) var cell_size: float = 48.0
@export_range(16.0, 128.0, 1.0) var elevation_step_pixels: float = 48.0
@export var hide_stair_geometry_under_authored_art: bool = false

@export_group("Proposal")
@export_range(0.001, 0.25, 0.001) var elevation_frequency: float = 0.034
@export_range(0.001, 0.25, 0.001) var moisture_frequency: float = 0.047
@export_range(-1.0, 1.0, 0.01) var raised_ground_threshold: float = 0.48

@export_group("Authored data")
@export var biomes: Array[TerrainBiomeDefinition] = []
@export var stamps: Array[TerrainStampDefinition] = []
@export var required_route_points: Array[Vector2i] = []


func get_total_size_cells() -> Vector2i:
	return chunk_count * chunk_size_cells


func get_world_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(get_total_size_cells()) * cell_size)

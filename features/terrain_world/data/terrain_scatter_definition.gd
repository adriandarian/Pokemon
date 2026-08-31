class_name TerrainScatterDefinition
extends Resource

@export var scatter_id: StringName
@export var visual_id: StringName
@export var allowed_biome_ids: Array[StringName] = []
@export_range(1, 256, 1) var attempts_per_chunk: int = 24
@export_range(0, 64, 1) var max_instances_per_chunk: int = 6
@export_range(0.0, 16.0, 0.25) var min_spacing_cells: float = 5.0
@export_range(0, 6, 1) var surface_clearance_cells: int = 1
@export_range(0.0, 8.0, 0.25) var chunk_margin_cells: float = 1.5
@export var seed_offset: int = 0


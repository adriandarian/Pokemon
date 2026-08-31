class_name TerrainStampDefinition
extends Resource

enum Kind {
	ELEVATION,
	BIOME,
	ROAD,
	WATER,
	PARCEL,
	STAIR,
	RAMP,
	BRIDGE,
}

enum Axis {
	X,
	Y,
}

@export var stamp_id: StringName
@export var kind: Kind = Kind.ELEVATION
@export var bounds: Rect2i
@export var target_elevation: float = 0.0
@export var start_elevation: float = 0.0
@export var end_elevation: float = 1.0
@export_enum("X", "Y") var axis: int = Axis.X
@export var biome_index: int = -1
@export var path_points: Array[Vector2] = []


func contains_cell(cell: Vector2i) -> bool:
	return bounds.has_point(cell)

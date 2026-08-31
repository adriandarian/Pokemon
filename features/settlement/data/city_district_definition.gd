class_name CityDistrictDefinition
extends Resource

@export var district_id: StringName
@export var display_name: String = "District"
@export_file("*.tscn") var scene_path: String
@export var map_coordinate: Vector2i
@export var neighbor_ids: Array[StringName] = []
@export var entry_cell: Vector2i


func is_valid() -> bool:
	return district_id != &"" and not scene_path.is_empty() and ResourceLoader.exists(scene_path)


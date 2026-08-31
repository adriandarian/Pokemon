class_name CityDistrictGroup
extends Node2D

@export var district_id: StringName


func get_terrain_world() -> TerrainWorld:
	return get_node_or_null("TerrainWorld") as TerrainWorld


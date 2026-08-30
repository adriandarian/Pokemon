class_name CreatureSpecies
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var lore: String
@export var elements: Array[ElementDefinition] = []
@export var base_stats: CreatureStats
@export var learnset: Array[MoveDefinition] = []
@export_file("*.tscn") var overworld_scene_path: String
@export_file("*.tscn") var battle_scene_path: String


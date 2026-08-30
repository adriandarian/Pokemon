class_name CreatureInstance
extends Resource

const MOVE_LIMIT: int = 4

@export var instance_id: StringName
@export var species_id: StringName
@export var nickname: String
@export_range(1, 100, 1) var level: int = 1
@export_range(0, 9999999, 1) var experience: int = 0
@export_range(0, 9999, 1) var current_hp: int = 1
@export var known_move_ids: Array[StringName] = []


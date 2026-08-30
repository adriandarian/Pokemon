class_name PlayerProfile
extends Resource

@export var trainer_name: String = "Trailkeeper"
@export var party: Array[CreatureInstance] = []
@export var reserve: Array[CreatureInstance] = []
@export var badge_ids: Array[StringName] = []
@export var discovered_species_ids: Array[StringName] = []
@export var world_flags: Dictionary[StringName, bool] = {}
@export var inventory: Dictionary[StringName, int] = {}

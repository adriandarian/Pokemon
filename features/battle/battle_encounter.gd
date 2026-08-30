class_name BattleEncounter
extends RefCounted

signal health_changed

var player_creature: CreatureInstance
var player_species: CreatureSpecies
var wild_species: CreatureSpecies
var wild_level: int
var player_hp: int
var wild_hp: int
var player_max_hp: int
var wild_max_hp: int


func _init(creature: CreatureInstance, species: CreatureSpecies, level: int) -> void:
	player_creature = creature
	player_species = ContentRegistry.get_species(creature.species_id)
	wild_species = species
	wild_level = clampi(level, 1, 100)
	player_max_hp = player_species.base_stats.max_hp
	wild_max_hp = wild_species.base_stats.max_hp + wild_level
	player_hp = clampi(creature.current_hp, 1, player_max_hp)
	wild_hp = wild_max_hp


func damage_wild(amount: int) -> int:
	var applied: int = mini(maxi(amount, 0), wild_hp)
	wild_hp -= applied
	health_changed.emit()
	return applied


func damage_player(amount: int) -> int:
	var applied: int = mini(maxi(amount, 0), player_hp)
	player_hp -= applied
	health_changed.emit()
	return applied


func get_capture_chance() -> float:
	var missing_ratio: float = 1.0 - (float(wild_hp) / float(maxi(wild_max_hp, 1)))
	return clampf(0.28 + missing_ratio * 0.68, 0.28, 0.96)


func commit_player_health() -> void:
	player_creature.current_hp = maxi(player_hp, 1)

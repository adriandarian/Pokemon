class_name CreatureStats
extends Resource

@export_group("Vitality")
@export_range(1, 999, 1) var max_hp: int = 10

@export_group("Physical")
@export_range(1, 255, 1) var attack: int = 5
@export_range(1, 255, 1) var defense: int = 5

@export_group("Elemental")
@export_range(1, 255, 1) var focus: int = 5
@export_range(1, 255, 1) var resistance: int = 5

@export_group("Tempo")
@export_range(1, 255, 1) var speed: int = 5


func is_valid() -> bool:
	return max_hp > 0 and attack > 0 and defense > 0 and focus > 0 and resistance > 0 and speed > 0


class_name BattleRules
extends RefCounted


static func calculate_damage(
	attacker: CreatureSpecies,
	attacker_level: int,
	move: MoveDefinition,
	defender: CreatureSpecies
) -> int:
	if attacker == null or defender == null or move == null:
		return 1
	var attack_stat: int = attacker.base_stats.attack if move.category == MoveDefinition.Category.PHYSICAL else attacker.base_stats.focus
	var defense_stat: int = defender.base_stats.defense if move.category == MoveDefinition.Category.PHYSICAL else defender.base_stats.resistance
	var level_factor: float = (2.0 * float(attacker_level) / 5.0) + 2.0
	var raw_damage: float = ((level_factor * float(maxi(move.power, 1)) * float(attack_stat) / float(maxi(defense_stat, 1))) / 50.0) + 2.0
	return maxi(1, roundi(raw_damage * _element_multiplier(move.element, defender)))


static func _element_multiplier(element: ElementDefinition, defender: CreatureSpecies) -> float:
	if element == null:
		return 1.0
	var multiplier: float = 1.0
	for defender_element: ElementDefinition in defender.elements:
		if element.strong_against.has(defender_element.id):
			multiplier *= 1.5
		elif element.weak_against.has(defender_element.id):
			multiplier *= 0.75
	return multiplier

extends Node

signal profile_changed

const PARTY_LIMIT: int = 6

var profile: PlayerProfile


func _ready() -> void:
	start_new_game("Trailkeeper")


func start_new_game(trainer_name: String = "Trailkeeper") -> void:
	profile = PlayerProfile.new()
	profile.trainer_name = trainer_name.strip_edges() if not trainer_name.strip_edges().is_empty() else "Trailkeeper"
	profile.inventory[&"trail_prism"] = 6
	profile.inventory[&"moss_tonic"] = 2
	profile_changed.emit()


func ensure_starter() -> CreatureInstance:
	if not profile.party.is_empty():
		return profile.party[0]
	return collect_creature(&"kindlehorn", 7)


func collect_creature(species_id: StringName, level: int = 5) -> CreatureInstance:
	var species: CreatureSpecies = ContentRegistry.get_species(species_id)
	if species == null:
		push_error("Cannot collect unknown creature species: %s" % species_id)
		return null

	var creature := CreatureInstance.new()
	creature.instance_id = _next_creature_id(species_id)
	creature.species_id = species.id
	creature.nickname = species.display_name
	creature.level = clampi(level, 1, 100)
	creature.current_hp = species.base_stats.max_hp
	for move: MoveDefinition in species.learnset:
		if creature.known_move_ids.size() >= CreatureInstance.MOVE_LIMIT:
			break
		creature.known_move_ids.append(move.id)

	if profile.party.size() < PARTY_LIMIT:
		profile.party.append(creature)
	else:
		profile.reserve.append(creature)

	if not profile.discovered_species_ids.has(species.id):
		profile.discovered_species_ids.append(species.id)

	EventHub.creature_collected.emit(creature)
	EventHub.party_changed.emit(profile.party.size(), profile.reserve.size())
	profile_changed.emit()
	return creature


func award_badge(badge_id: StringName) -> bool:
	if ContentRegistry.get_badge(badge_id) == null:
		push_error("Cannot award unknown badge: %s" % badge_id)
		return false
	if profile.badge_ids.has(badge_id):
		return false

	profile.badge_ids.append(badge_id)
	EventHub.badge_earned.emit(badge_id)
	profile_changed.emit()
	return true


func get_item_count(item_id: StringName) -> int:
	return profile.inventory.get(item_id, 0)


func add_item(item_id: StringName, quantity: int = 1) -> bool:
	var item: ItemDefinition = ContentRegistry.get_item(item_id)
	if item == null or quantity <= 0:
		return false
	var next_quantity: int = mini(get_item_count(item_id) + quantity, item.max_stack)
	profile.inventory[item_id] = next_quantity
	EventHub.inventory_changed.emit(item_id, next_quantity)
	profile_changed.emit()
	return true


func consume_item(item_id: StringName, quantity: int = 1) -> bool:
	var current: int = get_item_count(item_id)
	if quantity <= 0 or current < quantity:
		return false
	var next_quantity: int = current - quantity
	profile.inventory[item_id] = next_quantity
	EventHub.inventory_changed.emit(item_id, next_quantity)
	profile_changed.emit()
	return true


func get_summary() -> Dictionary:
	return {
		"trainer_name": profile.trainer_name,
		"party": profile.party.size(),
		"reserve": profile.reserve.size(),
		"badges": profile.badge_ids.size(),
		"discovered": profile.discovered_species_ids.size(),
	}


func _next_creature_id(species_id: StringName) -> StringName:
	var ordinal: int = profile.party.size() + profile.reserve.size() + 1
	return StringName("%s_%04d" % [species_id, ordinal])

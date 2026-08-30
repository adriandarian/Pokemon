extends Node

@onready var _view: BootstrapView = %BootstrapView


func _ready() -> void:
	_view.sample_creature_requested.connect(_on_sample_creature_requested)
	_view.first_badge_requested.connect(_on_first_badge_requested)
	_view.reset_requested.connect(_on_reset_requested)
	GameSession.profile_changed.connect(_on_profile_changed)
	EventHub.creature_collected.connect(_on_creature_collected)
	EventHub.badge_earned.connect(_on_badge_earned)

	if ContentRegistry.is_valid():
		_view.set_status("Foundation online. The catalog and session services are ready.")
	else:
		_view.set_status("Content validation failed. Run the smoke test for details.", false)
	_view.refresh()


func _on_sample_creature_requested() -> void:
	var species: CreatureSpecies = _find_next_sample_species()
	if species == null:
		_view.set_status("No creature definitions are available.", false)
		return
	GameSession.collect_creature(species.id)


func _on_first_badge_requested() -> void:
	var badge: BadgeDefinition = ContentRegistry.get_first_badge()
	if badge == null:
		_view.set_status("No badge definitions are available.", false)
		return
	if not GameSession.award_badge(badge.id):
		_view.set_status("%s has already been earned." % badge.display_name, false)


func _on_reset_requested() -> void:
	GameSession.start_new_game("Trailkeeper")
	_view.set_status("Expedition reset. The authored catalog was left untouched.")


func _on_profile_changed() -> void:
	_view.refresh()


func _on_creature_collected(creature: CreatureInstance) -> void:
	var species: CreatureSpecies = ContentRegistry.get_species(creature.species_id)
	var display_name: String = species.display_name if species != null else String(creature.species_id)
	_view.set_status("%s joined the expedition at level %d." % [display_name, creature.level])


func _on_badge_earned(badge_id: StringName) -> void:
	var badge: BadgeDefinition = ContentRegistry.get_badge(badge_id)
	var display_name: String = badge.display_name if badge != null else String(badge_id)
	_view.set_status("Badge earned: %s." % display_name)


func _find_next_sample_species() -> CreatureSpecies:
	for species: CreatureSpecies in ContentRegistry.get_all_species():
		if not GameSession.profile.discovered_species_ids.has(species.id):
			return species
	return ContentRegistry.get_first_species()


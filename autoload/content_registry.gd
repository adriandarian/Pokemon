extends Node

@export var catalog: GameContentCatalog

var _elements: Dictionary[StringName, ElementDefinition] = {}
var _moves: Dictionary[StringName, MoveDefinition] = {}
var _species: Dictionary[StringName, CreatureSpecies] = {}
var _badges: Dictionary[StringName, BadgeDefinition] = {}
var _locations: Dictionary[StringName, LocationDefinition] = {}
var _items: Dictionary[StringName, ItemDefinition] = {}
var _validation_errors: Array[String] = []


func _ready() -> void:
	reindex()


func reindex() -> void:
	_elements.clear()
	_moves.clear()
	_species.clear()
	_badges.clear()
	_locations.clear()
	_items.clear()
	_validation_errors.clear()

	if catalog == null:
		_validation_errors.append("ContentRegistry requires a GameContentCatalog.")
		push_error(_validation_errors[0])
		return

	_index_resources(catalog.elements, _elements, &"element")
	_index_resources(catalog.moves, _moves, &"move")
	_index_resources(catalog.species, _species, &"species")
	_index_resources(catalog.badges, _badges, &"badge")
	_index_resources(catalog.locations, _locations, &"location")
	_index_resources(catalog.items, _items, &"item")
	_validate_references()

	for error: String in _validation_errors:
		push_error(error)


func get_element(id: StringName) -> ElementDefinition:
	return _elements.get(id) as ElementDefinition


func get_move(id: StringName) -> MoveDefinition:
	return _moves.get(id) as MoveDefinition


func get_species(id: StringName) -> CreatureSpecies:
	return _species.get(id) as CreatureSpecies


func get_badge(id: StringName) -> BadgeDefinition:
	return _badges.get(id) as BadgeDefinition


func get_location(id: StringName) -> LocationDefinition:
	return _locations.get(id) as LocationDefinition


func get_item(id: StringName) -> ItemDefinition:
	return _items.get(id) as ItemDefinition


func get_all_items() -> Array[ItemDefinition]:
	return catalog.items.duplicate()


func get_all_species() -> Array[CreatureSpecies]:
	return catalog.species.duplicate()


func get_first_species() -> CreatureSpecies:
	if catalog == null or catalog.species.is_empty():
		return null
	return catalog.species[0]


func get_first_badge() -> BadgeDefinition:
	if catalog == null or catalog.badges.is_empty():
		return null
	return catalog.badges[0]


func is_valid() -> bool:
	return catalog != null and _validation_errors.is_empty()


func get_validation_errors() -> Array[String]:
	return _validation_errors.duplicate()


func get_summary() -> Dictionary:
	return {
		"elements": _elements.size(),
		"moves": _moves.size(),
		"species": _species.size(),
		"badges": _badges.size(),
		"locations": _locations.size(),
		"items": _items.size(),
		"valid": is_valid(),
	}


func _index_resources(resources: Array, destination: Dictionary, kind: StringName) -> void:
	for resource: Resource in resources:
		if resource == null:
			_validation_errors.append("The %s catalog contains a null resource." % kind)
			continue

		var id: StringName = resource.get("id") as StringName
		if id.is_empty():
			_validation_errors.append("A %s definition has an empty id." % kind)
			continue
		if destination.has(id):
			_validation_errors.append("Duplicate %s id: %s" % [kind, id])
			continue
		destination[id] = resource


func _validate_references() -> void:
	for element: ElementDefinition in catalog.elements:
		if element == null:
			continue
		for related_id: StringName in element.strong_against + element.weak_against:
			if not _elements.has(related_id):
				_validation_errors.append(
					"Element %s references unknown element %s." % [element.id, related_id]
				)

	for move: MoveDefinition in catalog.moves:
		if move == null:
			continue
		if move.element == null or not _elements.has(move.element.id):
			_validation_errors.append("Move %s has an unknown element." % move.id)

	for species: CreatureSpecies in catalog.species:
		if species == null:
			continue
		if species.base_stats == null or not species.base_stats.is_valid():
			_validation_errors.append("Species %s has invalid base stats." % species.id)
		if species.elements.is_empty():
			_validation_errors.append("Species %s must have at least one element." % species.id)
		for element: ElementDefinition in species.elements:
			if element == null or not _elements.has(element.id):
				_validation_errors.append("Species %s references an unknown element." % species.id)
		for move: MoveDefinition in species.learnset:
			if move == null or not _moves.has(move.id):
				_validation_errors.append("Species %s references an unknown move." % species.id)

	for badge: BadgeDefinition in catalog.badges:
		if badge != null and badge.element != null and not _elements.has(badge.element.id):
			_validation_errors.append("Badge %s references an unknown element." % badge.id)

	for location: LocationDefinition in catalog.locations:
		if location == null:
			continue
		for badge_id: StringName in location.required_badge_ids:
			if not _badges.has(badge_id):
				_validation_errors.append(
					"Location %s requires unknown badge %s." % [location.id, badge_id]
				)

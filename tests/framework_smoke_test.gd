extends Node

var _failures: Array[String] = []


func _ready() -> void:
	_expect(ContentRegistry.is_valid(), "The content registry is valid.")
	_expect(ContentRegistry.get_summary().get("elements", 0) == 4, "Four sample elements are indexed.")
	_expect(ContentRegistry.get_summary().get("species", 0) == 3, "Three sample species are indexed.")
	_expect(ContentRegistry.get_summary().get("items", 0) == 2, "Two starter inventory items are indexed.")
	_expect(ContentRegistry.get_location(&"mossglass_cave") != null, "A cave definition can be retrieved by id.")

	GameSession.start_new_game("Smoke Tester")
	var creature: CreatureInstance = GameSession.collect_creature(&"kindlehorn", 7)
	_expect(creature != null, "A creature instance can be created from authored species data.")
	_expect(GameSession.profile.party.size() == 1, "A collected creature enters the party.")
	_expect(creature != null and creature.known_move_ids.has(&"kindle_dash"), "The instance receives its authored starter move.")

	var badge_added: bool = GameSession.award_badge(&"ember_crest")
	_expect(badge_added, "A known badge can be awarded.")
	_expect(not GameSession.award_badge(&"ember_crest"), "A badge cannot be awarded twice.")

	if _failures.is_empty():
		print("FRAMEWORK_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error("FRAMEWORK_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

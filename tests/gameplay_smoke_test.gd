extends Node

const ADVENTURE_SCENE: PackedScene = preload("res://features/adventure/adventure.tscn")

var _failures: Array[String] = []


func _ready() -> void:
	GameSession.start_new_game("Gameplay Tester")
	var starter: CreatureInstance = GameSession.ensure_starter()
	_expect(starter != null, "A starter companion is available before exploration begins.")
	_expect(GameSession.profile.party.size() == 1, "The starter enters the active party.")
	_expect(GameSession.profile.discovered_species_ids.has(&"kindlehorn"), "The starter is recorded in the Creature Dex.")

	_expect(ContentRegistry.get_item(&"trail_prism") != null, "The capture tool is authored content.")
	_expect(
		AdventureWorldCanvas.get_trail_start().distance_to(RiverOverlay.PIER_LANDING_CENTER) < 0.1,
		"The village trail connects directly to the landward center of the pier."
	)
	_expect(
		VoxelWaterSurface.RIVER_POLYGON[0].y < 0.0
		and VoxelWaterSurface.RIVER_POLYGON[VoxelWaterSurface.RIVER_POLYGON.size() - 1].y > 1300.0,
		"The river extends beyond both vertical camera limits without a visible cap."
	)
	_expect(GameSession.get_item_count(&"trail_prism") == 6, "A new trailkeeper receives six capture tools.")
	_expect(GameSession.consume_item(&"trail_prism"), "A capture tool can be consumed through the session API.")
	_expect(GameSession.get_item_count(&"trail_prism") == 5, "Consuming an item updates the owned count.")
	_expect(GameSession.add_item(&"trail_prism"), "A known item can be added through the session API.")

	var wild_species: CreatureSpecies = ContentRegistry.get_species(&"rillip")
	var encounter := BattleEncounter.new(starter, wild_species, 5)
	var opening_chance: float = encounter.get_capture_chance()
	var move: MoveDefinition = ContentRegistry.get_move(&"kindle_dash")
	var damage: int = BattleRules.calculate_damage(ContentRegistry.get_species(starter.species_id), starter.level, move, wild_species)
	_expect(damage > 0, "Battle rules always resolve a positive damage value.")
	encounter.damage_wild(damage)
	_expect(encounter.wild_hp < encounter.wild_max_hp, "Wild battle health changes through its owning encounter.")
	_expect(encounter.get_capture_chance() > opening_chance, "Weakening a creature improves its capture chance.")

	var adventure: Node = ADVENTURE_SCENE.instantiate()
	add_child(adventure)
	await get_tree().process_frame
	var player: PlayerCharacter = adventure.get_node_or_null("Actors/Player") as PlayerCharacter
	var game_menu: GameMenu = adventure.get_node_or_null("Interface/GameMenu") as GameMenu
	var battle_overlay: BattleOverlay = adventure.get_node_or_null("Interface/BattleOverlay") as BattleOverlay
	_expect(player != null, "The adventure boots with a controllable CharacterBody2D player.")
	if player != null:
		var initial_visual: PlayerVisual = player.get_visual()
		_expect(initial_visual != null, "The player resolves its required visual child.")
		player.visual = null
		await get_tree().physics_frame
		await get_tree().physics_frame
		_expect(
			player.visual == initial_visual,
			"The player physics loop recovers its visual reference after an editor hot reload."
		)
	_expect(adventure.get_node("Actors/WildCreatures").get_child_count() == 3, "The authored wild preserve contains visible encounter creatures.")
	_expect(game_menu != null, "The Field Guide is present in the playable scene.")
	_expect(battle_overlay != null, "The 2D battle presentation is present in the playable scene.")

	game_menu.open(GameMenu.PAGE_DEX)
	_expect(game_menu.visible, "The Field Guide opens over exploration.")
	_expect((game_menu.get_node("Margin/Panel/MainVBox/Header/TitleLabel") as Label).text == "Creature Dex", "The Creature Dex page is connected to the menu shell.")
	game_menu.close()

	player.global_position = Vector2(1400.0, 690.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var location_label := adventure.get_node("Interface/AdventureHUD/TopMargin/TopRow/LocationCard/LocationVBox/Location") as Label
	_expect(location_label.text == "Mossglass Wilds", "Crossing into the preserve updates the location HUD.")

	var outcomes: Array[int] = []
	battle_overlay.battle_finished.connect(func(outcome: int) -> void: outcomes.append(outcome))
	_expect(battle_overlay.start_battle(&"rillip", 5), "A known visible species can start a battle.")
	_expect(battle_overlay.visible, "Starting a battle reveals the 2D combat presentation.")
	battle_overlay._on_run_pressed()
	await battle_overlay.battle_finished
	_expect(outcomes == [BattleOverlay.Result.RAN], "The Run command resolves and reports the correct battle outcome.")
	_expect(not battle_overlay.visible, "The battle presentation closes after its outcome resolves.")

	var party_before_capture: int = GameSession.profile.party.size()
	var prisms_before_capture: int = GameSession.get_item_count(&"trail_prism")
	_expect(battle_overlay.start_battle(&"rillip", 5), "A second encounter can begin after returning to exploration.")
	battle_overlay._encounter.damage_wild(999)
	battle_overlay._rng.seed = 1
	battle_overlay._on_capture_pressed()
	await battle_overlay.battle_finished
	_expect(outcomes.back() == BattleOverlay.Result.CAPTURED, "A weakened creature can be captured through the battle presentation.")
	_expect(GameSession.profile.party.size() == party_before_capture + 1, "A successful capture joins the active party.")
	_expect(GameSession.get_item_count(&"trail_prism") == prisms_before_capture - 1, "A capture attempt consumes one Trail Prism.")
	adventure.queue_free()

	if _failures.is_empty():
		print("GAMEPLAY_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("GAMEPLAY_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

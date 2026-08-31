extends Node

const ADVENTURE_SCENE: PackedScene = preload("res://features/adventure/adventure.tscn")
const HOMESTEAD_SETTLEMENT: SettlementDefinition = preload(
	"res://features/homestead_baseline/content/homestead_settlement.tres"
)

var _failures: Array[String] = []


func _ready() -> void:
	GameSession.start_new_game("Gameplay Tester")
	var starter: CreatureInstance = GameSession.ensure_starter()
	_expect(starter != null, "A starter companion is available before exploration begins.")
	_expect(GameSession.profile.party.size() == 1, "The starter enters the active party.")
	_expect(GameSession.profile.discovered_species_ids.has(&"kindlehorn"), "The starter is recorded in the Creature Dex.")

	_expect(ContentRegistry.get_item(&"trail_prism") != null, "The capture tool is authored content.")
	_expect(
		HOMESTEAD_SETTLEMENT.tier == SettlementDefinition.Tier.OUTPOST,
		"The starting homestead is authored as the pre-village settlement tier."
	)
	_expect(
		HOMESTEAD_SETTLEMENT.get_prop_count(AdventureProp.Kind.HOMESTEAD_COMPOUND) == 1
		and HOMESTEAD_SETTLEMENT.get_prop_count(AdventureProp.Kind.WHEAT_FIELD) == 1
		and HOMESTEAD_SETTLEMENT.get_prop_count(AdventureProp.Kind.RIVER_CROSSING) == 1
		and HOMESTEAD_SETTLEMENT.get_prop_count(AdventureProp.Kind.RIVER_STAIR) == 1,
		"The baseline definition contains one cottage compound, wheat field, stair, and bridge."
	)
	_expect(
		AdventureScale.HOUSE_HEIGHT_IN_HUMANS >= 3.5,
		"The lodge reads as architecture at more than three and a half human heights."
	)
	_expect(
		AdventureScale.SIGN_HEIGHT_IN_HUMANS < 0.8,
		"Wayfinding signs remain shorter than a person."
	)
	_expect(
		AdventureScale.LANTERN_HEIGHT_IN_HUMANS >= 1.7,
		"Hanging lanterns clear a person's head."
	)
	_expect(
		AdventureScale.EXPLORATION_CAMERA_ZOOM.x < 0.9,
		"Exploration is deliberately zoomed out for the corrected landmark scale."
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
	var terrain_world: TerrainWorld = adventure.get_node_or_null("WorldCanvas/TerrainWorld") as TerrainWorld
	var settlement_runtime: SettlementRuntime = adventure.get_node_or_null("SettlementRuntime") as SettlementRuntime
	var game_menu: GameMenu = adventure.get_node_or_null("Interface/GameMenu") as GameMenu
	var battle_overlay: BattleOverlay = adventure.get_node_or_null("Interface/BattleOverlay") as BattleOverlay
	_expect(player != null, "The adventure boots with a controllable CharacterBody2D player.")
	_expect(
		terrain_world != null and terrain_world.get_active_chunk_count() == 4,
		"The live adventure owns the complete four-chunk terrain district."
	)
	_expect(
		settlement_runtime != null and settlement_runtime.get_active_prop_count() == 4,
		"The four homestead landmarks materialize through the chunk-scoped settlement runtime."
	)
	_expect(
		adventure.get_node_or_null("WorldCollision") == null,
		"Compiled terrain topology replaces the obsolete hand-drawn world barriers."
	)
	if player != null:
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		_expect(
			camera != null and camera.zoom.is_equal_approx(AdventureScale.EXPLORATION_CAMERA_ZOOM),
			"The live exploration camera consumes the authoritative scale contract."
		)
		_expect(
			camera != null and camera.limit_right == 3072 and camera.limit_bottom == 3072,
			"The camera follows the expanded district bounds instead of the old one-screen map."
		)
		_expect(
			is_equal_approx(player.get_ground_elevation_pixels(), 80.0),
			"The player is visually projected onto the authored homestead terrace."
		)
		var initial_visual: PlayerVisual = player.get_visual()
		_expect(initial_visual != null, "The player resolves its required visual child.")
		player.visual = null
		await get_tree().physics_frame
		await get_tree().physics_frame
		_expect(
			player.visual == initial_visual,
			"The player physics loop recovers its visual reference after an editor hot reload."
		)
	_expect(adventure.get_node("Actors/WildCreatures").get_child_count() == 0, "The starting baseline does not render preserve encounters.")
	var homestead: AdventureProp
	var wheat_count: int = 0
	var old_building_count: int = 0
	for prop_node: Node in adventure.get_node("Actors/Props").get_children():
		if not prop_node is AdventureProp:
			continue
		var authored_prop := prop_node as AdventureProp
		match authored_prop.kind:
			AdventureProp.Kind.HOMESTEAD_COMPOUND:
				homestead = authored_prop
			AdventureProp.Kind.WHEAT_FIELD:
				wheat_count += 1
			AdventureProp.Kind.HOUSE, AdventureProp.Kind.COTTAGE, AdventureProp.Kind.MARKET_STALL, AdventureProp.Kind.CIVIC_HALL:
				old_building_count += 1
	_expect(homestead != null, "The authored baseline contains the Trailkeeper Homestead.")
	_expect(wheat_count == 1, "The upper terrace contains one dense wheat field.")
	_expect(old_building_count == 0, "The former village buildings are not part of the active render.")
	if terrain_world != null and settlement_runtime != null and player != null:
		terrain_world.enable_streaming(player, 0)
		player.global_position = terrain_world.get_query().cell_to_world_center(Vector2i(50, 50))
		await get_tree().physics_frame
		await get_tree().physics_frame
		_expect(
			settlement_runtime.get_active_prop_count() == 2,
			"Leaving the homestead chunk keeps only the destination stair and bridge landmarks active."
		)
		player.global_position = Vector2(1550.0, 1450.0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		_expect(
			settlement_runtime.get_active_prop_count() == 2,
			"Returning to the homestead chunk restores its two northern landmark definitions."
		)
		terrain_world.enable_streaming(player, 1)
	if homestead != null:
		var homestead_collision: CollisionShape2D
		for homestead_child: Node in homestead.get_children():
			if homestead_child is CollisionShape2D:
				homestead_collision = homestead_child as CollisionShape2D
				break
		var homestead_shape := homestead_collision.shape as RectangleShape2D if homestead_collision != null else null
		_expect(
			homestead_shape != null and homestead_shape.size.is_equal_approx(AdventureScale.HOMESTEAD_FOOTPRINT),
			"The compound uses a footprint-matched collision instead of a generic platform."
		)
	_expect(game_menu != null, "The Field Guide is present in the playable scene.")
	_expect(battle_overlay != null, "The 2D battle presentation is present in the playable scene.")

	game_menu.open(GameMenu.PAGE_DEX)
	_expect(game_menu.visible, "The Field Guide opens over exploration.")
	_expect((game_menu.get_node("Margin/Panel/MainVBox/Header/TitleLabel") as Label).text == "Creature Dex", "The Creature Dex page is connected to the menu shell.")
	game_menu.close()

	player.global_position = Vector2(2000.0, 800.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var location_label := adventure.get_node("Interface/AdventureHUD/TopMargin/TopRow/LocationCard/LocationVBox/Location") as Label
	_expect(location_label.text == "Highfield Terrace", "Climbing toward the wheat updates the location HUD.")

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

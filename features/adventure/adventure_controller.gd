class_name AdventureController
extends Node

const HOMESTEAD_SETTLEMENT: SettlementDefinition = preload(
	"res://features/homestead_baseline/content/homestead_settlement.tres"
)
const PLAYER_START_POSITION := Vector2(1320.0, 1580.0)

@onready var player: PlayerCharacter = %Player
@onready var props: Node2D = %Props
@onready var wild_creatures: Node2D = %WildCreatures
@onready var hud: AdventureHUD = %AdventureHUD
@onready var game_menu: GameMenu = %GameMenu
@onready var battle_overlay: BattleOverlay = %BattleOverlay
@onready var ambient_wind: AmbientWind = %AmbientWind
@onready var terrain_world: TerrainWorld = %TerrainWorld
@onready var settlement_runtime: SettlementRuntime = %SettlementRuntime

var _nearby_target: Node2D
var _active_wild_creature: WildCreatureActor
var _interaction_targets: Array[Node2D] = []
var _wild_targets: Array[WildCreatureActor] = []
var _current_area: StringName


func _ready() -> void:
	GameSession.ensure_starter()
	player.set_world_bounds(terrain_world.get_world_bounds())
	terrain_world.enable_streaming(player, 1)
	terrain_world.attach_follower(player, true)
	settlement_runtime.prop_activated.connect(_on_settlement_prop_activated)
	settlement_runtime.prop_deactivated.connect(_on_settlement_prop_deactivated)
	settlement_runtime.configure(HOMESTEAD_SETTLEMENT, terrain_world, props, ambient_wind)
	var player_visual: PlayerVisual = player.get_visual()
	if player_visual != null:
		player_visual.set_wind_source(ambient_wind)
	_spawn_authored_world()
	player.interact_requested.connect(_on_interact_requested)
	game_menu.closed.connect(_on_menu_closed)
	battle_overlay.battle_finished.connect(_on_battle_finished)
	_apply_developer_preview()
	_update_area_hud()


func _process(_delta: float) -> void:
	_update_area_hud()
	if game_menu.visible or battle_overlay.visible or hud.is_dialogue_open():
		if _nearby_target != null:
			_nearby_target = null
			hud.set_context_prompt("")
		return
	var target: Node2D = _find_interaction_target(player.global_position, player.facing)
	if target == _nearby_target:
		return
	_nearby_target = target
	if target == null:
		hud.set_context_prompt("")
	elif target is WildCreatureActor:
		hud.set_context_prompt((target as WildCreatureActor).get_prompt())
	elif target is AdventureNpc:
		hud.set_context_prompt((target as AdventureNpc).get_prompt())
	elif target is AdventureProp:
		hud.set_context_prompt((target as AdventureProp).get_prompt())


func _unhandled_input(event: InputEvent) -> void:
	if battle_overlay.visible:
		return
	if hud.is_dialogue_open() and (event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_cancel")):
		hud.hide_dialogue()
		player.set_movement_enabled(true)
		get_viewport().set_input_as_handled()
		return
	if not game_menu.visible and (event.is_action_pressed(&"open_menu") or event.is_action_pressed(&"ui_cancel")):
		player.set_movement_enabled(false)
		game_menu.open()
		get_viewport().set_input_as_handled()


func _on_interact_requested(origin: Vector2, facing: Vector2) -> void:
	var target: Node2D = _find_interaction_target(origin, facing)
	if target is WildCreatureActor:
		_start_wild_battle(target as WildCreatureActor)
	elif target is AdventureNpc:
		var npc := target as AdventureNpc
		var interaction: Dictionary = npc.get_interaction()
		player.set_movement_enabled(false)
		hud.show_dialogue(interaction.get("title", "Trail Notes") as String, interaction.get("text", "") as String)
	elif target is AdventureProp:
		var prop := target as AdventureProp
		var interaction: Dictionary = prop.get_interaction()
		player.set_movement_enabled(false)
		hud.show_dialogue(interaction.get("title", "Trail Notes") as String, interaction.get("text", "") as String)


func _start_wild_battle(actor: WildCreatureActor) -> void:
	_active_wild_creature = actor
	player.set_movement_enabled(false)
	hud.set_context_prompt("")
	if not battle_overlay.start_battle(actor.species_id, actor.level):
		player.set_movement_enabled(true)


func _on_battle_finished(outcome: int) -> void:
	if outcome == BattleOverlay.Result.CAPTURED or outcome == BattleOverlay.Result.WILD_DEFEATED:
		if is_instance_valid(_active_wild_creature):
			_wild_targets.erase(_active_wild_creature)
			_active_wild_creature.queue_free()
	elif outcome == BattleOverlay.Result.PLAYER_DEFEATED:
		player.global_position = PLAYER_START_POSITION
	_active_wild_creature = null
	player.set_movement_enabled(true)


func _on_menu_closed() -> void:
	player.set_movement_enabled(true)


func _find_interaction_target(origin: Vector2, facing: Vector2) -> Node2D:
	var probe: Vector2 = origin + facing.normalized() * 46.0
	var best_target: Node2D
	var best_distance: float = 112.0
	for actor: WildCreatureActor in _wild_targets:
		if not is_instance_valid(actor):
			continue
		var distance: float = probe.distance_to(actor.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = actor
	for interaction_target: Node2D in _interaction_targets:
		if not is_instance_valid(interaction_target):
			continue
		var distance: float = probe.distance_to(interaction_target.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = interaction_target
	return best_target


func _update_area_hud() -> void:
	var next_area: StringName
	if player.global_position.y >= 2050.0:
		next_area = &"river_crossing"
	elif player.global_position.x >= 1800.0 and player.global_position.y <= 1000.0:
		next_area = &"wheat_terrace"
	else:
		next_area = &"starting_homestead"
	if next_area == _current_area:
		return
	_current_area = next_area
	if _current_area == &"river_crossing":
		hud.set_location("Mossglass Frontier", "Willowrun Crossing", "Cross the timber bridge to continue south.")
	elif _current_area == &"wheat_terrace":
		hud.set_location("Mossglass Frontier", "Highfield Terrace", "Ripe wheat overlooks the starting homestead.")
	else:
		hud.set_location("Mossglass Frontier", "Trailkeeper Homestead", "Follow the path from your cottage toward the river.")


func _spawn_authored_world() -> void:
	# The authored grove frames the reference composition while preserving the
	# northern trail, cottage yard, stair approach, bridge, and southern exit.
	var tree_positions: Array[Vector2] = [
		Vector2(210.0, 260.0), Vector2(560.0, 240.0), Vector2(1030.0, 210.0),
		Vector2(1450.0, 260.0), Vector2(2840.0, 250.0), Vector2(2600.0, 520.0),
		Vector2(360.0, 780.0), Vector2(780.0, 1010.0), Vector2(2750.0, 1120.0),
		Vector2(300.0, 1620.0), Vector2(650.0, 1830.0), Vector2(2540.0, 1760.0),
		Vector2(180.0, 2640.0), Vector2(620.0, 2860.0), Vector2(2600.0, 2700.0),
		Vector2(2910.0, 2970.0), Vector2(1180.0, 2860.0),
	]
	for tree_position: Vector2 in tree_positions:
		_spawn_prop(AdventureProp.Kind.TREE, tree_position)

	var rock_positions: Array[Vector2] = [
		Vector2(780.0, 420.0), Vector2(1040.0, 1150.0), Vector2(2500.0, 1300.0),
		Vector2(360.0, 2300.0), Vector2(2520.0, 2460.0), Vector2(1500.0, 2820.0),
	]
	for rock_position: Vector2 in rock_positions:
		_spawn_prop(AdventureProp.Kind.ROCK, rock_position)

	var shrub_positions: Array[Vector2] = [
		Vector2(320.0, 420.0), Vector2(920.0, 330.0), Vector2(1320.0, 500.0),
		Vector2(2680.0, 780.0), Vector2(520.0, 1160.0), Vector2(930.0, 1420.0),
		Vector2(2260.0, 1380.0), Vector2(2740.0, 1520.0), Vector2(460.0, 1900.0),
		Vector2(870.0, 1880.0), Vector2(2380.0, 1880.0), Vector2(2820.0, 1980.0),
		Vector2(290.0, 2580.0), Vector2(850.0, 2520.0), Vector2(1280.0, 2700.0),
		Vector2(1760.0, 2860.0), Vector2(2360.0, 2660.0), Vector2(2760.0, 2860.0),
	]
	for shrub_position: Vector2 in shrub_positions:
		_spawn_prop(AdventureProp.Kind.MEADOW_SHRUB, shrub_position)



func _spawn_prop(kind: AdventureProp.Kind, world_position: Vector2, title: String = "", text: String = "") -> AdventureProp:
	var prop := AdventureProp.new()
	prop.configure(kind, title, text)
	prop.position = world_position
	props.add_child(prop)
	prop.set_wind_source(ambient_wind)
	terrain_world.attach_follower(prop, false)
	if not text.is_empty():
		_interaction_targets.append(prop)
	return prop


func _on_settlement_prop_activated(prop: AdventureProp) -> void:
	if not prop.interaction_text.is_empty() and not _interaction_targets.has(prop):
		_interaction_targets.append(prop)


func _on_settlement_prop_deactivated(prop: AdventureProp) -> void:
	_interaction_targets.erase(prop)
	if _nearby_target == prop:
		_nearby_target = null
		hud.set_context_prompt("")


func _spawn_npc(world_position: Vector2, title: String, text: String) -> AdventureNpc:
	var npc := AdventureNpc.new()
	npc.configure(title, text)
	npc.position = world_position
	props.add_child(npc)
	npc.set_wind_source(ambient_wind)
	terrain_world.attach_follower(npc, true)
	_interaction_targets.append(npc)
	return npc


func _spawn_wild_creature(species_id: StringName, level: int, world_position: Vector2, roam_radius: float) -> WildCreatureActor:
	var actor := WildCreatureActor.new()
	actor.species_id = species_id
	actor.level = level
	actor.roam_radius = roam_radius
	actor.position = world_position
	wild_creatures.add_child(actor)
	terrain_world.attach_follower(actor, true)
	_wild_targets.append(actor)
	return actor


func _apply_developer_preview() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.has("--preview-profile"):
		GameSession.collect_creature(&"rillip", 5)
		GameSession.collect_creature(&"brambit", 6)
		GameSession.award_badge(&"ember_crest")
		GameSession.award_badge(&"deep_delver_mark")
		player.set_movement_enabled(false)
		game_menu.open(GameMenu.PAGE_PROFILE)
	elif arguments.has("--preview-dex"):
		GameSession.collect_creature(&"rillip", 5)
		GameSession.collect_creature(&"brambit", 6)
		player.set_movement_enabled(false)
		game_menu.open(GameMenu.PAGE_DEX)
	elif arguments.has("--preview-menu"):
		player.set_movement_enabled(false)
		game_menu.open()
	elif arguments.has("--preview-battle"):
		player.set_movement_enabled(false)
		battle_overlay.start_battle(&"rillip", 5)
	elif arguments.has("--preview-pier"):
		player.global_position = Vector2(480.0, 1030.0)
	elif arguments.has("--preview-river-north"):
		player.global_position = Vector2(430.0, 340.0)
	elif arguments.has("--preview-wild"):
		player.global_position = Vector2(1400.0, 690.0)
	elif arguments.has("--preview-terrain"):
		player.global_position = PLAYER_START_POSITION
		player.reset_physics_interpolation()
	elif arguments.has("--preview-south"):
		player.global_position = Vector2(1980.0, 2780.0)
		player.reset_physics_interpolation()
	elif arguments.has("--preview-homestead-overview"):
		player.global_position = Vector2(1536.0, 1590.0)
		player.set_movement_enabled(false)
		player.reset_physics_interpolation()
		var camera := player.get_node_or_null("Camera2D") as Camera2D
		if camera != null:
			camera.zoom = Vector2(0.65, 0.65)
			camera.position = Vector2(0.0, -40.0)
		var interface_layer := get_node_or_null("Interface") as CanvasLayer
		if interface_layer != null:
			interface_layer.visible = false

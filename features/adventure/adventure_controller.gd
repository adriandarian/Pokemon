class_name AdventureController
extends Node

@onready var player: PlayerCharacter = %Player
@onready var props: Node2D = %Props
@onready var wild_creatures: Node2D = %WildCreatures
@onready var hud: AdventureHUD = %AdventureHUD
@onready var game_menu: GameMenu = %GameMenu
@onready var battle_overlay: BattleOverlay = %BattleOverlay
@onready var ambient_wind: AmbientWind = %AmbientWind
@onready var shoreline_waves: ShorelineWaves = %ShorelineWaves
@onready var wind_grass: WindGrass = %WindGrass
@onready var wind_motes: WindMotes = %WindMotes

var _nearby_target: Node2D
var _active_wild_creature: WildCreatureActor
var _interaction_targets: Array[Node2D] = []
var _wild_targets: Array[WildCreatureActor] = []
var _current_area: StringName


func _ready() -> void:
	GameSession.ensure_starter()
	shoreline_waves.set_wind_source(ambient_wind)
	wind_grass.set_wind_source(ambient_wind)
	wind_motes.set_wind_source(ambient_wind)
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
		player.global_position = Vector2(650.0, 860.0)
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
	var next_area: StringName = &"mossglass_wilds" if player.global_position.x >= 1220.0 else &"windfall_village"
	if next_area == _current_area:
		return
	_current_area = next_area
	if _current_area == &"mossglass_wilds":
		hud.set_location("Mossglass Frontier", "Mossglass Wilds", "Approach a roaming creature and press E to battle.")
	else:
		hud.set_location("Mossglass Frontier", "Windfall Village", "Follow the east trail into the wild grass.")


func _spawn_authored_world() -> void:
	_spawn_prop(AdventureProp.Kind.HOUSE, Vector2(610.0, 620.0), "Trailkeeper Lodge", "Your lodge is warm, but the open trail is calling. The Field Guide in your bag tracks creatures, supplies, and badges.")
	_spawn_npc(Vector2(875.0, 675.0), "Ranger Sela", "Wild creatures are visible in the preserve now. Approach calmly, press E, weaken one in battle, then cast a Trail Prism.")
	_spawn_prop(AdventureProp.Kind.SIGN, Vector2(1055.0, 750.0), "East Trail", "Mossglass Wilds  →\nVisible creatures roam the long grass. Trail Prisms work best after a creature is weakened.")
	_spawn_prop(AdventureProp.Kind.SIGN, Vector2(1268.0, 670.0), "Preserve Boundary", "WILD AREA\nStay alert. A creature's element changes which moves hit hardest.")
	_spawn_prop(AdventureProp.Kind.LANTERN, Vector2(950.0, 820.0))
	_spawn_prop(AdventureProp.Kind.LANTERN, Vector2(1180.0, 785.0))

	var tree_positions: Array[Vector2] = [
		Vector2(390.0, 390.0), Vector2(515.0, 320.0), Vector2(805.0, 350.0),
		Vector2(995.0, 365.0), Vector2(1140.0, 430.0), Vector2(1110.0, 1030.0),
		Vector2(790.0, 1095.0), Vector2(470.0, 1210.0), Vector2(2040.0, 350.0),
		Vector2(2070.0, 610.0), Vector2(2015.0, 920.0),
	]
	for tree_position: Vector2 in tree_positions:
		_spawn_prop(AdventureProp.Kind.TREE, tree_position)

	var rock_positions: Array[Vector2] = [
		Vector2(1350.0, 300.0), Vector2(1830.0, 325.0), Vector2(1910.0, 825.0),
		Vector2(1430.0, 910.0), Vector2(1020.0, 1110.0),
	]
	for rock_position: Vector2 in rock_positions:
		_spawn_prop(AdventureProp.Kind.ROCK, rock_position)

	_spawn_wild_creature(&"rillip", 5, Vector2(1490.0, 610.0), 38.0)
	_spawn_wild_creature(&"brambit", 6, Vector2(1740.0, 760.0), 46.0)
	_spawn_wild_creature(&"rillip", 8, Vector2(1850.0, 465.0), 34.0)


func _spawn_prop(kind: AdventureProp.Kind, world_position: Vector2, title: String = "", text: String = "") -> AdventureProp:
	var prop := AdventureProp.new()
	prop.configure(kind, title, text)
	prop.position = world_position
	props.add_child(prop)
	prop.set_wind_source(ambient_wind)
	if not text.is_empty():
		_interaction_targets.append(prop)
	return prop


func _spawn_npc(world_position: Vector2, title: String, text: String) -> AdventureNpc:
	var npc := AdventureNpc.new()
	npc.configure(title, text)
	npc.position = world_position
	props.add_child(npc)
	npc.set_wind_source(ambient_wind)
	_interaction_targets.append(npc)
	return npc


func _spawn_wild_creature(species_id: StringName, level: int, world_position: Vector2, roam_radius: float) -> WildCreatureActor:
	var actor := WildCreatureActor.new()
	actor.species_id = species_id
	actor.level = level
	actor.roam_radius = roam_radius
	actor.position = world_position
	wild_creatures.add_child(actor)
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
	elif arguments.has("--preview-wild"):
		player.global_position = Vector2(1400.0, 690.0)

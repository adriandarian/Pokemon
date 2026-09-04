class_name HomesteadAdventure3D
extends Node3D

const MouseNavigationType = preload(
	"res://features/mouse_navigation/mouse_navigation_controller.gd"
)

@onready var world: HomesteadWorld3D = %World
@onready var player: HomesteadPlayer3D = %Player
@onready var camera_rig: Faux2DCameraRig = %CameraRig
@onready var navigation_region: NavigationRegion3D = %NavigationRegion3D
@onready var mouse_navigation: MouseNavigationType = %MouseNavigation
@onready var hud: AdventureHUD = %AdventureHUD
@onready var game_menu: GameMenu = %GameMenu
@onready var battle_overlay: BattleOverlay = %BattleOverlay

var _current_area: StringName


func _ready() -> void:
	GameSession.ensure_starter()
	player.teleport_to(world.get_spawn_position())
	camera_rig.target = player
	camera_rig.set_overview_enabled(false)
	mouse_navigation.configure(camera_rig, player, navigation_region)
	mouse_navigation.interaction_requested.connect(_on_mouse_interaction_requested)
	player.interact_requested.connect(mouse_navigation.request_directional_interaction)
	world.water_entered.connect(_on_water_entered)
	game_menu.closed.connect(_on_menu_closed)
	battle_overlay.battle_finished.connect(_on_battle_finished)
	_apply_developer_preview()
	_update_area_hud()


func _process(_delta: float) -> void:
	_update_area_hud()


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


func _update_area_hud() -> void:
	var next_area: StringName
	if player.global_position.z >= 9.0:
		next_area = &"river_crossing"
	elif player.global_position.y >= 6.2:
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


func _on_water_entered(body: Node3D) -> void:
	if body != player:
		return
	player.teleport_to(player.last_safe_position)


func _on_menu_closed() -> void:
	player.set_movement_enabled(true)


func _on_mouse_interaction_requested(interactable: Node3D) -> void:
	if not is_instance_valid(interactable) or not interactable.has_method(&"get_interaction"):
		return
	var interaction: Dictionary = interactable.call(&"get_interaction") as Dictionary
	player.set_movement_enabled(false)
	hud.show_dialogue(
		interaction.get("title", "Trail Notes") as String,
		interaction.get("text", "") as String
	)


func _on_battle_finished(outcome: int) -> void:
	if outcome == BattleOverlay.Result.PLAYER_DEFEATED:
		player.teleport_to(world.get_spawn_position())
	player.set_movement_enabled(true)


func _apply_developer_preview() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.has("--preview-profile"):
		GameSession.collect_creature(&"rillip", 5)
		GameSession.collect_creature(&"brambit", 6)
		player.set_movement_enabled(false)
		game_menu.open(GameMenu.PAGE_PROFILE)
	elif arguments.has("--preview-dex"):
		GameSession.collect_creature(&"rillip", 5)
		player.set_movement_enabled(false)
		game_menu.open(GameMenu.PAGE_DEX)
	elif arguments.has("--preview-menu"):
		player.set_movement_enabled(false)
		game_menu.open()
	elif arguments.has("--preview-battle"):
		player.set_movement_enabled(false)
		battle_overlay.start_battle(&"rillip", 5)
	elif arguments.has("--preview-stairs"):
		player.teleport_to(world.get_route_endpoint(&"stair_top") + Vector3(0.0, 0.05, -1.2))
	elif arguments.has("--preview-bridge"):
		player.teleport_to(world.get_route_endpoint(&"bridge_north") + Vector3(0.0, 0.05, -1.2))
	elif arguments.has("--preview-south"):
		player.teleport_to(Vector3(3.0, 0.08, 28.0))
	elif arguments.has("--preview-homestead-orbit"):
		player.set_movement_enabled(false)
		camera_rig.set_overview_enabled(true)
		camera_rig.set_preview_orbit_degrees(-38.0, 46.0)
		_hide_preview_interface()
	elif arguments.has("--preview-homestead-overview"):
		player.set_movement_enabled(false)
		camera_rig.set_overview_enabled(true)
		_hide_preview_interface()


func _hide_preview_interface() -> void:
	var interface_layer := get_node_or_null("Interface") as CanvasLayer
	if interface_layer != null:
		interface_layer.visible = false

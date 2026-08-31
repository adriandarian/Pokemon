extends Node

const ADVENTURE_SCENE: PackedScene = preload("res://features/adventure/adventure.tscn")
const HumanAtlas = preload("res://features/world_animation/human_animation_atlas.gd")
const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")

var _failures: Array[String] = []


func _ready() -> void:
	var sprint_events: Array[InputEvent] = InputMap.action_get_events(&"sprint")
	_expect(not sprint_events.is_empty(), "The run action is present in the Input Map.")
	if not sprint_events.is_empty():
		_expect(sprint_events[0].as_text().contains("Shift"), "The run action is bound to Shift.")
	_expect(VoxelAssets.get_player_animation_texture(false).get_width() <= 512, "The explorer atlas respects the runtime import budget.")
	_expect(VoxelAssets.get_ranger_animation_texture().get_width() <= 512, "The Ranger atlas respects the runtime import budget.")

	var player_frames: SpriteFrames = HumanAtlas.create_player_frames()
	_expect(player_frames.has_animation(&"front_idle"), "The explorer has a front-facing idle clip.")
	_expect(player_frames.has_animation(&"front_walk"), "The explorer has a front-facing walk clip.")
	_expect(player_frames.has_animation(&"front_run"), "The explorer has a front-facing run clip.")
	_expect(player_frames.has_animation(&"back_idle"), "The explorer has a rear-facing idle clip.")
	_expect(player_frames.has_animation(&"back_walk"), "The explorer has a rear-facing walk clip.")
	_expect(player_frames.has_animation(&"back_run"), "The explorer has a rear-facing run clip.")
	_expect(player_frames.get_frame_count(&"front_idle") == 5, "The explorer idle clip includes blink and smile frames.")
	_expect(player_frames.get_frame_count(&"front_walk") == 4, "The explorer walk loop has a passing-frame return.")
	_expect(player_frames.get_frame_count(&"front_run") == 4, "The explorer run loop has a passing-frame return.")

	var ranger_frames: SpriteFrames = HumanAtlas.create_ranger_frames()
	_expect(ranger_frames.has_animation(&"idle"), "Ranger Sela has an idle expression clip.")
	_expect(ranger_frames.has_animation(&"walk"), "Ranger Sela has a walk clip.")
	_expect(ranger_frames.has_animation(&"run"), "Ranger Sela has a run clip.")

	GameSession.start_new_game("Animation Tester")
	var adventure: Node = ADVENTURE_SCENE.instantiate()
	add_child(adventure)
	await get_tree().process_frame

	var wind: AmbientWind = adventure.get_node_or_null("AmbientWind") as AmbientWind
	var shoreline: ShorelineWaves = adventure.get_node_or_null("WorldCanvas/ShorelineWaves") as ShorelineWaves
	var grass: WindGrass = adventure.get_node_or_null("WorldCanvas/WindGrass") as WindGrass
	var motes: WindMotes = adventure.get_node_or_null("WorldCanvas/WindMotes") as WindMotes
	_expect(wind != null, "The adventure has one authoritative ambient wind owner.")
	_expect(shoreline != null, "The animated shoreline layer is present.")
	_expect(grass != null, "The wind-driven grass layer is present.")
	_expect(motes != null, "The wind-mote layer is present.")

	var player: PlayerCharacter = adventure.get_node("Actors/Player") as PlayerCharacter
	var player_sprite: AnimatedSprite2D = player.visual.get_node("AnimatedSprite2D") as AnimatedSprite2D
	player.visual.set_motion(Vector2.RIGHT, 80.0, false)
	_expect(player.visual.get_current_animation_name() == &"front_walk", "Walking selects the explorer front walk clip.")
	_expect(player_sprite.flip_h, "Moving right mirrors the atlas's native left-facing pose.")
	player.visual.set_motion(Vector2.LEFT, 80.0, false)
	_expect(not player_sprite.flip_h, "Moving left uses the atlas's native left-facing pose.")
	player.visual.set_motion(Vector2.RIGHT, 220.0, true)
	_expect(player.visual.get_current_animation_name() == &"front_run", "Running selects the explorer front run clip.")
	player.visual.set_motion(Vector2.UP, 220.0, true)
	_expect(player.visual.get_current_animation_name() == &"back_run", "Moving north selects the rear run clip.")
	player.visual.set_motion(Vector2.DOWN, 0.0, false)
	_expect(player.visual.get_current_animation_name() == &"front_idle", "Stopping returns the explorer to its expression idle clip.")

	var npc: AdventureNpc
	var lantern_flame_count: int = 0
	var props: Node = adventure.get_node("Actors/Props")
	for child: Node in props.get_children():
		if child is AdventureNpc:
			npc = child as AdventureNpc
		elif child is AdventureProp and (child as AdventureProp).kind == AdventureProp.Kind.LANTERN:
			var flame := child.get_node_or_null("LanternFlame") as LanternFlame
			if flame != null:
				lantern_flame_count += 1
				_expect(
					flame.position.is_equal_approx(AdventureScale.LANTERN_FLAME_POSITION),
					"A lantern flame scales with the hanging fixture instead of detaching."
				)
				_expect(
					flame.scale.is_equal_approx(AdventureScale.LANTERN_FLAME_SCALE),
					"Lantern flame volume follows the authoritative prop scale."
				)
	_expect(npc != null, "Ranger Sela is a dedicated moving NPC actor.")
	_expect(lantern_flame_count == 2, "Both authored lanterns own a wind-driven flame visual.")
	if npc != null:
		var npc_sprite: AnimatedSprite2D = npc.get_visual().get_node("AnimatedSprite2D") as AnimatedSprite2D
		npc.get_visual().set_motion(Vector2.RIGHT, 40.0, false)
		_expect(npc.get_locomotion_state_name() == &"walk", "Ranger velocity selects the walk clip.")
		_expect(npc_sprite.flip_h, "A right-moving Ranger mirrors the atlas's native left-facing pose.")
		npc.get_visual().set_motion(Vector2.LEFT, 40.0, false)
		_expect(not npc_sprite.flip_h, "A left-moving Ranger uses the atlas's native left-facing pose.")
		npc.get_visual().set_motion(Vector2.RIGHT, 95.0, true)
		_expect(npc.get_locomotion_state_name() == &"run", "Ranger run intent selects the run clip.")
		npc.get_visual().set_motion(Vector2.ZERO, 0.0, false)
		_expect(npc.get_locomotion_state_name() == &"idle", "Ranger stopping returns to the facial idle clip.")

	if wind != null:
		var moving_time: float = wind.get_time()
		await get_tree().process_frame
		_expect(wind.get_time() > moving_time, "Ambient wind advances while motion is enabled.")
		SettingsService.set_reduced_motion(true)
		var frozen_time: float = wind.get_time()
		await get_tree().process_frame
		await get_tree().process_frame
		_expect(is_equal_approx(wind.get_time(), frozen_time), "Reduced motion freezes the shared wind phase.")
		_expect(not wind.is_processing(), "Reduced motion suspends wind updates.")
		_expect(grass == null or not grass.is_processing(), "Reduced motion suspends animated grass redraws.")
		_expect(shoreline == null or not shoreline.is_processing(), "Reduced motion suspends shoreline redraws.")
		SettingsService.set_reduced_motion(false)

	adventure.queue_free()
	if _failures.is_empty():
		print("WORLD_ANIMATION_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("WORLD_ANIMATION_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

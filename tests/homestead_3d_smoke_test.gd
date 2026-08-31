extends Node

const HOMESTEAD_SCENE: PackedScene = preload(
	"res://features/homestead_3d/homestead_adventure_3d.tscn"
)

var _failures: Array[String] = []


func _ready() -> void:
	GameSession.start_new_game("3D Homestead Tester")
	var adventure := HOMESTEAD_SCENE.instantiate() as HomesteadAdventure3D
	add_child(adventure)
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	var world := adventure.get_node_or_null("World") as HomesteadWorld3D
	var player := adventure.get_node_or_null("Player") as HomesteadPlayer3D
	var camera := adventure.get_node_or_null("CameraRig/Camera3D") as Camera3D
	_expect(adventure is Node3D, "The active homestead exploration root is a Node3D.")
	_expect(world != null, "The active homestead owns its 3D world boundary.")
	_expect(player != null, "The player is a CharacterBody3D controller.")
	_expect(camera != null and camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "The 3D exploration camera uses the locked orthographic presentation.")
	_expect(adventure.get_node_or_null("WorldCanvas") == null, "The active 3D render does not mount the retired 2D WorldCanvas.")
	_expect(ProjectSettings.get_setting("application/run/main_scene") == "res://features/homestead_3d/homestead_adventure_3d.tscn", "The project boots directly into the 3D homestead baseline.")

	if world != null:
		_expect(world.get_route_endpoint(&"north_trail_end").is_equal_approx(world.get_route_endpoint(&"stair_top")), "The north trail terminates exactly at the stair top.")
		_expect(world.get_route_endpoint(&"stair_bottom").is_equal_approx(world.get_route_endpoint(&"lower_trail_start")), "The stair bottom and lower trail share one endpoint.")
		_expect(world.get_route_endpoint(&"lower_trail_end").is_equal_approx(world.get_route_endpoint(&"bridge_north")), "The lower trail and bridge share one north endpoint.")
		_expect(world.get_route_endpoint(&"bridge_south").is_equal_approx(world.get_route_endpoint(&"south_trail_start")), "The bridge and southern trail share one south endpoint.")
		_expect(world.get_stair_slope_degrees() < 50.0, "The smooth 3D stair ramp stays within the player floor-angle limit.")
		var summary: Dictionary = world.get_physics_summary()
		_expect(summary.get("static_bodies", 0) >= 30, "Terrain, bridge, buildings, trees, rocks, and fences own StaticBody3D collision.")
		_expect(summary.get("collision_shapes", 0) >= 30, "The baseline materializes real CollisionShape3D resources.")
		_expect(summary.get("areas", 0) == 2, "Two water hazard areas leave one physical bridge corridor.")
		_expect(summary.get("trail_ribbons", 0) == 3, "The route uses three fitted 3D ribbons around the stair and bridge geometry.")
		_expect(summary.get("landmarks", 0) == 4, "The compound, wheat, stair, and bridge remain the four authored landmarks.")
		var space_state: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
		_expect(_has_world_floor(space_state, world.get_spawn_position()), "The spawn path has a physical 3D floor.")
		_expect(_has_world_floor(space_state, (world.get_route_endpoint(&"stair_top") + world.get_route_endpoint(&"stair_bottom")) * 0.5), "The visible stair is backed by its smooth physical ramp.")
		_expect(_has_world_floor(space_state, (world.get_route_endpoint(&"bridge_north") + world.get_route_endpoint(&"bridge_south")) * 0.5), "The timber bridge owns a physical 3D deck.")
		_expect(not _has_world_floor(space_state, Vector3(-8.0, 0.5, 13.0)), "Open river water has no walkable world floor.")

	if player != null:
		var collision := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var sprite := player.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
		_expect(collision != null and collision.shape is CapsuleShape3D, "The 3D player uses a capsule collision shape.")
		_expect(player.scale.is_equal_approx(Vector3.ONE), "The CharacterBody3D is not scaled.")
		_expect(collision == null or collision.scale.is_equal_approx(Vector3.ONE), "The 3D collision shape is not scaled.")
		_expect(sprite != null and sprite.sprite_frames.has_animation(&"front_idle"), "The 3D player uses the authored animated front-facing atlas.")
		_expect(sprite != null and sprite.sprite_frames.has_animation(&"back_run"), "The 3D player can animate away from camera while running.")
		_expect(player.global_position.distance_to(world.get_spawn_position()) < 0.25, "The player starts on the cottage path in 3D space.")

	var menu := adventure.get_node_or_null("Interface/GameMenu") as GameMenu
	var battle := adventure.get_node_or_null("Interface/BattleOverlay") as BattleOverlay
	_expect(menu != null, "The existing Field Guide remains over the 3D world.")
	_expect(battle != null, "The deliberately flat 2D battle overlay remains available.")
	if menu != null:
		menu.open(GameMenu.PAGE_DEX)
		_expect(menu.visible, "The Field Guide still opens over 3D exploration.")
		menu.close()

	adventure.queue_free()
	if _failures.is_empty():
		print("HOMESTEAD_3D_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("HOMESTEAD_3D_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _has_world_floor(space_state: PhysicsDirectSpaceState3D, point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		point + Vector3.UP * 4.0,
		point + Vector3.DOWN * 5.0,
		2
	)
	query.collide_with_areas = false
	return not space_state.intersect_ray(query).is_empty()

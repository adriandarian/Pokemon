extends Node

const HOMESTEAD_SCENE: PackedScene = preload(
	"res://features/homestead_3d/homestead_adventure_3d.tscn"
)
const MouseNavigationType = preload(
	"res://features/mouse_navigation/mouse_navigation_controller.gd"
)

const NAVIGATION_WAIT_FRAMES: int = 600

var _failures: Array[String] = []


func _ready() -> void:
	GameSession.start_new_game("Mouse Navigation Tester")
	var adventure := HOMESTEAD_SCENE.instantiate() as HomesteadAdventure3D
	add_child(adventure)
	await get_tree().process_frame
	await get_tree().physics_frame

	var world := adventure.get_node_or_null("World") as HomesteadWorld3D
	var player := adventure.get_node_or_null("Player") as HomesteadPlayer3D
	var camera_rig := adventure.get_node_or_null("CameraRig") as Faux2DCameraRig
	var camera := adventure.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var navigation_region := adventure.get_node_or_null("NavigationRegion3D") as NavigationRegion3D
	var mouse_navigation: MouseNavigationType = adventure.get_node_or_null("MouseNavigation")

	_expect(mouse_navigation != null, "The homestead mounts the mouse navigation input boundary.")
	_expect(navigation_region != null, "The homestead owns a NavigationRegion3D.")
	_expect(player != null and player.get_node_or_null("NavigationAgent3D") is NavigationAgent3D, "The player owns its NavigationAgent3D movement state.")

	if mouse_navigation != null:
		var waited_frames: int = 0
		while not mouse_navigation.is_navigation_ready() and waited_frames < NAVIGATION_WAIT_FRAMES:
			await get_tree().physics_frame
			waited_frames += 1
		_expect(mouse_navigation.is_navigation_ready(), "Runtime navigation baking completes and synchronizes with the map.")

	if navigation_region != null and navigation_region.navigation_mesh != null:
		_expect(navigation_region.navigation_mesh.get_polygon_count() > 0, "The runtime bake produces walkable navigation polygons.")

	if mouse_navigation != null and world != null:
		var bridge_path: PackedVector3Array = mouse_navigation.trace_path_to(
			world.get_route_endpoint(&"bridge_south")
		)
		_expect(bridge_path.size() >= 2, "Path tracing finds a route from the homestead through the stair and bridge.")
		var stair_link := world.find_child(
			"SteepStairNavigationLink",
			true,
			false
		) as NavigationLink3D
		var path_reaches_link_top: bool = false
		var path_reaches_link_bottom: bool = false
		if stair_link != null:
			for path_point: Vector3 in bridge_path:
				path_reaches_link_top = path_reaches_link_top or path_point.distance_to(
					stair_link.global_position + stair_link.start_position
				) < 1.0
				path_reaches_link_bottom = path_reaches_link_bottom or path_point.distance_to(
					stair_link.global_position + stair_link.end_position
				) < 1.0
		_expect(
			stair_link != null
			and path_reaches_link_top
			and path_reaches_link_bottom,
			"The click-to-move route crosses the dedicated bidirectional stair link: %s"
			% [bridge_path]
		)
		if camera != null and player != null:
			var clicked_ground: Vector3 = world.get_spawn_position() + Vector3(1.5, 0.0, 1.5)
			var ground_screen_position: Vector2 = camera.unproject_position(clicked_ground)
			_expect(mouse_navigation.request_move_at_screen(ground_screen_position), "A screen-space right click ray resolves to walkable world collision.")
			_expect(player.is_navigating(), "A right-click ground ray starts click-to-move on the player owner.")
			mouse_navigation.cancel_pending_action()

	if camera_rig != null and camera != null:
		var initial_size: float = camera.size
		camera_rig.zoom_by_steps(1.0)
		_expect(camera.size < initial_size, "A wheel-up step zooms the orthographic camera in.")
		camera_rig.zoom_by_steps(100.0)
		_expect(is_equal_approx(camera.size, camera_rig.min_gameplay_size), "Zoom-in clamps at the authored minimum size.")
		camera_rig.zoom_by_steps(-100.0)
		_expect(is_equal_approx(camera.size, camera_rig.max_gameplay_size), "Zoom-out clamps at the authored maximum size.")
		var angles_before: Vector2 = camera_rig.get_orbit_angles()
		camera_rig.orbit_by(Vector2(24.0, -10000.0))
		var angles_after: Vector2 = camera_rig.get_orbit_angles()
		_expect(not is_equal_approx(angles_before.x, angles_after.x), "Right-drag deltas change the stored camera yaw.")
		_expect(angles_after.y <= deg_to_rad(camera_rig.max_pitch_degrees) + 0.001, "Camera pitch clamps at the faux-2.5D upper limit.")

	if mouse_navigation != null:
		_expect(not mouse_navigation.is_orbit_gesture(mouse_navigation.orbit_drag_threshold), "A stationary right click remains a walk gesture.")
		_expect(mouse_navigation.is_orbit_gesture(mouse_navigation.orbit_drag_threshold + 0.1), "Mouse travel beyond the threshold becomes an orbit gesture.")

	var interactables: Array[Node] = get_tree().get_nodes_in_group(&"mouse_interactable")
	_expect(not interactables.is_empty(), "The homestead exposes at least one object through the generic interactable contract.")
	if not interactables.is_empty() and mouse_navigation != null and player != null and world != null:
		var interactable := interactables.front() as Node3D
		var completed_targets: Array[Node3D] = []
		mouse_navigation.interaction_requested.connect(
			func(target: Node3D) -> void: completed_targets.append(target)
		)
		var approach_position: Vector3 = interactable.call(
			&"get_interaction_position",
			player.global_position
		) as Vector3
		player.teleport_to(world.get_spawn_position())
		var clicked_body := interactable.find_child("HouseFoundation", true, false) as StaticBody3D
		var click_started: bool = false
		if clicked_body != null and camera != null:
			click_started = mouse_navigation.request_interaction_at_screen(
				camera.unproject_position(clicked_body.global_position)
			)
		_expect(click_started, "A screen-space left click resolves an interactable object through its collider ancestry.")
		_expect(mouse_navigation.has_pending_interaction(), "A distant left-click target remains pending during auto-approach.")
		_expect(player.is_navigating(), "A distant interaction asks the player owner to follow a path.")
		var approach_frames: int = 0
		while completed_targets.is_empty() and approach_frames < NAVIGATION_WAIT_FRAMES:
			await get_tree().physics_frame
			approach_frames += 1
		_expect(completed_targets.size() == 1, "Auto-pathing completes the requested interaction after reaching its approach point.")
		_expect(adventure.hud.is_dialogue_open(), "Auto-pathing presents the clicked object's dialogue on arrival.")
		adventure.hud.hide_dialogue()
		player.set_movement_enabled(true)

		completed_targets.clear()
		player.teleport_to(world.get_spawn_position())
		mouse_navigation.request_interaction_target(interactable)
		player.cancel_navigation()
		_expect(not mouse_navigation.has_pending_interaction(), "Cancelling player navigation also cancels its pending interaction intent.")

		player.teleport_to(approach_position)
		mouse_navigation.request_interaction_target(interactable)
		_expect(completed_targets.size() == 1, "An in-range left click interacts immediately.")
		_expect(adventure.hud.is_dialogue_open(), "The adventure owner presents the clicked object's dialogue.")

	adventure.queue_free()
	if _failures.is_empty():
		print("MOUSE_NAVIGATION_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("MOUSE_NAVIGATION_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

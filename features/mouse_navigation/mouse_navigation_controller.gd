class_name MouseNavigationController
extends Node

signal navigation_ready
signal interaction_requested(interactable: Node3D)

const GET_INTERACTION_METHOD := &"get_interaction"
const GET_INTERACTION_POSITION_METHOD := &"get_interaction_position"
const CAN_INTERACT_FROM_METHOD := &"can_interact_from"
const NAVIGATION_SYNC_TIMEOUT_FRAMES: int = 300

@export_range(2.0, 30.0, 0.5) var orbit_drag_threshold: float = 8.0
@export_range(25.0, 500.0, 5.0) var ray_length: float = 250.0
@export_flags_3d_physics var world_collision_mask: int = 2
@export_flags_3d_physics var interactable_collision_mask: int = 8

var input_enabled: bool = true
var _camera_rig: Faux2DCameraRig
var _camera: Camera3D
var _player: HomesteadPlayer3D
var _navigation_region: NavigationRegion3D
var _navigation_is_ready: bool = false
var _right_button_held: bool = false
var _right_drag_distance: float = 0.0
var _pending_interactable: Node3D
var _queued_destination: Vector3
var _has_queued_destination: bool = false


func _ready() -> void:
	set_physics_process(false)


func configure(
	camera_rig: Faux2DCameraRig,
	player: HomesteadPlayer3D,
	navigation_region: NavigationRegion3D
) -> void:
	_camera_rig = camera_rig
	_camera = camera_rig.get_camera()
	_player = player
	_navigation_region = navigation_region
	if not _player.navigation_finished.is_connected(_on_player_navigation_finished):
		_player.navigation_finished.connect(_on_player_navigation_finished)
	if not _player.navigation_cancelled.is_connected(_on_player_navigation_cancelled):
		_player.navigation_cancelled.connect(_on_player_navigation_cancelled)
	if not _player.manual_movement_started.is_connected(_on_manual_movement_started):
		_player.manual_movement_started.connect(_on_manual_movement_started)
	if not _navigation_region.bake_finished.is_connected(_on_navigation_bake_finished):
		_navigation_region.bake_finished.connect(_on_navigation_bake_finished)
	_navigation_is_ready = false
	_navigation_region.bake_navigation_mesh(true)


func _physics_process(_delta: float) -> void:
	if _pending_interactable == null:
		set_physics_process(false)
		return
	if not _player.movement_enabled:
		cancel_pending_action()
		return
	if not is_instance_valid(_pending_interactable):
		cancel_pending_action()
		return
	if _can_interact_with(_pending_interactable):
		_complete_pending_interaction()


func _unhandled_input(event: InputEvent) -> void:
	if not _can_accept_gameplay_input():
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_reset_right_gesture()
		return

	if event is InputEventMouseMotion and _right_button_held:
		_right_drag_distance += event.relative.length()
		if is_orbit_gesture(_right_drag_distance):
			_camera_rig.orbit_by(event.relative)
			get_viewport().set_input_as_handled()
		return

	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	match mouse_event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if mouse_event.pressed:
				_camera_rig.zoom_by_steps(maxf(mouse_event.factor, 1.0))
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_WHEEL_DOWN:
			if mouse_event.pressed:
				_camera_rig.zoom_by_steps(-maxf(mouse_event.factor, 1.0))
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_RIGHT:
			if mouse_event.pressed:
				_right_button_held = true
				_right_drag_distance = 0.0
			elif _right_button_held:
				var should_walk: bool = not is_orbit_gesture(_right_drag_distance)
				_reset_right_gesture()
				if should_walk:
					request_move_at_screen(mouse_event.position)
				get_viewport().set_input_as_handled()
		MOUSE_BUTTON_LEFT:
			if mouse_event.pressed and request_interaction_at_screen(mouse_event.position):
				get_viewport().set_input_as_handled()


func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled
	if not enabled:
		_reset_right_gesture()
		cancel_pending_action()


func is_navigation_ready() -> bool:
	return _navigation_is_ready


func is_orbit_gesture(accumulated_distance: float) -> bool:
	return accumulated_distance > orbit_drag_threshold


func request_move_at_screen(screen_position: Vector2) -> bool:
	var hit: Dictionary = _raycast_world(screen_position, world_collision_mask)
	if hit.is_empty():
		return false
	return request_move_to_world(hit.get("position", Vector3.ZERO) as Vector3)


func request_move_to_world(world_position: Vector3) -> bool:
	_clear_pending_interaction()
	if _player != null:
		_player.cancel_navigation()
	if not _navigation_is_ready:
		_queued_destination = world_position
		_has_queued_destination = true
		return true
	_has_queued_destination = false
	var projected_position: Vector3 = _project_to_navigation(world_position)
	return _player.navigate_to(projected_position)


func request_interaction_at_screen(screen_position: Vector2) -> bool:
	var hit: Dictionary = _raycast_world(
		screen_position,
		world_collision_mask | interactable_collision_mask
	)
	if hit.is_empty():
		return false
	var interactable: Node3D = _find_interactable(hit.get("collider"))
	if interactable == null:
		return false
	return request_interaction_target(interactable)


func request_interaction_target(interactable: Node3D) -> bool:
	if not _is_interactable(interactable):
		return false
	_player.cancel_navigation()
	_has_queued_destination = false
	_pending_interactable = interactable
	set_physics_process(true)
	if _can_interact_with(interactable):
		_complete_pending_interaction()
		return true
	if _navigation_is_ready:
		_start_pending_interaction_path()
	return true


func request_directional_interaction(origin: Vector3, facing: Vector3) -> void:
	var probe: Vector3 = origin + facing.normalized() * 1.2
	var best_target: Node3D
	var best_distance: float = INF
	for candidate_value: Node in get_tree().get_nodes_in_group(&"mouse_interactable"):
		var candidate := candidate_value as Node3D
		if not _is_interactable(candidate):
			continue
		var candidate_position: Vector3 = _get_interaction_position(candidate)
		var distance: float = probe.distance_to(candidate_position)
		if distance < best_distance and distance <= 3.0:
			best_target = candidate
			best_distance = distance
	if best_target != null:
		request_interaction_target(best_target)


func trace_path_to(world_position: Vector3) -> PackedVector3Array:
	if not _navigation_is_ready or _player == null:
		return PackedVector3Array()
	var navigation_map: RID = _player.get_navigation_map()
	if not navigation_map.is_valid():
		return PackedVector3Array()
	var path_start: Vector3 = NavigationServer3D.map_get_closest_point(
		navigation_map,
		_player.global_position
	)
	var path_end: Vector3 = NavigationServer3D.map_get_closest_point(
		navigation_map,
		world_position
	)
	return NavigationServer3D.map_get_path(navigation_map, path_start, path_end, true)


func has_pending_interaction() -> bool:
	return is_instance_valid(_pending_interactable)


func cancel_pending_action() -> void:
	_clear_pending_interaction()
	_has_queued_destination = false
	if _player != null:
		_player.cancel_navigation()


func _on_navigation_bake_finished() -> void:
	_synchronize_navigation_map()


func _synchronize_navigation_map() -> void:
	var waited_frames: int = 0
	while waited_frames < NAVIGATION_SYNC_TIMEOUT_FRAMES:
		await get_tree().physics_frame
		if not is_instance_valid(_navigation_region) or not is_instance_valid(_player):
			return
		var navigation_map: RID = _navigation_region.get_navigation_map()
		var closest_owner: RID = NavigationServer3D.map_get_closest_point_owner(
			navigation_map,
			_player.global_position
		)
		if closest_owner.is_valid():
			break
		waited_frames += 1
	if waited_frames >= NAVIGATION_SYNC_TIMEOUT_FRAMES:
		push_error("The homestead navigation map did not synchronize after its runtime bake.")
		return
	_navigation_is_ready = true
	navigation_ready.emit()
	if is_instance_valid(_pending_interactable):
		_start_pending_interaction_path()
	elif _has_queued_destination:
		var destination: Vector3 = _queued_destination
		_has_queued_destination = false
		request_move_to_world(destination)


func _on_player_navigation_finished(reached: bool) -> void:
	if not is_instance_valid(_pending_interactable):
		_clear_pending_interaction()
		return
	if _can_interact_with(_pending_interactable):
		_complete_pending_interaction()
	elif not reached:
		_clear_pending_interaction()


func _on_player_navigation_cancelled() -> void:
	_clear_pending_interaction()
	_has_queued_destination = false


func _on_manual_movement_started() -> void:
	_clear_pending_interaction()
	_has_queued_destination = false


func _start_pending_interaction_path() -> void:
	if not is_instance_valid(_pending_interactable):
		_clear_pending_interaction()
		return
	var approach_position: Vector3 = _get_interaction_position(_pending_interactable)
	_player.navigate_to(_project_to_navigation(approach_position))


func _complete_pending_interaction() -> void:
	if not is_instance_valid(_pending_interactable):
		_clear_pending_interaction()
		return
	var completed_target: Node3D = _pending_interactable
	_clear_pending_interaction()
	_player.cancel_navigation()
	interaction_requested.emit(completed_target)


func _project_to_navigation(world_position: Vector3) -> Vector3:
	var navigation_map: RID = _player.get_navigation_map()
	if not navigation_map.is_valid():
		return world_position
	return NavigationServer3D.map_get_closest_point(navigation_map, world_position)


func _raycast_world(screen_position: Vector2, collision_mask: int) -> Dictionary:
	if _camera == null:
		return {}
	var origin: Vector3 = _camera.project_ray_origin(screen_position)
	var destination: Vector3 = origin + _camera.project_ray_normal(screen_position) * ray_length
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		destination,
		collision_mask,
		[_player.get_rid()]
	)
	query.collide_with_areas = false
	return get_viewport().world_3d.direct_space_state.intersect_ray(query)


func _find_interactable(collider_value: Variant) -> Node3D:
	var current := collider_value as Node
	while current != null:
		if current is Node3D and _is_interactable(current as Node3D):
			return current as Node3D
		current = current.get_parent()
	return null


func _is_interactable(candidate: Node3D) -> bool:
	return candidate != null \
		and candidate.has_method(GET_INTERACTION_METHOD) \
		and candidate.has_method(GET_INTERACTION_POSITION_METHOD) \
		and candidate.has_method(CAN_INTERACT_FROM_METHOD)


func _get_interaction_position(interactable: Node3D) -> Vector3:
	var result: Variant = interactable.call(
		GET_INTERACTION_POSITION_METHOD,
		_player.global_position
	)
	return result as Vector3


func _can_interact_with(interactable: Node3D) -> bool:
	return interactable.call(CAN_INTERACT_FROM_METHOD, _player.global_position) as bool


func _can_accept_gameplay_input() -> bool:
	return input_enabled \
		and is_instance_valid(_camera_rig) \
		and is_instance_valid(_player) \
		and _player.movement_enabled


func _reset_right_gesture() -> void:
	_right_button_held = false
	_right_drag_distance = 0.0


func _clear_pending_interaction() -> void:
	_pending_interactable = null
	set_physics_process(false)

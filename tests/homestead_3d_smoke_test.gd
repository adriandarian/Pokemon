extends Node

const HOMESTEAD_SCENE: PackedScene = preload(
	"res://features/homestead_3d/homestead_adventure_3d.tscn"
)
const RiverShoreProfile: Script = preload(
	"res://features/homestead_3d/river_shore_profile_3d.gd"
)
const UpperPromontoryFront: Script = preload(
	"res://features/homestead_3d/upper_promontory_front_3d.gd"
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
		var bridge_root := world.find_child("TimberBridge", true, false) as Node3D
		_expect(bridge_root != null, "The authored route materializes one 3D timber bridge landmark.")
		if bridge_root != null:
			var bridge_north_endpoint: Vector3 = world.get_route_endpoint(&"bridge_north")
			var bridge_south_endpoint: Vector3 = world.get_route_endpoint(&"bridge_south")
			var bridge_vector: Vector3 = bridge_south_endpoint - bridge_north_endpoint
			var bridge_length: float = Vector2(bridge_vector.x, bridge_vector.z).length()
			_expect(
				bridge_root.position.is_equal_approx(
					(bridge_north_endpoint + bridge_south_endpoint) * 0.5
				)
				and is_equal_approx(
					bridge_root.rotation.y,
					atan2(bridge_vector.x, bridge_vector.z)
				),
				"The visual correction does not move the bridge endpoints or authored yaw."
			)
			var bridge_deck := bridge_root.get_node_or_null(
				"BridgeDeckCollision"
			) as StaticBody3D
			_expect(
				bridge_deck != null
					and not bridge_deck.visible
					and bridge_deck.position.is_equal_approx(Vector3(0.0, -0.16, 0.0))
					and bridge_deck.collision_layer == 2
					and bridge_deck.collision_mask == 1,
				"The hidden layer-2 bridge deck remains the sole physical crossing."
			)
			if bridge_deck != null:
				var deck_shapes: Array[Node] = bridge_deck.find_children(
					"*",
					"CollisionShape3D",
					false,
					false
				)
				var deck_shape := (
					(deck_shapes[0] as CollisionShape3D).shape as ConvexPolygonShape3D
					if deck_shapes.size() == 1
					else null
				)
				var expected_visual_offset := Vector3(-0.120460, 0.0, -0.1350954)
				var expected_cross_half_axis := Vector3(1.546228, 0.0, 0.3602544)
				var expected_run_half_axis := Vector3(
					0.0,
					0.0,
					bridge_length * 0.5 - 0.11
				)
				var expected_plank_corners: Array[Vector3] = [
					expected_visual_offset - expected_cross_half_axis - expected_run_half_axis,
					expected_visual_offset - expected_cross_half_axis + expected_run_half_axis,
					expected_visual_offset + expected_cross_half_axis + expected_run_half_axis,
					expected_visual_offset + expected_cross_half_axis - expected_run_half_axis,
				]
				var expected_connector_corners: Array[Vector3] = []
				for connector_side: float in [-1.0, 1.0]:
					var connector_center := Vector3(
						0.0,
						0.0,
						connector_side * (bridge_length * 0.5 - 0.14)
					)
					expected_connector_corners.append(
						connector_center - Vector3(1.1, 0.0, 0.14)
					)
					expected_connector_corners.append(
						connector_center - Vector3(1.1, 0.0, -0.14)
					)
					expected_connector_corners.append(
						connector_center + Vector3(1.1, 0.0, 0.14)
					)
					expected_connector_corners.append(
						connector_center + Vector3(1.1, 0.0, -0.14)
					)
				var expected_deck_footprint: Array[Vector3] = []
				expected_deck_footprint.append_array(expected_plank_corners)
				expected_deck_footprint.append_array(expected_connector_corners)
				var deck_shape_matches := deck_shape != null and deck_shape.points.size() == 24
				if deck_shape != null:
					for corner: Vector3 in expected_deck_footprint:
						deck_shape_matches = (
							deck_shape_matches
							and _mesh_has_vertex(
								deck_shape.points,
								Vector3(corner.x, 0.105, corner.z)
							)
							and _mesh_has_vertex(
								deck_shape.points,
								Vector3(corner.x, -0.105, corner.z)
							)
						)
				_expect(
					deck_shape_matches,
					"One convex layer-2 deck hull is generated from every rendered walking-surface corner."
				)
				var bridge_space_state: PhysicsDirectSpaceState3D = (
					world.get_world_3d().direct_space_state
				)
				for deck_corner: Vector3 in expected_deck_footprint:
					var inset_probe: Vector3 = deck_corner.lerp(Vector3.ZERO, 0.02)
					var probe_top: Vector3 = bridge_root.to_global(
						Vector3(inset_probe.x, 0.75, inset_probe.z)
					)
					var probe_bottom: Vector3 = bridge_root.to_global(
						Vector3(inset_probe.x, -0.5, inset_probe.z)
					)
					var support_query := PhysicsRayQueryParameters3D.create(
						probe_top,
						probe_bottom,
						2
					)
					support_query.collide_with_areas = false
					var support_hit: Dictionary = bridge_space_state.intersect_ray(
						support_query
					)
					_expect(
						support_hit.get("collider") == bridge_deck,
						"Every rendered bridge-deck corner has matching layer-2 hull support."
					)
			var bridge_visuals := bridge_root.get_node_or_null(
				"BridgeVisuals"
			) as Node3D
			_expect(
				bridge_visuals != null
					and bridge_visuals.position.is_equal_approx(
						Vector3(-0.120460, 0.0, -0.1350954)
					),
				"The bridge presentation locks the right edge while retracting only the left."
			)
			if bridge_visuals != null:
				_expect(
					bridge_visuals.find_children(
						"*",
						"CollisionShape3D",
						true,
						false
					).is_empty()
					and bridge_visuals.find_children(
						"*",
						"StaticBody3D",
						true,
						false
					).is_empty(),
					"Bridge visuals contain no competing physics bodies or collision shapes."
				)
				var bridge_planks: Array[Node] = _direct_mesh_children_with_prefix(
					bridge_visuals,
					"BridgePlank"
				)
				_expect(bridge_planks.size() == 12, "The bridge retains twelve broad visible planks.")
				var expected_plank_corner := Vector3(1.546228, 0.09, 0.5002544)
				for plank_node: Node in bridge_planks:
					var plank := plank_node as MeshInstance3D
					var plank_mesh := plank.mesh as ArrayMesh if plank != null else null
					var plank_arrays: Array = (
						plank_mesh.surface_get_arrays(0)
						if plank_mesh != null and plank_mesh.get_surface_count() == 1
						else []
					)
					var plank_vertices := (
						plank_arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array
						if not plank_arrays.is_empty()
						else PackedVector3Array()
					)
					var plank_normals := (
						plank_arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array
						if not plank_arrays.is_empty()
						else PackedVector3Array()
					)
					_expect(
						plank != null
						and plank_mesh != null
						and plank_vertices.size() == 36
						and plank_normals.size() == 36
						and _mesh_has_vertex(plank_vertices, expected_plank_corner)
						and _mesh_has_vertex(plank_vertices, -expected_plank_corner)
						and _mesh_has_normal(plank_normals, Vector3.UP)
						and _mesh_has_normal(plank_normals, Vector3.DOWN),
						"Every bridge plank is the exact six-faced sheared 3D prism."
					)
				var bridge_rails: Array[Node] = _direct_mesh_children_with_prefix(
					bridge_visuals, "BridgeRail"
				)
				var bridge_posts: Array[Node] = _direct_mesh_children_with_prefix(
					bridge_visuals, "BridgePost"
				)
				var bridge_piles: Array[Node] = _direct_mesh_children_with_prefix(
					bridge_visuals, "BridgePile"
				)
				_expect(bridge_rails.size() == 2, "The broadened bridge retains two 3D rails.")
				_expect(bridge_posts.size() == 6, "The broadened bridge retains six 3D posts.")
				_expect(bridge_piles.size() == 4, "The broadened bridge retains four 3D piles.")
				for rail_node: Node in bridge_rails:
					var rail := rail_node as MeshInstance3D
					var side: float = signf(rail.position.x)
					var rail_box := rail.mesh as BoxMesh
					_expect(
						is_equal_approx(absf(rail.position.x), 1.741228)
							and is_equal_approx(rail.position.z, side * 0.3602544)
						and rail_box.size.is_equal_approx(
							Vector3(0.12, 0.12, bridge_length - 0.3)
						),
						"Each rail uses the projection-safe side extension without changing height."
					)
				for post_node: Node in bridge_posts:
					var post := post_node as MeshInstance3D
					var side: float = signf(post.position.x)
					var post_box := post.mesh as BoxMesh
					_expect(
						is_equal_approx(absf(post.position.x), 1.741228)
							and post_box.size.is_equal_approx(Vector3(0.16, 1.35, 0.16))
							and absf(post.position.z - side * 0.3602544)
						<= bridge_length * 0.5,
						"Each post follows its sheared rail edge with unchanged vertical dimensions."
					)
				for pile_node: Node in bridge_piles:
					var pile := pile_node as MeshInstance3D
					var side: float = signf(pile.position.x)
					var pile_box := pile.mesh as BoxMesh
					_expect(
						is_equal_approx(absf(pile.position.x), 1.081228)
							and pile_box.size.is_equal_approx(Vector3(0.26, 0.6, 0.26))
							and is_equal_approx(
								absf(pile.position.z - side * 0.3602544),
							bridge_length * 0.37
						),
						"Each pile keeps its original inset while following the widened 3D deck."
					)
			var connector_planks: Array[Node] = _direct_mesh_children_with_prefix(
				bridge_root, "BridgeConnectorPlank"
			)
			_expect(connector_planks.size() == 2, "Two centered boards cover the physical route handoffs.")
			for connector_node: Node in connector_planks:
				var connector := connector_node as MeshInstance3D
				var connector_box := connector.mesh as BoxMesh
				_expect(
					is_equal_approx(absf(connector.position.z), bridge_length * 0.5 - 0.14)
						and connector.position.x == 0.0
						and connector_box.size.is_equal_approx(Vector3(2.2, 0.18, 0.28)),
					"Each connector terminates exactly over the endpoint-aligned deck hull."
				)
		_expect(
			world.get_route_endpoint(&"stair_top").is_equal_approx(
				Vector3(-3.264106, 4.085, 5.353714)
			)
			and world.get_route_endpoint(&"stair_bottom").is_equal_approx(
				Vector3(-1.836513, 0.085, 4.842562)
			),
			"The steep stair retains the approved A/B endpoints and both terrace elevations."
		)
		_expect(
			absf(world.get_stair_slope_degrees() - 69.23899) < 0.01,
			"The compact stair keeps its measured 69.239-degree physical slope."
		)
		var stair_root := world.find_child("StoneStair", true, false) as Node3D
		_expect(stair_root != null, "The authored route materializes one 3D stone stair landmark.")
		if stair_root != null:
			var tread_exemplar := stair_root.get_node_or_null("StoneTread") as MeshInstance3D
			var riser_exemplar := stair_root.get_node_or_null("StoneRiser") as MeshInstance3D
			var stone_treads: Array[Node] = []
			var stone_risers: Array[Node] = []
			for stair_mesh_node: Node in stair_root.find_children("*", "MeshInstance3D", true, false):
				var stair_mesh := stair_mesh_node as MeshInstance3D
				if tread_exemplar != null and stair_mesh.material_override == tread_exemplar.material_override:
					stone_treads.append(stair_mesh_node)
				elif riser_exemplar != null and stair_mesh.material_override == riser_exemplar.material_override:
					stone_risers.append(stair_mesh_node)
			_expect(stone_treads.size() == 6, "The 3D stair has exactly six StoneTread meshes.")
			_expect(stone_risers.size() == 6, "The 3D stair has exactly six StoneRiser meshes.")
			var previous_tread_width := INF
			for tread_node: Node in stone_treads:
				var tread := tread_node as MeshInstance3D
				_expect(tread != null and tread.mesh is BoxMesh, "Every StoneTread is a fixed-thickness BoxMesh.")
				if tread != null and tread.mesh is BoxMesh:
					var tread_size: Vector3 = (tread.mesh as BoxMesh).size
					_expect(is_equal_approx(tread_size.y, 0.18), "Every StoneTread retains the authored slab thickness.")
					_expect(tread_size.x <= previous_tread_width + 0.0001, "StoneTread widths taper monotonically from the upper terrace to the lower trail.")
					previous_tread_width = tread_size.x
			for riser_node: Node in stone_risers:
				var riser := riser_node as MeshInstance3D
				_expect(riser != null and riser.mesh is BoxMesh, "Every StoneRiser is a BoxMesh.")

			var ramp_nodes: Array[Node] = stair_root.find_children("SmoothRampCollision", "", true, false)
			_expect(ramp_nodes.size() == 1, "The 3D stair owns exactly one SmoothRampCollision node.")
			if ramp_nodes.size() == 1:
				var ramp_body := ramp_nodes[0] as StaticBody3D
				_expect(ramp_body != null, "SmoothRampCollision is a StaticBody3D.")
				if ramp_body != null:
					_expect(ramp_body.collision_layer == 2, "SmoothRampCollision is exclusively on world collision layer 2.")
					var ramp_shapes: Array[Node] = ramp_body.find_children("*", "CollisionShape3D", true, false)
					_expect(ramp_shapes.size() == 1, "SmoothRampCollision owns exactly one CollisionShape3D.")
					if ramp_shapes.size() == 1:
						var ramp_collision := ramp_shapes[0] as CollisionShape3D
						_expect(ramp_collision.shape is BoxShape3D, "The smooth stair ramp uses one BoxShape3D collision resource.")
					if player != null:
						var ramp_axis := ramp_body.global_transform.basis.z.normalized()
						var horizontal_run := Vector2(ramp_axis.x, ramp_axis.z).length()
						var actual_slope := atan2(absf(ramp_axis.y), horizontal_run)
						_expect(
							actual_slope > deg_to_rad(65.0)
							and actual_slope <= deg_to_rad(72.0) + 0.0001,
							"The actual ramp is steep enough to require, but not exceed, the isolated stair policy."
						)
		var stair_area := world.find_child(
			"SteepStairTraversalArea",
			true,
			false
		) as Area3D
		_expect(stair_area != null, "The steep ramp owns one non-water traversal sensor.")
		if stair_area != null:
			_expect(
				stair_area.get_parent() == stair_root
				and stair_area.collision_layer == 0
				and stair_area.collision_mask == 1,
				"The stair sensor is isolated from world and water ownership layers."
			)
			var stair_area_shapes: Array[Node] = stair_area.find_children(
				"*",
				"CollisionShape3D",
				false,
				false
			)
			_expect(
				stair_area_shapes.size() == 1
				and (stair_area_shapes[0] as CollisionShape3D).shape is BoxShape3D,
				"The stair policy is bounded by one ordinary 3D box volume."
			)
		var stair_navigation_link := world.find_child(
			"SteepStairNavigationLink",
			true,
			false
		) as NavigationLink3D
		_expect(
			stair_navigation_link != null and stair_navigation_link.bidirectional,
			"A bidirectional navigation link connects the two real stair landings."
		)
		if stair_navigation_link != null:
			_expect(
				stair_navigation_link.start_position.is_equal_approx(
					Vector3(-3.781915, 4.085, 5.539117)
				)
				and stair_navigation_link.end_position.is_equal_approx(
					Vector3(-1.675453, 0.085, 5.405439)
				),
				"The navigation link lands on the authored upper and flat-lower approaches."
			)
		var contour_root := world.get_node_or_null(
			"Terrain/UpperPromontoryFrontContour"
		) as Node3D
		_expect(contour_root != null, "The upper terrace mounts one authored front-contour owner.")
		if contour_root != null:
			var contour_metrics: Dictionary = UpperPromontoryFront.get_validation_metrics()
			var contour_top := contour_root.get_node_or_null(
				"PromontoryContourTop"
			) as MeshInstance3D
			var contour_face := contour_root.get_node_or_null(
				"PromontoryContourFace"
			) as MeshInstance3D
			var contour_collision := contour_root.get_node_or_null(
				"PromontoryContourCollision"
			) as StaticBody3D
			_expect(
				contour_top != null and contour_top.mesh is ArrayMesh,
				"The integrated promontory top is one profile-derived ArrayMesh."
			)
			_expect(
				contour_face != null and contour_face.mesh is ArrayMesh,
				"The integrated promontory face is one profile-derived ArrayMesh."
			)
			_expect(
				contour_collision != null
				and contour_collision.collision_layer == 2
				and contour_collision.collision_mask == 1,
				"The integrated promontory contour is physical terrain on layer 2."
			)
			if contour_collision != null:
				_expect(
					contour_collision.get_child_count()
					== contour_metrics["collision_prism_count"],
					"The runtime contour retains one convex prism per sampled segment."
				)
		for hidden_section_name: StringName in [
			&"MainCenter",
			&"MainNearWestInset",
			&"MainEdgeFingerStair",
			&"PromontoryStairInteriorSupport",
			&"HomesteadPromontoryRight",
			&"HomesteadPromontoryNorthApron",
			&"HomesteadLipWest",
			&"HomesteadLipCenter",
			&"HomesteadLipEast",
		]:
			var hidden_body := world.get_node_or_null(
				"Terrain/%s" % hidden_section_name
			) as StaticBody3D
			_expect(hidden_body != null, "%s retains its established terrain owner." % hidden_section_name)
			if hidden_body != null:
				for child: Node in hidden_body.get_children():
					if child is MeshInstance3D:
						_expect(
							not (child as MeshInstance3D).visible,
							"%s no longer exposes a redundant rectangular cliff face." % hidden_section_name
						)
		for obsolete_lip_name: StringName in [
			&"HomesteadLipWest",
			&"HomesteadLipCenter",
			&"HomesteadLipEast",
		]:
			var obsolete_lip := world.get_node_or_null(
				"Terrain/%s" % obsolete_lip_name
			) as StaticBody3D
			_expect(
				obsolete_lip != null
				and obsolete_lip.collision_layer == 0
				and obsolete_lip.collision_mask == 0,
				"%s cannot protrude physically beyond the authored contour." % obsolete_lip_name
			)
		var compound := world.find_child(
			"HomesteadCompound",
			true,
			false
		) as Node3D
		var cottage_structure := world.find_child(
			"CottageStructureScale",
			true,
			false
		) as Node3D
		var wall_shell := world.find_child(
			"CottageWallShell",
			true,
			false
		) as Node3D
		_expect(
			compound != null
				and cottage_structure != null
				and cottage_structure.scale.is_equal_approx(Vector3(0.73, 0.84, 0.84))
				and wall_shell != null
				and wall_shell.get_parent() == compound
				and wall_shell.scale.is_equal_approx(Vector3.ONE)
				and world.find_child("HouseWalls", true, false) == null,
			"The cottage keeps its accepted presentation root while its wall shell owns an unscaled physical topology."
		)
		var expected_wall_shell: Dictionary = {
			&"CottageWestWall": {
				"position": Vector3(2.142716, 3.512000, -5.457196),
				"size": Vector3(0.240000, 2.688000, 4.228665),
				"yaw": 0.2506746603,
			},
			&"CottageSouthWall": {
				"position": Vector3(3.916821, 3.512000, -3.621429),
				"size": Vector3(3.083291, 2.688000, 0.252000),
				"yaw": 0.0,
			},
			&"CottageEastWall": {
				"position": Vector3(5.202967, 3.512000, -5.427429),
				"size": Vector3(0.219000, 2.688000, 4.116000),
				"yaw": 0.0,
			},
			&"CottageRearWall": {
				"position": Vector3(3.422112, 3.512000, -7.233429),
				"size": Vector3(4.072710, 2.688000, 0.252000),
				"yaw": 0.0,
			},
			&"CottageWestEntranceBay": {
				"position": Vector3(1.958807, 3.512000, -5.322429),
				"size": Vector3(0.897900, 2.688000, 1.848000),
				"yaw": 0.0,
			},
		}
		var shell_body_count := 0
		var shell_layout_matches := wall_shell != null
		var shell_static_bodies: Array[Node] = (
			wall_shell.find_children("*", "StaticBody3D", false, false)
			if wall_shell != null
			else []
		)
		for shell_body_name: StringName in expected_wall_shell:
			var shell_body := world.find_child(
				shell_body_name,
				true,
				false
			) as StaticBody3D
			var expected_shell_body: Dictionary = expected_wall_shell[shell_body_name]
			var shell_meshes: Array[Node] = []
			var shell_collisions: Array[Node] = []
			if shell_body != null:
				shell_body_count += 1
				shell_meshes = shell_body.find_children(
					"*",
					"MeshInstance3D",
					false,
					false
				)
				shell_collisions = shell_body.find_children(
					"*",
					"CollisionShape3D",
					false,
					false
				)
			shell_layout_matches = (
				shell_layout_matches
				and shell_body != null
				and shell_body.get_parent() == wall_shell
				and shell_body.scale.is_equal_approx(Vector3.ONE)
				and shell_body.collision_layer == 2
				and shell_body.collision_mask == 1
				and shell_body.position.is_equal_approx(
					expected_shell_body.get("position", Vector3.ZERO) as Vector3
				)
				and is_equal_approx(
					shell_body.rotation.y,
					expected_shell_body.get("yaw", 0.0) as float
				)
				and shell_meshes.size() == 1
				and shell_collisions.size() == 1
			)
			if shell_meshes.size() == 1 and shell_collisions.size() == 1:
				var shell_mesh := (shell_meshes[0] as MeshInstance3D).mesh as BoxMesh
				var shell_shape := (
					(shell_collisions[0] as CollisionShape3D).shape as BoxShape3D
				)
				shell_layout_matches = (
					shell_layout_matches
					and shell_mesh != null
					and shell_shape != null
					and shell_mesh.size.is_equal_approx(
						expected_shell_body.get("size", Vector3.ZERO) as Vector3
					)
					and shell_mesh.size.is_equal_approx(shell_shape.size)
				)
		_expect(
			shell_body_count == 5
				and shell_static_bodies.size() == 5
				and shell_layout_matches,
			"The trapezoidal cottage owns five exact unscaled BoxMesh/BoxShape3D wall volumes."
		)
		var foundation := world.find_child(
			"HouseFoundation",
			true,
			false
		) as StaticBody3D
		var foundation_mesh := (
			(foundation.get_child(0) as MeshInstance3D).mesh as BoxMesh
			if foundation != null
			else null
		)
		var entrance_bay := world.find_child(
			"CottageWestEntranceBay",
			true,
			false
		) as StaticBody3D
		var entrance_bay_mesh := (
			(entrance_bay.get_child(0) as MeshInstance3D).mesh as BoxMesh
			if entrance_bay != null
			else null
		)
		if foundation != null and foundation_mesh != null and entrance_bay != null and entrance_bay_mesh != null:
			var foundation_top: float = foundation.global_position.y + (
				foundation_mesh.size.y * foundation.global_transform.basis.y.length() * 0.5
			)
			var shell_bottom: float = entrance_bay.global_position.y - entrance_bay_mesh.size.y * 0.5
			_expect(
				shell_bottom < foundation_top
					and foundation_top - shell_bottom > 0.19,
				"The wall shell and projecting entrance bay remain rooted in the original physical foundation."
			)
		var side_window := world.find_child("SideWindow", true, false) as MeshInstance3D
		var side_window_cross := world.find_child(
			"SideWindowCross",
			true,
			false
		) as MeshInstance3D
		_expect(
			side_window != null
				and side_window.position.is_equal_approx(Vector3(4.519055, 3.7, -4.5))
				and side_window_cross != null
				and side_window_cross.position.is_equal_approx(Vector3(4.629055, 3.7, -4.5)),
			"The east side window and cross remain flush to the re-authored east wall."
		)
		var door_steps: Array[Node] = world.find_children(
			"DoorStep*",
			"StaticBody3D",
			true,
			false
		)
		_expect(door_steps.size() == 3, "The west cottage entry owns three physical 3D step bodies.")
		var chimney_layout: Dictionary = {
			&"ChimneyLowerShaft": {
				"position": Vector3(0.153, 6.600433242, -5.325453644),
				"size": Vector3(0.72, 1.255833517, 0.72),
			},
			&"Chimney": {
				"position": Vector3(0.153, 7.57835, -5.325453644),
				"size": Vector3(0.72, 0.70, 0.72),
			},
			&"ChimneyCap": {
				"position": Vector3(0.153, 8.4506, -5.325453644),
				"size": Vector3(0.94, 0.26, 0.94),
			},
			&"ChimneyOpening": {
				"position": Vector3(0.153, 8.6006, -5.325453644),
				"size": Vector3(0.55, 0.08, 0.55),
			},
		}
		for chimney_name: StringName in chimney_layout:
			var chimney_part := world.find_child(chimney_name, true, false) as MeshInstance3D
			var expected_chimney_part: Dictionary = chimney_layout[chimney_name]
			var chimney_box := chimney_part.mesh as BoxMesh if chimney_part != null else null
			_expect(
				chimney_part != null
					and chimney_box != null
					and chimney_part.position.is_equal_approx(
						expected_chimney_part.get("position", Vector3.ZERO) as Vector3
					)
					and chimney_box.size.is_equal_approx(
						expected_chimney_part.get("size", Vector3.ZERO) as Vector3
					),
				"%s keeps the measured target-facing 3D transform." % chimney_name
			)
		var chimney_lower := world.find_child("ChimneyLowerShaft", true, false) as MeshInstance3D
		var chimney_upper := world.find_child("Chimney", true, false) as MeshInstance3D
		if chimney_lower != null and chimney_upper != null:
			var lower_box := chimney_lower.mesh as BoxMesh
			var upper_box := chimney_upper.mesh as BoxMesh
			_expect(
				is_equal_approx(
					chimney_lower.position.y - lower_box.size.y * 0.5,
					5.972516484
				)
					and is_equal_approx(
						chimney_lower.position.y + lower_box.size.y * 0.5,
						chimney_upper.position.y - upper_box.size.y * 0.5
					),
				"The chimney remains continuous from its original roof-embedded base."
			)
		var expected_front_windows: Dictionary = {
			&"Window": Vector3(2.766403, 3.617743, -2.31),
			&"WindowLeft": Vector3(0.659350, 3.825409, -2.31),
		}
		var front_window_nodes: Array[Node] = world.find_children(
			"Window*",
			"MeshInstance3D",
			true,
			false
		)
		_expect(
			front_window_nodes.size() == 2,
			"The cottage presents exactly two target-matched south-face windows."
		)
		for window_name: StringName in expected_front_windows:
			var window := world.find_child(window_name, true, false) as MeshInstance3D
			var window_box := window.mesh as BoxMesh if window != null else null
			_expect(
				window != null
					and window_box != null
					and window.position.is_equal_approx(
						expected_front_windows[window_name] as Vector3
					)
					and window_box.size.is_equal_approx(Vector3(0.50, 0.54, 0.18))
					and is_equal_approx(
						window.position.z - window_box.size.z * 0.5,
						-2.4
				),
				"%s remains a shallow true-3D cuboid flush to the south wall." % window_name
			)
			var south_wall := world.find_child(
				"CottageSouthWall",
				true,
				false
			) as StaticBody3D
			var south_wall_box := (
				(south_wall.get_child(0) as MeshInstance3D).mesh as BoxMesh
				if south_wall != null
				else null
			)
			if window != null and window_box != null and south_wall != null and south_wall_box != null:
				var window_half_width: float = (
					window_box.size.x * window.global_transform.basis.x.length() * 0.5
				)
				var window_back_z: float = window.global_position.z - (
					window_box.size.z * window.global_transform.basis.z.length() * 0.5
				)
				var south_wall_west_x: float = (
					south_wall.global_position.x - south_wall_box.size.x * 0.5
				)
				var south_wall_east_x: float = (
					south_wall.global_position.x + south_wall_box.size.x * 0.5
				)
				var south_wall_front_z: float = (
					south_wall.global_position.z + south_wall_box.size.z * 0.5
				)
				_expect(
					window.global_position.x - window_half_width >= south_wall_west_x
						and window.global_position.x + window_half_width <= south_wall_east_x
						and absf(window_back_z - south_wall_front_z) < 0.001,
					"%s remains fully backed by and flush to the physical south-wall slab." % window_name
				)
		var expected_step_layout: Dictionary = {
			&"DoorStepTop": {
				"position": Vector3(1.188857, 2.08, -4.225212907),
				"size": Vector3(0.35, 0.16, 1.15),
			},
			&"DoorStepMiddle": {
				"position": Vector3(0.770107, 2.035, -4.345841707),
				"size": Vector3(0.65, 0.14, 1.15),
			},
			&"DoorStepBottom": {
				"position": Vector3(0.351357, 1.955, -4.466470506),
				"size": Vector3(0.45, 0.12, 1.15),
			},
		}
		var door_step_rids: Array[RID] = []
		for door_step_node: Node in door_steps:
			var door_step := door_step_node as StaticBody3D
			var expected_step: Dictionary = expected_step_layout.get(
				door_step.name,
				{}
			) as Dictionary
			var step_meshes: Array[Node] = door_step.find_children(
				"*",
				"MeshInstance3D",
				false,
				false
			)
			var step_collisions: Array[Node] = door_step.find_children(
				"*",
				"CollisionShape3D",
				false,
				false
			)
			_expect(
				door_step.collision_layer == 2
				and door_step.collision_mask == 1
				and door_step.get_parent().name == &"HomesteadCompound"
				and door_step.get_parent() is Node3D
				and (door_step.get_parent() as Node3D).scale.is_equal_approx(Vector3.ONE)
				and not expected_step.is_empty()
				and door_step.position.is_equal_approx(
					expected_step.get("position", Vector3.ZERO) as Vector3
				)
				and step_meshes.size() == 1
				and step_collisions.size() == 1,
				"%s keeps its exact unscaled west-entry transform and one layer-2 collision shape." % door_step.name
			)
			if step_meshes.size() == 1 and step_collisions.size() == 1:
				var step_mesh := (step_meshes[0] as MeshInstance3D).mesh as BoxMesh
				var step_shape := (step_collisions[0] as CollisionShape3D).shape as BoxShape3D
				_expect(
					step_mesh != null
					and step_shape != null
					and step_mesh.size.is_equal_approx(
						expected_step.get("size", Vector3.ZERO) as Vector3
					)
					and step_mesh.size.is_equal_approx(step_shape.size),
					"%s visual and collision boxes share the exact authored dimensions." % door_step.name
				)
			door_step_rids.append(door_step.get_rid())
		var step_top := world.find_child("DoorStepTop", true, false) as StaticBody3D
		var step_middle := world.find_child("DoorStepMiddle", true, false) as StaticBody3D
		var step_bottom := world.find_child("DoorStepBottom", true, false) as StaticBody3D
		_expect(
			step_top != null and step_middle != null and step_bottom != null,
			"The west entrance materializes the top, middle, and bottom tread bodies."
		)
		if step_top != null and step_middle != null and step_bottom != null:
			var top_box := (step_top.get_child(0) as MeshInstance3D).mesh as BoxMesh
			var middle_box := (step_middle.get_child(0) as MeshInstance3D).mesh as BoxMesh
			var bottom_box := (step_bottom.get_child(0) as MeshInstance3D).mesh as BoxMesh
			var door := world.find_child("Door", true, false) as MeshInstance3D
			var door_box := door.mesh as BoxMesh if door != null else null
			_expect(
				door != null
				and door_box != null
				and door.position.is_equal_approx(Vector3(-0.88, 2.628, -4.575))
				and door_box.size.is_equal_approx(Vector3(0.20, 2.127, 1.70)),
				"The readable entrance occupies the true west cottage face."
			)
			var door_material := (
				door.material_override as StandardMaterial3D if door != null else null
			)
			_expect(
				door_material != null
					and door_material.albedo_texture != null
					and door_material.albedo_color.is_equal_approx(Color("#e2c5a0")),
				"The door panel alone keeps the capture-calibrated value lift."
			)
			var door_lower := world.find_child(
				"DoorLowerPanel",
				true,
				false
			) as MeshInstance3D
			var door_lower_box := (
				door_lower.mesh as BoxMesh if door_lower != null else null
			)
			_expect(
				door_lower != null
					and door_lower_box != null
					and door_lower.position.is_equal_approx(
						Vector3(-1.235, 2.4511, -4.575)
					)
					and door_lower_box.size.is_equal_approx(
						Vector3(0.510, 0.8050, 1.70)
					)
					and door_lower.material_override is StandardMaterial3D
					and (door_lower.material_override as StandardMaterial3D).albedo_texture
						== door_material.albedo_texture
					and (door_lower.material_override as StandardMaterial3D).albedo_color
						.is_equal_approx(Color("#aa9478")),
				"The foundation-backed lower door leaf reaches the stoop without moving the upper frame."
			)
			var door_jambs: Array[Node] = world.find_children(
				"DoorJamb*",
				"MeshInstance3D",
				true,
				false
			)
			var door_inset := world.find_child(
				"DoorInset",
				true,
				false
			) as MeshInstance3D
			var door_inset_box := (
				door_inset.mesh as BoxMesh if door_inset != null else null
			)
			var door_lintel := world.find_child(
				"DoorLintel",
				true,
				false
			) as MeshInstance3D
			var door_lintel_box := (
				door_lintel.mesh as BoxMesh if door_lintel != null else null
			)
			var jamb_layout_matches := door_jambs.size() == 2
			for jamb_node: Node in door_jambs:
				var jamb := jamb_node as MeshInstance3D
				var jamb_box := jamb.mesh as BoxMesh if jamb != null else null
				jamb_layout_matches = (
					jamb_layout_matches
					and jamb != null
					and jamb_box != null
					and is_equal_approx(jamb.position.y, 2.628)
					and jamb_box.size.is_equal_approx(Vector3(0.28, 2.127, 0.25))
				)
			_expect(
				jamb_layout_matches
				and door_inset != null
				and door_inset_box != null
				and door_inset.position.is_equal_approx(Vector3(-1.01, 2.578, -4.575))
				and door_inset_box.size.is_equal_approx(Vector3(0.10, 1.60, 1.05))
				and door_lintel != null
				and door_lintel_box != null
				and door_lintel.position.is_equal_approx(Vector3(-1.01, 3.816, -4.575))
				and door_lintel_box.size.is_equal_approx(Vector3(0.32, 0.25, 2.00)),
				"The west entrance keeps its measured lowered panel and 19-pixel frame."
			)
			if door != null and door_box != null:
				var door_outer_x: float = door.global_position.x - (
					door_box.size.x * door.global_transform.basis.x.length() * 0.5
				)
				var door_inner_x: float = door.global_position.x + (
					door_box.size.x * door.global_transform.basis.x.length() * 0.5
				)
				var top_inner_x: float = step_top.global_position.x + top_box.size.x * 0.5
				_expect(
					absf(door_outer_x - top_inner_x) < 0.001,
					"The physical stoop meets the west door plane without a route gap."
				)
				if entrance_bay != null and entrance_bay_mesh != null:
					var bay_outer_x: float = (
						entrance_bay.global_position.x - entrance_bay_mesh.size.x * 0.5
					)
					_expect(
						absf(door_inner_x - bay_outer_x) < 0.001,
						"The accepted door panel is physically flush to the projecting west entrance bay."
					)
			_expect(
				step_middle.global_position.x + middle_box.size.x * 0.5
				> step_top.global_position.x - top_box.size.x * 0.5
				and step_bottom.global_position.x + bottom_box.size.x * 0.5
				> step_middle.global_position.x - middle_box.size.x * 0.5
				and step_middle.global_position.z - middle_box.size.z * 0.5
				< step_top.global_position.z + top_box.size.z * 0.5
				and step_middle.global_position.z + middle_box.size.z * 0.5
				> step_top.global_position.z - top_box.size.z * 0.5
				and step_bottom.global_position.z - bottom_box.size.z * 0.5
				< step_middle.global_position.z + middle_box.size.z * 0.5
				and step_bottom.global_position.z + bottom_box.size.z * 0.5
				> step_middle.global_position.z - middle_box.size.z * 0.5,
				"The three descending tread bodies overlap as a continuous 3D fan."
			)
			var space_state: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
			for support_corner: Vector2 in [
				Vector2(4.126357, -0.541471),
				Vector2(4.126357, 0.608529),
				Vector2(4.576357, -0.541471),
				Vector2(4.576357, 0.608529),
				Vector2(4.445107, -0.420842),
				Vector2(4.445107, 0.729158),
				Vector2(5.095107, -0.420842),
				Vector2(5.095107, 0.729158),
				Vector2(5.013857, -0.300213),
				Vector2(5.013857, 0.849787),
				Vector2(5.363857, -0.300213),
				Vector2(5.363857, 0.849787),
			]:
				var support_query := PhysicsRayQueryParameters3D.create(
					Vector3(support_corner.x, 5.015, support_corner.y),
					Vector3(support_corner.x, 3.515, support_corner.y),
					2
				)
				support_query.exclude = door_step_rids
				support_query.collide_with_areas = false
				_expect(
					UpperPromontoryFront.contains_top_support_xz(support_corner)
					and not space_state.intersect_ray(support_query).is_empty(),
					"West stoop corner %s remains backed by layer-2 upper terrain." % support_corner
				)
		var fence_north := world.find_child("FenceNorth", true, false) as StaticBody3D
		var fence_east := world.find_child("FenceEast", true, false) as StaticBody3D
		_expect(
			fence_north != null and fence_east != null,
			"The north and east fence bodies remain materialized."
		)
		if fence_north != null and fence_east != null:
			var north_box := (fence_north.get_child(0) as MeshInstance3D).mesh as BoxMesh
			var east_box := (fence_east.get_child(0) as MeshInstance3D).mesh as BoxMesh
			var north_east_endpoint := fence_north.to_global(
				Vector3(north_box.size.x * 0.5, 0.0, 0.0)
			)
			var east_north_endpoint := fence_east.to_global(
				Vector3(0.0, 0.0, -east_box.size.z * 0.5)
			)
			_expect(
				Vector2(north_east_endpoint.x, north_east_endpoint.z).distance_to(
					Vector2(east_north_endpoint.x, east_north_endpoint.z)
				) < 0.001,
				"The asymmetrically extended north fence meets the east fence without a gap."
			)
		var summary: Dictionary = world.get_physics_summary()
		print(
			"HOMESTEAD_3D_METRIC: world_sprites=%d mesh_instances=%d multimesh_instances=%d static_bodies=%d collision_shapes=%d"
			% [
				summary.get("world_sprites", -1),
				summary.get("mesh_instances", 0),
				summary.get("multimesh_instances", 0),
				summary.get("static_bodies", 0),
				summary.get("collision_shapes", 0),
			]
		)
		_expect(summary.get("static_bodies", 0) >= 30, "Terrain, bridge, buildings, trees, rocks, and fences own StaticBody3D collision.")
		_expect(summary.get("collision_shapes", 0) >= 30, "The baseline materializes real CollisionShape3D resources.")
		_expect(
			summary.get("areas", 0) == 3,
			"The world owns exactly two water hazards plus one isolated stair sensor."
		)
		_expect(summary.get("trail_ribbons", 0) == 4, "The route uses four fitted 3D ribbons for the through-road, courtyard, stair, and bridge connections.")
		_expect(summary.get("landmarks", 0) == 4, "The compound, wheat, stair, and bridge remain the four authored landmarks.")
		_expect(summary.get("world_sprites", -1) == 0, "Terrain and world props are genuine volumetric meshes, not Sprite3D billboards.")
		_expect(summary.get("mesh_instances", 0) >= 500, "The homestead, foliage, crops, rocks, bridge, and cliffs materialize visible 3D mesh geometry.")
		var space_state: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
		for garden_corner: Vector2 in [
			Vector2(4.648, 5.141),
			Vector2(4.133, 5.966),
			Vector2(7.922, 7.186),
			Vector2(7.407, 8.011),
		]:
			_expect(
				UpperPromontoryFront.contains_top_support_xz(garden_corner)
				and _has_upper_world_floor(
					space_state,
					Vector3(garden_corner.x, UpperPromontoryFront.TOP_Y, garden_corner.y)
				),
				"The cultivated garden corner %s remains backed by profile-aligned layer-2 terrain." % garden_corner
			)
		for supported_probe: Vector2 in [
			Vector2(-10.0, -1.1),
			Vector2(13.3, 5.9),
		]:
			_expect(
				UpperPromontoryFront.contains_top_support_xz(supported_probe)
				and _has_upper_world_floor(
					space_state,
					Vector3(supported_probe.x, UpperPromontoryFront.TOP_Y, supported_probe.y)
				),
				"Profile-only cap probe %s has matching layer-2 support." % supported_probe
			)
		for unsupported_probe: Vector2 in [
			Vector2(-10.0, -0.4),
			Vector2(13.3, 6.7),
		]:
			_expect(
				not UpperPromontoryFront.contains_top_support_xz(unsupported_probe),
				"The profile-derived upper cap stops before forward probe %s." % unsupported_probe
			)
		var hazards_root := world.get_node_or_null("Hazards") as Node3D
		var water_areas: Array[Area3D] = _get_direct_water_areas(hazards_root)
		var water_owner_names := PackedStringArray()
		for water_area: Area3D in water_areas:
			water_owner_names.append(String(water_area.name))
			var direct_shape_count: int = 0
			for child: Node in water_area.get_children():
				if child is CollisionShape3D:
					direct_shape_count += 1
					_expect(child.get_parent() == water_area, "Every water CollisionShape3D remains parented to its established Area3D owner.")
					_expect(
						(child as CollisionShape3D).shape is ConvexPolygonShape3D,
						"Every water hazard segment follows the endpoint shoreline with a convex prism."
					)
			_expect(direct_shape_count > 0, "%s retains segmented water collision shapes." % water_area.name)
		water_owner_names.sort()
		var expected_owner_names: PackedStringArray = RiverShoreProfile.get_water_area_owner_names()
		expected_owner_names.sort()
		_expect(
			water_areas.size() == RiverShoreProfile.WATER_AREA_OWNER_COUNT
			and water_owner_names == expected_owner_names,
			"Hazards owns exactly the established WestWater and EastWater Area3D nodes."
		)
		var water_surfaces: Array[Node] = world.find_children(
			"RiverWaterSurface*",
			"MeshInstance3D",
			true,
			false
		)
		_expect(
			water_surfaces.size() == 2,
			"The visible river is split only around the explicit land occlusion."
		)
		for surface_node: Node in water_surfaces:
			var surface_mesh := surface_node as MeshInstance3D
			_expect(
				surface_mesh != null and surface_mesh.mesh is ArrayMesh,
				"Visible water uses a shared-endpoint trapezoid ArrayMesh."
			)
		_expect(
			world.find_children("RiverWaterSegment*", "MeshInstance3D", true, false).is_empty(),
			"No exposed axis-aligned water boxes remain in the river silhouette."
		)
		for bank_name: StringName in [&"NorthRiverBank", &"SouthRiverBank"]:
			var bank_body := world.get_node_or_null("Terrain/%s" % bank_name) as StaticBody3D
			_expect(bank_body != null, "%s remains a physical layer-2 river bank." % bank_name)
			if bank_body != null:
				_expect(bank_body.collision_layer == 2, "%s uses the world collision layer." % bank_name)
				var bank_shapes: Array[Node] = bank_body.find_children(
					"*",
					"CollisionShape3D",
					false,
					false
				)
				_expect(bank_shapes.size() >= 120, "%s follows the shoreline at half-meter resolution." % bank_name)
				for bank_shape_node: Node in bank_shapes:
					_expect(
						(bank_shape_node as CollisionShape3D).shape is ConvexPolygonShape3D,
						"%s collision is made only from endpoint-matched convex prisms." % bank_name
					)
		for bank_mesh_name: StringName in [
			&"NorthRiverBankTop",
			&"SouthRiverBankTop",
			&"NorthRiverBankFace",
			&"SouthRiverBankFace",
		]:
			var bank_mesh := world.get_node_or_null("Terrain/%s" % bank_mesh_name) as MeshInstance3D
			_expect(
				bank_mesh != null and bank_mesh.mesh is ArrayMesh,
				"%s is one shared-endpoint ArrayMesh rather than exposed bank boxes." % bank_mesh_name
			)
		var bridge_north: Vector3 = world.get_route_endpoint(&"bridge_north")
		var endpoint_shores: Vector2 = RiverShoreProfile.sample_effective_shores(bridge_north.x)
		_expect(
			not RiverShoreProfile.is_land_at_x(bridge_north.x)
			and bridge_north.z >= endpoint_shores.x
			and bridge_north.z <= endpoint_shores.y,
			"The bridge north endpoint remains inside the open authored channel."
		)
		var bridge_shores: Vector2 = RiverShoreProfile.sample_effective_shores(
			RiverShoreProfile.BRIDGE_PIN_X
		)
		var bridge_water_point := Vector3(
			RiverShoreProfile.BRIDGE_PIN_X,
			-0.1,
			(bridge_shores.x + bridge_shores.y) * 0.5
		)
		_expect(
			_water_area_names_at_point(space_state, bridge_water_point).is_empty(),
			"The physical bridge corridor remains outside both water Area3D owners."
		)
		var occlusion_x: float = (
			RiverShoreProfile.FULL_OCCLUSION_MIN_X
			+ RiverShoreProfile.FULL_OCCLUSION_MAX_X
		) * 0.5
		var occlusion_shores: Vector2 = RiverShoreProfile.sample_effective_shores(occlusion_x)
		var occlusion_floor_point := Vector3(occlusion_x, 0.5, occlusion_shores.x)
		_expect(
			_has_world_floor(space_state, occlusion_floor_point),
			"The full shoreline occlusion is backed by a physical layer-2 land surface."
		)
		for boundary_probe_x: float in [
			RiverShoreProfile.FULL_OCCLUSION_MIN_X + 0.02,
			occlusion_x,
			RiverShoreProfile.FULL_OCCLUSION_MAX_X - 0.02,
		]:
			var probe_shores: Vector2 = RiverShoreProfile.sample_effective_shores(boundary_probe_x)
			var probe_point := Vector3(boundary_probe_x, -0.1, probe_shores.x)
			_expect(
				_water_area_names_at_point(space_state, probe_point).is_empty(),
				"Water hazard collision is trimmed from the full-occlusion interval at x=%.2f." % boundary_probe_x
			)
			_expect(
				not _river_water_mesh_covers_x(world, boundary_probe_x),
				"Rendered water is trimmed from the full-occlusion interval at x=%.2f." % boundary_probe_x
			)
		for open_x: float in [-8.4, 3.0]:
			var open_shores: Vector2 = RiverShoreProfile.sample_effective_shores(open_x)
			var open_point := Vector3(open_x, -0.1, (open_shores.x + open_shores.y) * 0.5)
			var expected_owner := String(RiverShoreProfile.water_area_owner_for_x(open_x))
			_expect(
				_water_area_names_at_point(space_state, open_point) == PackedStringArray([expected_owner]),
				"Open water at x=%.1f belongs only to %s." % [open_x, expected_owner]
			)
		_expect(_has_world_floor(space_state, world.get_spawn_position()), "The spawn path has a physical 3D floor.")
		_expect(_has_world_floor(space_state, (world.get_route_endpoint(&"stair_top") + world.get_route_endpoint(&"stair_bottom")) * 0.5), "The visible stair is backed by its smooth physical ramp.")
		_expect(_has_world_floor(space_state, (world.get_route_endpoint(&"bridge_north") + world.get_route_endpoint(&"bridge_south")) * 0.5), "The timber bridge owns a physical 3D deck.")
		for floor_probe_x: float in [-8.5, 3.0]:
			var floor_probe_shores: Vector2 = RiverShoreProfile.sample_effective_shores(floor_probe_x)
			_expect(
				not _has_world_floor(
					space_state,
					Vector3(floor_probe_x, 0.5, (floor_probe_shores.x + floor_probe_shores.y) * 0.5)
				),
				"Profile-derived open river water at x=%.2f has no walkable land bar." % floor_probe_x
			)

	if player != null:
		var collision := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var sprite := player.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
		_expect(collision != null and collision.shape is CapsuleShape3D, "The 3D player uses a capsule collision shape.")
		_expect(player.scale.is_equal_approx(Vector3.ONE), "The CharacterBody3D is not scaled.")
		_expect(collision == null or collision.scale.is_equal_approx(Vector3.ONE), "The 3D collision shape is not scaled.")
		_expect(sprite != null and sprite.sprite_frames.has_animation(&"front_idle"), "The 3D player uses the authored animated front-facing atlas.")
		_expect(sprite != null and sprite.sprite_frames.has_animation(&"back_run"), "The 3D player can animate away from camera while running.")
		_expect(player.global_position.distance_to(world.get_spawn_position()) < 0.25, "The player starts on the cottage path in 3D space.")
		player.set_steep_stair_traversal_active(true)
		_expect(
			player.is_steep_stair_traversal_active()
			and is_equal_approx(player.floor_max_angle, deg_to_rad(72.0)),
			"Entering the stair volume raises only the player's floor angle to 72 degrees."
		)
		player.set_steep_stair_traversal_active(false)
		_expect(
			not player.is_steep_stair_traversal_active()
			and is_equal_approx(player.floor_max_angle, deg_to_rad(65.0)),
			"Leaving the stair volume restores the ordinary 65-degree floor policy."
		)

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


func _mesh_has_vertex(vertices: PackedVector3Array, expected: Vector3) -> bool:
	for vertex: Vector3 in vertices:
		if vertex.is_equal_approx(expected):
			return true
	return false


func _mesh_has_normal(normals: PackedVector3Array, expected: Vector3) -> bool:
	for normal: Vector3 in normals:
		if normal.normalized().dot(expected.normalized()) >= 0.9999:
			return true
	return false


func _direct_mesh_children_with_prefix(parent: Node, prefix: String) -> Array[Node]:
	var matches: Array[Node] = []
	for child: Node in parent.get_children():
		if child is MeshInstance3D and String(child.name).begins_with(prefix):
			matches.append(child)
	return matches


func _find_matching_box_meshes(root: Node, exemplar: MeshInstance3D) -> Array[MeshInstance3D]:
	var matches: Array[MeshInstance3D] = []
	var exemplar_box := exemplar.mesh as BoxMesh
	for descendant: Node in root.find_children("*", "MeshInstance3D", true, false):
		var candidate := descendant as MeshInstance3D
		var candidate_box := candidate.mesh as BoxMesh
		if candidate_box == null:
			continue
		if (
			candidate_box.size.is_equal_approx(exemplar_box.size)
			and candidate.material_override == exemplar.material_override
		):
			matches.append(candidate)
	return matches


func _get_direct_water_areas(hazards_root: Node3D) -> Array[Area3D]:
	var areas: Array[Area3D] = []
	if hazards_root == null:
		return areas
	for child: Node in hazards_root.get_children():
		if child is Area3D:
			areas.append(child as Area3D)
	return areas


func _water_area_names_at_point(
	space_state: PhysicsDirectSpaceState3D,
	point: Vector3
) -> PackedStringArray:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.collision_mask = 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var names := PackedStringArray()
	for hit: Dictionary in space_state.intersect_point(query, 8):
		var area := hit.get("collider") as Area3D
		if area != null and not names.has(String(area.name)):
			names.append(String(area.name))
	names.sort()
	return names


func _river_water_mesh_covers_x(world: HomesteadWorld3D, x_value: float) -> bool:
	for descendant: Node in world.find_children(
		"RiverWaterSurface*",
		"MeshInstance3D",
		true,
		false
	):
		var water_mesh := descendant as MeshInstance3D
		if water_mesh == null or water_mesh.mesh == null:
			continue
		var mesh_bounds: AABB = water_mesh.mesh.get_aabb()
		var scale_x: float = water_mesh.global_transform.basis.x.length()
		var min_x: float = water_mesh.global_position.x + mesh_bounds.position.x * scale_x
		var max_x: float = water_mesh.global_position.x + mesh_bounds.end.x * scale_x
		if (
			x_value > min_x + 0.0001
			and x_value < max_x - 0.0001
		):
			return true
	return false


func _has_world_floor(space_state: PhysicsDirectSpaceState3D, point: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		point + Vector3.UP * 4.0,
		point + Vector3.DOWN * 5.0,
		2
	)
	query.collide_with_areas = false
	return not space_state.intersect_ray(query).is_empty()


func _has_upper_world_floor(
	space_state: PhysicsDirectSpaceState3D,
	point: Vector3
) -> bool:
	var query := PhysicsRayQueryParameters3D.create(
		point + Vector3.UP * 1.0,
		point + Vector3.DOWN * 0.5,
		2
	)
	query.collide_with_areas = false
	return not space_state.intersect_ray(query).is_empty()

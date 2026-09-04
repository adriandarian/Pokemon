class_name HomesteadWorld3D
extends Node3D

const TrailRibbon = preload("res://features/homestead_3d/trail_ribbon_3d.gd")
const WorldInteractable = preload("res://features/mouse_navigation/world_interactable_3d.gd")
const RiverLayout = preload("res://features/homestead_3d/river_layout_3d.gd")
const RiverShoreProfile = preload("res://features/homestead_3d/river_shore_profile_3d.gd")
const UpperPromontoryFront = preload(
	"res://features/homestead_3d/upper_promontory_front_3d.gd"
)
const GRASS_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_grass_top_v9.png")
const MOSS_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_moss_cap_v1.png")
const CLIFF_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_cliff_face_v7.png")
const FOLIAGE_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_foliage_v6.png")
const WATER_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_water_v9.png")
const STONE_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_cliff_3d.png")
const STAIR_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_stair_paver_v2_candidate.png")
const TRAIL_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_trail_top_v10_candidate.png")
const WOOD_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_wood_3d.png")
const ROOF_TEXTURE: Texture2D = preload("res://assets/voxel/cottage_roof_tile_v5.png")
const PLASTER_TEXTURE: Texture2D = preload("res://assets/voxel/cottage_plaster_v5.png")

signal water_entered(body: Node3D)

const SPAWN_POSITION := Vector3(-1.1, 4.08, 3.16)
const STAIR_APPROACH_START := Vector3(-1.813104, 4.085, 3.442016)
const NORTH_TRAIL_END := Vector3(-3.264106, 4.085, 5.353714)
const STAIR_BOTTOM := Vector3(-1.836513, 0.085, 4.842562)
const STAIR_NAVIGATION_TOP := Vector3(-3.781915, 4.085, 5.539117)
const STAIR_NAVIGATION_BOTTOM := Vector3(-1.675453, 0.085, 5.405439)
const BRIDGE_NORTH := Vector3(-1.699365, 0.265, 13.927374)
const BRIDGE_SOUTH := Vector3(-0.346146, 0.265, 19.564056)
const WHEAT_CENTER_X := 17.7
const WHEAT_CENTER_Z := -5.1
const WHEAT_TOP_HEIGHT := 7.0
const WHEAT_TERRACE_HALF_WIDTH := 8.0
const WHEAT_TERRACE_DEPTH := 13.0
const VISUAL_ROUTE_DETAIL_LIFT := 0.045
const STAIR_WIDTH := 2.08
const STAIR_TOP_WIDTH := 2.65
const STEEP_STAIR_MAX_SLOPE_DEGREES := 72.0
const COURTYARD_LAYOUT_OFFSET := Vector3(-1.15357, 0.0, 0.179132)
const COURTYARD_TRAIL_WIDTH := 3.38
const COTTAGE_LAYOUT_OFFSET := Vector3(1.539257, 0.0, -0.727429)
const ROOF_SLOPE_ROW_COUNT := 5
const ROOF_OUTER_ROW_OFFSET := 3.652226368
const ROOF_ROW_INSET := 0.840556592
const ROOF_ROW_RISE := 0.15
const ROOF_TILE_SIZE := Vector3(0.90, 0.18, 0.56)
const SHED_LAYOUT_OFFSET := Vector3(-0.87, 0.0, -1.39)
const YARD_LAYOUT_OFFSET := Vector3(-3.1, 0.0, 1.7)
const FENCE_LAYOUT_OFFSET := Vector3(1.926792, 0.0, -1.070580)
const GARDEN_LAYOUT_OFFSET := Vector3(-0.1285, 0.0, -3.4792)
const GARDEN_WIDTH_SCALE := 0.915
const FENCE_WIDTH_SCALE := 0.87
const GARDEN_DEPTH_SCALE := 0.46
const GARDEN_YAW_DEGREES := -31.993477
const FENCE_DEPTH_SCALE := 0.74
const FENCE_EAST_EXTENSION := 1.50

var _materials: Dictionary = {}
var _route_endpoints: Dictionary = {}
var _built: bool = false

@onready var terrain_root: Node3D = %Terrain
@onready var route_root: Node3D = %Route
@onready var props_root: Node3D = %Props
@onready var hazards_root: Node3D = %Hazards


func _ready() -> void:
	if _built:
		return
	_built = true
	_create_materials()
	_build_terrain()
	_build_route()
	_build_homestead()
	_build_wheat_field()
	_build_forest_frame()
	_build_ground_details()
	_build_homestead_dressing()
	_build_homestead_cliff_dressing()
	_build_cliff_vegetation()
	_build_micro_ground_cover()
	_build_biome_scatter()
	_build_riverbank_foliage()
	_build_water_hazards()


func get_spawn_position() -> Vector3:
	return SPAWN_POSITION


func get_route_endpoint(endpoint_id: StringName) -> Vector3:
	return _route_endpoints.get(endpoint_id, Vector3.ZERO) as Vector3


func get_physics_summary() -> Dictionary:
	return {
		"static_bodies": _count_type(self, StaticBody3D),
		"areas": _count_type(self, Area3D),
		"collision_shapes": _count_type(self, CollisionShape3D),
		"trail_ribbons": _count_type(self, TrailRibbon3D),
		"landmarks": get_tree().get_nodes_in_group("homestead_3d_landmark").size(),
		"world_sprites": _count_type(terrain_root, Sprite3D) + _count_type(props_root, Sprite3D),
		"mesh_instances": _count_type(self, MeshInstance3D),
		"multimesh_instances": _count_type(self, MultiMeshInstance3D),
	}


func get_stair_slope_degrees() -> float:
	var rise: float = absf(NORTH_TRAIL_END.y - STAIR_BOTTOM.y)
	var run: float = Vector2(
		NORTH_TRAIL_END.x - STAIR_BOTTOM.x,
		NORTH_TRAIL_END.z - STAIR_BOTTOM.z
	).length()
	return rad_to_deg(atan2(rise, run))


func _create_materials() -> void:
	_materials[&"grass"] = _make_textured_material(GRASS_TEXTURE, Color("#a8ac9b"), 1.0, 0.22)
	_materials[&"grass_light"] = _make_textured_material(GRASS_TEXTURE, Color("#bab59a"), 1.0, 0.22)
	_materials[&"grass_dark"] = _make_textured_material(GRASS_TEXTURE, Color("#858c7d"), 1.0, 0.18)
	_materials[&"grass_mid"] = _make_textured_material(GRASS_TEXTURE, Color("#969b89"), 1.0, 0.18)
	_materials[&"grass_voxel_light"] = _make_textured_material(GRASS_TEXTURE, Color("#aca68e"), 1.0, 0.18)
	_materials[&"earth"] = _make_material(Color("#4d3d20"), 1.0)
	_materials[&"cliff"] = _make_textured_material(CLIFF_TEXTURE, Color("#a2acc2"), 1.0, 0.18)
	_materials[&"cliff_dark"] = _make_textured_material(CLIFF_TEXTURE, Color("#7c8693"), 1.0, 0.18)
	_materials[&"cliff_mid"] = _make_textured_material(CLIFF_TEXTURE, Color("#a9b3ca"), 1.0, 0.18)
	# A larger world-space texel footprint restores the broad stone-and-earth
	# variation present in the reference instead of mip-filtering it into one tan.
	_materials[&"trail"] = _make_textured_material(TRAIL_TEXTURE, Color("#e8e7ff"), 1.0, 0.18, false)
	_materials[&"trail_edge"] = _make_material(Color("#776d45"), 1.0)
	_materials[&"stone"] = _make_textured_material(STONE_TEXTURE, Color("#b5b6a2"), 0.95, 0.18)
	_materials[&"stone_light"] = _make_textured_material(STONE_TEXTURE, Color("#c6c7b1"), 0.95, 0.18)
	# Keep the stair volumetric, but let its treads inherit the irregular paver
	# joints and moss variation from the generated surface instead of reading as
	# flat grey prototype boxes in the locked camera.
	_materials[&"stair_stone"] = _make_textured_material(
		STAIR_TEXTURE,
		Color("#fffbe6"),
		1.0,
		0.38
	)
	_materials[&"boulder"] = _make_textured_material(STONE_TEXTURE, Color("#62685e"), 1.0, 0.12)
	_materials[&"boulder_light"] = _make_textured_material(STONE_TEXTURE, Color("#777d70"), 1.0, 0.12)
	_materials[&"stair_tread"] = _make_textured_material(
		STAIR_TEXTURE,
		Color("#8e8772"),
		1.0,
		0.38
	)
	(_materials[&"stair_stone"] as StandardMaterial3D).texture_filter = (
		BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
	)
	(_materials[&"stair_tread"] as StandardMaterial3D).texture_filter = (
		BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
	)
	_materials[&"wood"] = _make_textured_material(WOOD_TEXTURE, Color("#967f65"), 0.9, 0.18, false, false)
	_materials[&"wood_dark"] = _make_textured_material(WOOD_TEXTURE, Color("#5d5142"), 1.0, 0.18, false, false)
	# The west-facing door needs a higher local value than the structural timber
	# to remain readable at the locked overview angle. Keep this isolated from the
	# jambs, lintel, and inset so their accepted frame contrast does not change.
	_materials[&"door_panel"] = _make_textured_material(WOOD_TEXTURE, Color("#e2c5a0"), 1.0, 0.18, false, false)
	_materials[&"door_lower_panel"] = _make_textured_material(WOOD_TEXTURE, Color("#aa9478"), 1.0, 0.18, false, false)
	_materials[&"bridge_wood"] = _make_textured_material(WOOD_TEXTURE, Color("#cfce94"), 0.9, 0.18, false, false)
	_materials[&"bridge_dark"] = _make_textured_material(WOOD_TEXTURE, Color("#857e54"), 1.0, 0.18, false, false)
	_materials[&"plaster"] = _make_textured_material(PLASTER_TEXTURE, Color("#c9bea0"), 1.0, 0.2)
	_materials[&"roof"] = _make_textured_material(ROOF_TEXTURE, Color("#99a26c"), 0.92, 0.12)
	_materials[&"roof_light"] = _make_textured_material(ROOF_TEXTURE, Color("#aebc79"), 0.92, 0.12)
	_materials[&"roof_dark"] = _make_textured_material(ROOF_TEXTURE, Color("#736e49"), 0.96, 0.12)
	_materials[&"teal"] = _make_material(Color("#124b49"), 0.86)
	_materials[&"teal_dark"] = _make_material(Color("#0b3737"), 0.9)
	_materials[&"window_glass"] = _make_material(Color("#0b3536"), 0.86)
	_materials[&"wheat"] = _make_material(Color("#6f5018"), 1.0)
	_materials[&"wheat_light"] = _make_material(Color("#946b20"), 1.0)
	_materials[&"leaf"] = _make_textured_material(FOLIAGE_TEXTURE, Color("#e3ead8"), 1.0, 0.15)
	_materials[&"leaf_light"] = _make_textured_material(FOLIAGE_TEXTURE, Color("#fff4d6"), 1.0, 0.15)
	_materials[&"leaf_dark"] = _make_textured_material(FOLIAGE_TEXTURE, Color("#a9b49f"), 1.0, 0.15)
	# The generated moss sheet has stronger value grouping than the grass family.
	# Keep it on compact caps and ledges where its authored pattern does not visibly
	# repeat across a broad plane.
	_materials[&"moss"] = _make_textured_material(MOSS_TEXTURE, Color("#92977f"), 1.0, 0.18)
	_materials[&"moss_light"] = _make_textured_material(MOSS_TEXTURE, Color("#a4a486"), 1.0, 0.18)
	_materials[&"reed"] = _make_material(Color("#5d6f2d"), 1.0)
	_materials[&"reed_tip"] = _make_material(Color("#99782c"), 1.0)
	_materials[&"flower"] = _make_material(Color("#dc7044"), 1.0)
	_materials[&"flower_white"] = _make_material(Color("#e9dfbd"), 1.0)
	_materials[&"water"] = _make_textured_material(WATER_TEXTURE, Color("#6c99b4"), 0.42, 0.08, false, true)
	_materials[&"black"] = _make_material(Color("#241d15"), 1.0)
	_materials[&"gold"] = _make_material(Color("#f1b43c"), 0.8)
	var shadow_material := _make_material(Color(0.07, 0.09, 0.025, 0.16), 1.0, true)
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[&"shadow"] = shadow_material


func _build_terrain() -> void:
	_add_terrain_section("MainWest", Vector3(-22.5, 1.92, -30.0), Vector3(19.0, 4.16, 60.0), 4.015)
	# The broad center collider/top remains the authoritative interior terrain but
	# now stops at the contour's shared join. The authored contour owns everything
	# from this seam to the visible foreground edge.
	_add_terrain_section("MainCenter", Vector3(-4.0, 1.92, -32.0), Vector3(10.0, 4.16, 56.0), 4.015)
	_add_terrain_section("MainEast", Vector3(16.5, 1.92, -29.0), Vector3(31.0, 4.16, 62.0), 4.015)
	# Keep the homestead terrace collision-backed while cutting a genuine stair
	# notch at the authored flight axis. The northern apron supports the shed and
	# courtyard; the full right section supports the cottage, garden, and fence compound.
	_add_terrain_section("HomesteadPromontoryRight", Vector3(9.05, 1.92, 1.1), Vector3(5.9, 4.16, 14.2), 4.015)
	_add_terrain_section("HomesteadPromontoryNorthApron", Vector3(3.55, 1.92, -0.15), Vector3(5.1, 4.16, 11.7), 4.015)
	# Collision-backed staggered lip blocks replace the ruler-straight terrace
	# silhouette with the chunky stepped edge visible in the target concept.
	_add_terrain_section("HomesteadLipWest", Vector3(6.55, 1.92, 8.35), Vector3(0.8, 4.16, 1.05), 4.015)
	_add_terrain_section("HomesteadLipCenter", Vector3(6.1, 1.92, 8.52), Vector3(2.45, 4.16, 1.38), 4.015)
	_add_terrain_section("HomesteadLipEast", Vector3(9.65, 1.92, 8.34), Vector3(1.85, 4.16, 1.02), 4.015)
	_add_terrain_section("MainEdgeFingerFarWest", Vector3(-25.0, 1.92, 0.65), Vector3(4.0, 4.16, 1.3), 4.015)
	_add_terrain_section("MainEdgeFingerWest", Vector3(-18.0, 1.92, 1.2), Vector3(4.0, 4.16, 1.6), 4.015)
	_add_terrain_section("MainNearWestInset", Vector3(-11.0, 1.92, -32.0), Vector3(4.0, 4.16, 56.0), 4.015)
	# Stop the collision-backed finger exactly at the upper landing; continuing
	# it beneath the descent would hide the 3D treads and block the smooth ramp.
	_add_terrain_section(
		"MainEdgeFingerStair",
		Vector3(NORTH_TRAIL_END.x, 1.92, NORTH_TRAIL_END.z - 1.4),
		Vector3(4.1, 4.16, 2.0),
		4.015
	)
	var stair_interior_front_z: float = NORTH_TRAIL_END.z - 2.4
	var stair_interior_depth: float = (
		stair_interior_front_z - UpperPromontoryFront.INTERIOR_JOIN_Z
	)
	_add_terrain_section(
		"PromontoryStairInteriorSupport",
		Vector3(
			-3.0,
			1.92,
			UpperPromontoryFront.INTERIOR_JOIN_Z + stair_interior_depth * 0.5
		),
		Vector3(3.6, 4.16, stair_interior_depth),
		4.015
	)
	var stair_approach_apron := _add_static_box(
		terrain_root,
		"StairApproachApron",
		Vector3(-2.538605, 4.015, 4.397865),
		Vector3(2.65, 0.1, 2.4),
		_materials[&"trail"]
	)
	stair_approach_apron.rotation.y = deg_to_rad(-37.206)
	# The collider supports the final path fan, but rendering its rectangular box
	# duplicates the taper and produces a conspicuous tan slab at the cliff edge.
	var stair_apron_mesh := stair_approach_apron.get_child(0) as MeshInstance3D
	stair_apron_mesh.visible = false
	_add_terrain_section("MainEdgeFingerEast", Vector3(17.0, 1.92, 3.25), Vector3(4.0, 4.16, 2.5), 4.015)
	_add_terrain_section("MainEdgeFingerFarEast", Vector3(26.0, 1.92, 2.9), Vector3(4.0, 4.16, 1.8), 4.015)
	_build_upper_promontory_front()
	_add_static_box(terrain_root, "WheatTerrace", Vector3(WHEAT_CENTER_X, 5.46, WHEAT_CENTER_Z), Vector3(WHEAT_TERRACE_HALF_WIDTH * 2.0, 3.0, WHEAT_TERRACE_DEPTH), _materials[&"cliff"])
	_add_visual_box(terrain_root, "WheatTerraceTop", Vector3(WHEAT_CENTER_X, WHEAT_TOP_HEIGHT + 0.015, WHEAT_CENTER_Z), Vector3(WHEAT_TERRACE_HALF_WIDTH * 2.0 + 0.1, 0.08, WHEAT_TERRACE_DEPTH + 0.1), _materials[&"grass_light"])
	_build_lower_river_terrain()
	_build_retaining_blocks()
	_build_ground_voxel_surface()
	_build_shoreline_voxels()


func _build_upper_promontory_front() -> void:
	var contour_root: Node3D = UpperPromontoryFront.create_contour_root(
		_materials[&"grass"],
		_materials[&"cliff"],
		UpperPromontoryFront.DEFAULT_SAMPLE_STEP
	)
	terrain_root.add_child(contour_root)

	# Retain the large boxes as interior support, while removing only their
	# redundant exposed volume meshes. Their dedicated grass tops remain wherever
	# the contour does not replace them.
	for section_name: StringName in [
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
		_set_terrain_section_volume_visible(section_name, false)

	# These caps are wholly covered by the profile-derived top. Hiding them avoids
	# z overlap and prevents the former rectangular lips from protruding forward
	# of the new physical face.
	for top_name: StringName in [
		&"HomesteadPromontoryRightTop",
		&"HomesteadPromontoryNorthApronTop",
		&"HomesteadLipWestTop",
		&"HomesteadLipCenterTop",
		&"HomesteadLipEastTop",
	]:
		var top_mesh := terrain_root.get_node_or_null(NodePath(String(top_name))) as MeshInstance3D
		if top_mesh != null:
			top_mesh.visible = false

	# The three former lip colliders extend past the authored face. The new convex
	# prisms replace only these obsolete edge colliders; broad apron/promontory
	# bodies continue to support the interior compound.
	for lip_name: StringName in [
		&"HomesteadLipWest",
		&"HomesteadLipCenter",
		&"HomesteadLipEast",
	]:
		var lip_body := terrain_root.get_node_or_null(NodePath(String(lip_name))) as StaticBody3D
		if lip_body != null:
			lip_body.collision_layer = 0
			lip_body.collision_mask = 0


func _set_terrain_section_volume_visible(
	section_name: StringName,
	is_visible: bool
) -> void:
	var section_body := terrain_root.get_node_or_null(
		NodePath(String(section_name))
	) as StaticBody3D
	if section_body == null:
		return
	for child: Node in section_body.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = is_visible


func _build_lower_river_terrain() -> void:
	const SEGMENT_STEP := 0.5
	const LOWER_TERRAIN_MIN_Z := -2.0
	const LOWER_TERRAIN_MAX_Z := 43.0
	const BANK_COLLISION_TOP_Y := 0.0
	const BANK_VISUAL_TOP_Y := 0.055
	const BANK_BOTTOM_Y := -1.1
	const WATER_TOP_Y := -0.05
	const WATER_SHORE_OVERLAP := 0.275
	var north_bank_body := _create_river_bank_body(&"NorthRiverBank")
	var south_bank_body := _create_river_bank_body(&"SouthRiverBank")
	var north_bank_top := SurfaceTool.new()
	var south_bank_top := SurfaceTool.new()
	var north_bank_face := SurfaceTool.new()
	var south_bank_face := SurfaceTool.new()
	north_bank_top.begin(Mesh.PRIMITIVE_TRIANGLES)
	south_bank_top.begin(Mesh.PRIMITIVE_TRIANGLES)
	north_bank_face.begin(Mesh.PRIMITIVE_TRIANGLES)
	south_bank_face.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segment_index: int = 0
	var water_surface_index: int = 0
	for x_range: Vector2 in _river_profile_ranges(
		RiverLayout.WORLD_MIN_X,
		RiverLayout.WORLD_MAX_X
	):
		var samples: PackedVector4Array = _river_geometry_samples(
			x_range.x,
			x_range.y,
			SEGMENT_STEP
		)
		var water_surface := SurfaceTool.new()
		water_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var water_quad_count: int = 0
		for index: int in range(samples.size() - 1):
			var left: Vector4 = samples[index]
			var right: Vector4 = samples[index + 1]
			var center_x: float = (left.x + right.x) * 0.5
			var is_land: bool = RiverShoreProfile.is_land_at_x(center_x)
			var north_left := Vector3(left.x, BANK_VISUAL_TOP_Y, left.y)
			var north_right := Vector3(right.x, BANK_VISUAL_TOP_Y, right.y)
			var south_left := Vector3(left.x, BANK_VISUAL_TOP_Y, left.z)
			var south_right := Vector3(right.x, BANK_VISUAL_TOP_Y, right.z)
			if left.y > LOWER_TERRAIN_MIN_Z or right.y > LOWER_TERRAIN_MIN_Z:
				_add_river_horizontal_quad(
					north_bank_top,
					Vector3(left.x, BANK_VISUAL_TOP_Y, LOWER_TERRAIN_MIN_Z),
					Vector3(right.x, BANK_VISUAL_TOP_Y, LOWER_TERRAIN_MIN_Z),
					north_right,
					north_left
				)
				_add_river_vertical_quad(
					north_bank_face,
					north_left,
					north_right,
					Vector3(right.x, BANK_BOTTOM_Y, right.y),
					Vector3(left.x, BANK_BOTTOM_Y, left.y),
					true
				)
				_add_river_bank_collision_prism(
					north_bank_body,
					"NorthBankPrism%03d" % segment_index,
					left.x,
					right.x,
					LOWER_TERRAIN_MIN_Z,
					left.y,
					right.y,
					LOWER_TERRAIN_MIN_Z,
					BANK_COLLISION_TOP_Y,
					BANK_BOTTOM_Y
				)
			if left.z < LOWER_TERRAIN_MAX_Z or right.z < LOWER_TERRAIN_MAX_Z:
				_add_river_horizontal_quad(
					south_bank_top,
					south_left,
					south_right,
					Vector3(right.x, BANK_VISUAL_TOP_Y, LOWER_TERRAIN_MAX_Z),
					Vector3(left.x, BANK_VISUAL_TOP_Y, LOWER_TERRAIN_MAX_Z)
				)
				_add_river_vertical_quad(
					south_bank_face,
					south_left,
					south_right,
					Vector3(right.x, BANK_BOTTOM_Y, right.z),
					Vector3(left.x, BANK_BOTTOM_Y, left.z),
					false
				)
				_add_river_bank_collision_prism(
					south_bank_body,
					"SouthBankPrism%03d" % segment_index,
					left.x,
					right.x,
					left.z,
					LOWER_TERRAIN_MAX_Z,
					LOWER_TERRAIN_MAX_Z,
					right.z,
					BANK_COLLISION_TOP_Y,
					BANK_BOTTOM_Y
				)
			if not is_land:
				_add_river_horizontal_quad(
					water_surface,
					Vector3(left.x, WATER_TOP_Y, left.y - WATER_SHORE_OVERLAP),
					Vector3(right.x, WATER_TOP_Y, right.y - WATER_SHORE_OVERLAP),
					Vector3(right.x, WATER_TOP_Y, right.z + WATER_SHORE_OVERLAP),
					Vector3(left.x, WATER_TOP_Y, left.z + WATER_SHORE_OVERLAP)
				)
				water_quad_count += 1
			segment_index += 1
		if water_quad_count > 0:
			_commit_river_surface(
				"RiverWaterSurface%02d" % water_surface_index,
				water_surface,
				_materials[&"water"]
			)
		water_surface_index += 1
	_commit_river_surface("NorthRiverBankTop", north_bank_top, _materials[&"grass"])
	_commit_river_surface("SouthRiverBankTop", south_bank_top, _materials[&"grass"])
	_commit_river_surface("NorthRiverBankFace", north_bank_face, _materials[&"earth"])
	_commit_river_surface("SouthRiverBankFace", south_bank_face, _materials[&"earth"])
	# The target bridge begins on a broken stone finger rather than at a ruler-flat
	# shore. This collision-backed landing carries the route into the water ribbon.
	var bridge_shores: Vector2 = RiverShoreProfile.sample_effective_shores(BRIDGE_NORTH.x)
	var bridge_north_shore: float = bridge_shores.x
	var landing_depth: float = BRIDGE_NORTH.z - bridge_north_shore
	if landing_depth > 0.1:
		_add_terrain_section(
			"NorthBridgeLanding",
			Vector3(BRIDGE_NORTH.x, -0.55, bridge_north_shore + landing_depth * 0.5),
			Vector3(3.9, 1.1, landing_depth + 0.4),
			0.015
		)
	var south_bridge_shores: Vector2 = RiverShoreProfile.sample_effective_shores(BRIDGE_SOUTH.x)
	var south_bridge_shore: float = south_bridge_shores.y
	var south_landing_depth: float = south_bridge_shore - BRIDGE_SOUTH.z
	if south_landing_depth > 0.1:
		_add_terrain_section(
			"SouthBridgeLanding",
			Vector3(BRIDGE_SOUTH.x, -0.55, BRIDGE_SOUTH.z + south_landing_depth * 0.5),
			Vector3(3.9, 1.1, south_landing_depth + 0.4),
			0.015
		)


func _river_geometry_samples(
	min_x: float,
	max_x: float,
	step: float = RiverShoreProfile.DEFAULT_SAMPLE_STEP
) -> PackedVector4Array:
	var sample_x_values := PackedFloat32Array()
	for regular_sample: Vector4 in RiverShoreProfile.sample_segment(min_x, max_x, step):
		sample_x_values.append(regular_sample.x)
	for breakpoint_x: float in RiverShoreProfile.get_geometry_breakpoints():
		if breakpoint_x > min_x and breakpoint_x < max_x:
			sample_x_values.append(breakpoint_x)
	sample_x_values.sort()
	var samples := PackedVector4Array()
	for world_x: float in sample_x_values:
		if not samples.is_empty() and is_equal_approx(samples[-1].x, world_x):
			continue
		var shores: Vector2 = RiverShoreProfile.sample_effective_shores(world_x)
		samples.append(Vector4(
			world_x,
			shores.x,
			shores.y,
			1.0 if RiverShoreProfile.is_land_at_x(world_x) else 0.0
		))
	return samples


func _create_river_bank_body(body_name: StringName) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = 2
	body.collision_mask = 1
	terrain_root.add_child(body)
	return body


func _add_river_bank_collision_prism(
	body: StaticBody3D,
	shape_name: String,
	left_x: float,
	right_x: float,
	left_near_z: float,
	left_far_z: float,
	right_far_z: float,
	right_near_z: float,
	top_y: float,
	bottom_y: float
) -> void:
	var shape := ConvexPolygonShape3D.new()
	shape.points = PackedVector3Array([
		Vector3(left_x, top_y, left_near_z),
		Vector3(left_x, top_y, left_far_z),
		Vector3(right_x, top_y, right_far_z),
		Vector3(right_x, top_y, right_near_z),
		Vector3(left_x, bottom_y, left_near_z),
		Vector3(left_x, bottom_y, left_far_z),
		Vector3(right_x, bottom_y, right_far_z),
		Vector3(right_x, bottom_y, right_near_z),
	])
	var collision := CollisionShape3D.new()
	collision.name = shape_name
	collision.shape = shape
	body.add_child(collision)


func _add_river_horizontal_quad(
	surface: SurfaceTool,
	north_left: Vector3,
	north_right: Vector3,
	south_right: Vector3,
	south_left: Vector3
) -> void:
	_add_river_surface_triangle(surface, north_left, south_right, north_right)
	_add_river_surface_triangle(surface, north_left, south_left, south_right)


func _add_river_vertical_quad(
	surface: SurfaceTool,
	top_left: Vector3,
	top_right: Vector3,
	bottom_right: Vector3,
	bottom_left: Vector3,
	toward_positive_z: bool
) -> void:
	if toward_positive_z:
		_add_river_surface_triangle(surface, top_left, bottom_right, top_right)
		_add_river_surface_triangle(surface, top_left, bottom_left, bottom_right)
		return
	_add_river_surface_triangle(surface, top_left, top_right, bottom_right)
	_add_river_surface_triangle(surface, top_left, bottom_right, bottom_left)


func _add_river_surface_triangle(
	surface: SurfaceTool,
	first: Vector3,
	second: Vector3,
	third: Vector3
) -> void:
	for vertex: Vector3 in [first, second, third]:
		surface.set_uv(Vector2(vertex.x, vertex.z))
		surface.add_vertex(vertex)


func _commit_river_surface(
	mesh_name: String,
	surface: SurfaceTool,
	material: Material
) -> void:
	surface.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	mesh_instance.mesh = surface.commit()
	mesh_instance.material_override = material
	terrain_root.add_child(mesh_instance)


func _build_ground_voxel_surface() -> void:
	var dark_tiles: Array[Transform3D] = []
	var mid_tiles: Array[Transform3D] = []
	var light_tiles: Array[Transform3D] = []
	# The previous pass covered the world with a half-meter checker grid. The base
	# terrain already owns the complete grass surface, so this layer only needs to
	# break its value into broad, irregular voxel-painterly islands. Seeded lobes
	# keep the authored layout deterministic while avoiding a repeated tile field.
	var cluster_random := RandomNumberGenerator.new()
	cluster_random.seed = 0x7A2F19
	for z_index: int in range(43):
		var cluster_z: float = -40.0 + float(z_index) * 2.0 + cluster_random.randf_range(-0.34, 0.34)
		for x_index: int in range(33):
			var cluster_x: float = -32.0 + float(x_index) * 2.0 + cluster_random.randf_range(-0.34, 0.34)
			var cluster_selector: int = posmod(x_index * 11 + z_index * 7 + x_index * z_index, 13)
			if cluster_selector in [0, 4, 9, 12]:
				continue
			var tone_selector: int = posmod(x_index * 5 + z_index * 9 + cluster_selector, 11)
			var lobe_count: int = 1
			if cluster_random.randf() < 0.72:
				lobe_count += 1
			if cluster_random.randf() < 0.3:
				lobe_count += 1
			for lobe_index: int in range(lobe_count):
				var patch_x: float = cluster_x
				var patch_z: float = cluster_z
				if lobe_index > 0:
					var axis_bias: float = -1.0 if lobe_index % 2 == 0 else 1.0
					patch_x += cluster_random.randf_range(0.42, 1.1) * axis_bias
					patch_z += cluster_random.randf_range(-0.9, 0.9)
				if _is_in_river(Vector2(patch_x, patch_z), 0.25):
					continue
				if not _is_scatter_clear(Vector2(patch_x, patch_z)):
					continue
				var patch_width: float = cluster_random.randf_range(1.05, 2.15) if lobe_index == 0 else cluster_random.randf_range(0.48, 1.18)
				var patch_depth: float = cluster_random.randf_range(0.88, 1.9) if lobe_index == 0 else cluster_random.randf_range(0.42, 1.08)
				var top_height: float = _ground_height(patch_x, patch_z)
				var patch_size := Vector3(patch_width, 0.045, patch_depth)
				var patch_transform := Transform3D(Basis.IDENTITY.scaled(patch_size), Vector3(patch_x, top_height + 0.045, patch_z))
				if tone_selector in [0, 7]:
					light_tiles.append(patch_transform)
				elif tone_selector in [2, 4, 9]:
					mid_tiles.append(patch_transform)
				else:
					dark_tiles.append(patch_transform)
	_add_multimesh_boxes(terrain_root, "GroundVoxelDark", dark_tiles, _materials[&"grass_dark"])
	_add_multimesh_boxes(terrain_root, "GroundVoxelMid", mid_tiles, _materials[&"grass_mid"])
	_add_multimesh_boxes(terrain_root, "GroundVoxelLight", light_tiles, _materials[&"grass_voxel_light"])


func _build_shoreline_voxels() -> void:
	var grass_transforms: Array[Transform3D] = []
	var moss_transforms: Array[Transform3D] = []
	var stone_transforms: Array[Transform3D] = []
	var random := RandomNumberGenerator.new()
	random.seed = 0x51A0E
	for side_index: int in range(2):
		var water_direction: float = 1.0 if side_index == 0 else -1.0
		for shoreline_index: int in range(61):
			var x_value: float = -31.5 + float(shoreline_index) * 1.05
			if x_value > BRIDGE_NORTH.x - 2.0 and x_value < BRIDGE_NORTH.x + 2.0:
				continue
			var is_land: bool = RiverShoreProfile.is_land_at_x(x_value)
			var shores: Vector2 = RiverShoreProfile.sample_effective_shores(x_value)
			var bank_z: float = shores.x if side_index == 0 else shores.y
			# Broken clusters create stepped coves and mossy fingers instead of a
			# uniformly spaced necklace along both river edges.
			if random.randf() < 0.52:
				continue
			var lobe_count: int = 1
			if random.randf() < 0.2:
				lobe_count += 1
			if random.randf() < 0.04:
				lobe_count += 1
			var base_reach: float = random.randf_range(0.05, 0.55)
			for lobe_index: int in range(lobe_count):
				var lateral_offset: float = 0.0
				if lobe_index > 0:
					lateral_offset = random.randf_range(0.24, 0.62) * (-1.0 if lobe_index % 2 == 0 else 1.0)
				var lobe_reach: float = base_reach + random.randf_range(-0.1, 0.18)
				var tile_size := Vector3(
					random.randf_range(0.48, 0.98),
					random.randf_range(0.1, 0.16),
					random.randf_range(0.44, 0.9)
				)
				var origin := Vector3(x_value + lateral_offset, 0.055, bank_z + water_direction * lobe_reach)
				var transform := Transform3D(Basis.IDENTITY.scaled(tile_size), origin)
				if not is_land:
					if posmod(shoreline_index + lobe_index * 3, 5) == 0:
						moss_transforms.append(transform)
					else:
						grass_transforms.append(transform)
				if posmod(shoreline_index * 3 + lobe_index, 13) == 0:
					var stone_size := Vector3(random.randf_range(0.3, 0.62), random.randf_range(0.14, 0.3), random.randf_range(0.3, 0.62))
					var stone_origin := origin + Vector3(random.randf_range(-0.28, 0.28), -0.01, water_direction * random.randf_range(0.3, 0.72))
					if not is_land:
						stone_transforms.append(Transform3D(Basis.IDENTITY.scaled(stone_size), stone_origin))
	_add_multimesh_boxes(terrain_root, "ShoreGrassVoxels", grass_transforms, _materials[&"grass_dark"])
	_add_multimesh_boxes(terrain_root, "ShoreMossVoxels", moss_transforms, _materials[&"moss"])
	_add_multimesh_boxes(terrain_root, "ShoreStoneVoxels", stone_transforms, _materials[&"stone"])


func _build_retaining_blocks() -> void:
	for x_index: int in range(-9, 10):
		if x_index in [-2, -1]:
			continue
		var x_value: float = float(x_index) * 1.85
		# The profile's ArrayMesh is the sole continuous cliff face in its authored
		# spans. Keep the older block facade only outside those spans.
		if UpperPromontoryFront.has_contour_at_x(x_value):
			continue
		var edge_z: float = _main_edge_z(x_value)
		var tone: Material = _materials[&"cliff_dark"] if abs(x_index) % 2 == 0 else _materials[&"cliff"]
		for row_index: int in range(5):
			var row_y: float = 0.38 + float(row_index) * 0.76
			var row_offset: float = 0.24 if row_index % 2 == 1 else 0.0
			var row_tone: Material = tone if row_index % 3 != 0 else _materials[&"cliff_dark"]
			_add_visual_box(
				terrain_root,
				"RetainingBlock",
				Vector3(x_value + row_offset, row_y, edge_z + 0.045 + float(row_index % 2) * 0.035),
				Vector3(1.72, 0.72, 0.2),
				row_tone
			)
		var cap_push: float = 0.42 + float(posmod(abs(x_index) * 7, 4)) * 0.13
		_add_visual_box(
			terrain_root,
			"RetainingGrassCap",
			Vector3(x_value + (0.18 if x_index % 2 == 0 else -0.12), 4.04, edge_z + cap_push),
			Vector3(1.8, 0.16, 0.75 + cap_push * 0.35),
			_materials[&"moss_light"] if x_index % 5 == 0 else (_materials[&"grass_light"] if x_index % 3 == 0 else _materials[&"grass"])
		)
		if x_index % 2 == 0:
			_add_visual_box(
				terrain_root,
				"RetainingMossLedge",
				Vector3(x_value - 0.28, 2.02 + float(posmod(x_index, 3)) * 0.32, edge_z - 0.16),
				Vector3(0.72, 0.2, 0.48),
				_materials[&"moss_light"] if x_index % 4 == 0 else _materials[&"moss"]
			)
	for x_index: int in range(9):
		var x_value: float = WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH + 0.8 + float(x_index) * 1.8
		for row_index: int in range(5):
			var row_y: float = 4.3 + float(row_index) * 0.62
			var row_offset: float = 0.22 if row_index % 2 == 1 else 0.0
			var row_tone: Material = _materials[&"cliff"] if (x_index + row_index) % 3 != 0 else _materials[&"cliff_dark"]
			_add_visual_box(
				terrain_root,
				"HighRetainingBlock",
				Vector3(x_value + row_offset, row_y, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 + 0.045),
				Vector3(1.7, 0.56, 0.2),
				row_tone
			)
		if x_index % 2 == 1:
			_add_visual_box(terrain_root, "HighRetainingMoss", Vector3(x_value + 0.3, 6.2, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.08), Vector3(0.78, 0.22, 0.44), _materials[&"moss_light"] if x_index % 4 == 1 else _materials[&"moss"])
	var main_micro_stones: Array[Transform3D] = []
	var main_micro_moss: Array[Transform3D] = []
	for micro_index: int in range(-68, 69):
		var micro_x: float = float(micro_index) * 0.47
		if micro_x > -4.8 and micro_x < -0.8:
			continue
		var micro_edge_z: float = _main_edge_z(micro_x)
		for micro_row: int in range(8):
			var micro_origin := Vector3(
				micro_x + (0.22 if micro_row % 2 == 1 else 0.0),
				0.25 + float(micro_row) * 0.5,
				micro_edge_z - 0.34
			)
			var micro_scale := Vector3(0.43, 0.43, 0.28)
			main_micro_stones.append(Transform3D(Basis.IDENTITY.scaled(micro_scale), micro_origin))
			if posmod(micro_index * 3 + micro_row * 5, 11) == 0:
				main_micro_moss.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.34, 0.18, 0.34)), micro_origin + Vector3(0.0, 0.25, -0.02)))
	var high_micro_stones: Array[Transform3D] = []
	var high_micro_moss: Array[Transform3D] = []
	for micro_index: int in range(34):
		var micro_x: float = WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH + 0.2 + float(micro_index) * 0.47
		for micro_row: int in range(6):
			var micro_origin := Vector3(
				micro_x + (0.22 if micro_row % 2 == 1 else 0.0),
				4.25 + float(micro_row) * 0.5,
				WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 + 0.21
			)
			high_micro_stones.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.43, 0.43, 0.28)), micro_origin))
			if posmod(micro_index * 7 + micro_row * 3, 13) == 0:
				high_micro_moss.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.34, 0.18, 0.34)), micro_origin + Vector3(0.0, 0.25, 0.02)))
	# The generated cliff albedo owns the masonry. Only the sparse moss pockets are
	# layered over it; restoring the dense stone overlay would bring back the tiny
	# brick wallpaper rejected in the target comparison.
	_add_multimesh_boxes(terrain_root, "MainCliffMicroMoss", main_micro_moss, _materials[&"moss"])
	_add_multimesh_boxes(terrain_root, "HighCliffMicroMoss", high_micro_moss, _materials[&"moss_light"])


func _build_route() -> void:
	var north_points := PackedVector3Array([
		Vector3(30.0, 4.085, -55.0), Vector3(26.0, 4.085, -48.0),
		Vector3(22.8, 4.085, -41.4), Vector3(20.0, 4.085, -35.3),
		Vector3(17.0, 4.085, -32.3), Vector3(15.2, 4.085, -29.1),
		Vector3(13.3, 4.085, -26.1), Vector3(11.65, 4.085, -22.85),
		Vector3(11.2, 4.085, -18.57), Vector3(4.45, 4.085, -16.8), Vector3(2.75, 4.085, -12.205),
		Vector3(2.85, 4.085, -6.75), Vector3(-1.74, 4.085, -5.84),
		Vector3(0.8, 4.085, -2.5), Vector3(0.8, 4.085, -1.6),
		Vector3(0.0, 4.085, -1.2), Vector3(0.0, 4.085, 1.0),
		Vector3(-0.54512, 4.085, 1.771445), STAIR_APPROACH_START,
	])
	var lower_points := PackedVector3Array([
		STAIR_BOTTOM, Vector3(-1.44512, 0.085, 6.621445), Vector3(-1.45, 0.085, 9.2),
		Vector3(-1.75, 0.085, 10.55), BRIDGE_NORTH,
	])
	var south_points := PackedVector3Array([
		BRIDGE_SOUTH, Vector3(-0.6, 0.16, 21.4), Vector3(-0.8, 0.085, 22.3),
		Vector3(-0.7, 0.085, 23.7), Vector3(-0.7, 0.085, 25.6),
		Vector3(-1.5, 0.085, 27.8), Vector3(-2.6, 0.085, 30.3),
		Vector3(-4.2, 0.085, 32.8), Vector3(-6.2, 0.085, 35.4),
		Vector3(-8.4, 0.085, 37.8),
	])
	var courtyard_points := PackedVector3Array([
		Vector3(0.0, 4.092, -0.25) + COURTYARD_LAYOUT_OFFSET,
		Vector3(-1.636912, 4.092, -0.114733) + COURTYARD_LAYOUT_OFFSET,
		Vector3(2.500111, 4.092, 2.991638) + COURTYARD_LAYOUT_OFFSET,
		Vector3(4.710259, 4.092, 2.528328) + COURTYARD_LAYOUT_OFFSET,
		Vector3(6.313698, 4.092, 1.661376) + COURTYARD_LAYOUT_OFFSET,
	])
	var north_trail := TrailRibbon.new() as TrailRibbon3D
	north_trail.name = "NorthTrail"
	north_trail.configure(north_points, 2.65, _materials[&"trail"])
	route_root.add_child(north_trail)
	var lower_trail := TrailRibbon.new() as TrailRibbon3D
	lower_trail.name = "LowerTrail"
	lower_trail.configure(lower_points, 2.08, _materials[&"trail"])
	route_root.add_child(lower_trail)
	var south_trail := TrailRibbon.new() as TrailRibbon3D
	south_trail.name = "SouthTrail"
	south_trail.configure(south_points, 2.08, _materials[&"trail"])
	route_root.add_child(south_trail)
	var courtyard_trail := TrailRibbon.new() as TrailRibbon3D
	courtyard_trail.name = "HomesteadCourtyardTrail"
	courtyard_trail.configure(courtyard_points, COURTYARD_TRAIL_WIDTH, _materials[&"trail"])
	route_root.add_child(courtyard_trail)
	_build_trail_edge_blending(north_trail, 3101)
	_build_trail_edge_blending(lower_trail, 3102)
	_build_trail_edge_blending(south_trail, 3103)
	_build_trail_edge_blending(courtyard_trail, 3104)
	_build_route_junction(Vector3(0.08, 4.094, -0.2), 1.36)
	_build_stair_approach_taper()
	_build_stairs()
	_build_bridge()
	_route_endpoints = {
		# The ribbon hands off to the collision-backed taper before the stair; the
		# public route endpoint remains the shared top landing.
		&"north_trail_end": NORTH_TRAIL_END,
		&"stair_top": NORTH_TRAIL_END,
		&"stair_bottom": STAIR_BOTTOM,
		&"lower_trail_start": lower_trail.get_start_point(),
		&"lower_trail_end": lower_trail.get_end_point(),
		&"bridge_north": BRIDGE_NORTH,
		&"bridge_south": BRIDGE_SOUTH,
		&"south_trail_start": south_trail.get_start_point(),
	}


func _build_trail_edge_blending(trail: TrailRibbon3D, seed_value: int) -> void:
	var dark_transforms: Array[Transform3D] = []
	var light_transforms: Array[Transform3D] = []
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var points: PackedVector3Array = trail.get_render_points(4)
	for index: int in range(1, points.size() - 1, 2):
		var tangent: Vector3 = points[index + 1] - points[index - 1]
		tangent.y = 0.0
		if tangent.is_zero_approx():
			continue
		tangent = tangent.normalized()
		var side := Vector3(-tangent.z, 0.0, tangent.x)
		for side_sign: float in [-1.0, 1.0]:
			if random.randf() > 0.78:
				continue
			var edge_distance: float = trail.route_width * random.randf_range(0.43, 0.58)
			var patch_size := Vector3(
				random.randf_range(0.16, 0.34),
				random.randf_range(0.055, 0.11),
				random.randf_range(0.14, 0.3)
			)
			var patch_position: Vector3 = points[index] \
				+ side * side_sign * edge_distance \
				+ tangent * random.randf_range(-0.22, 0.22) \
				+ Vector3.UP * (VISUAL_ROUTE_DETAIL_LIFT + patch_size.y * 0.5)
			var patch_yaw: float = atan2(tangent.x, tangent.z) + random.randf_range(-0.55, 0.55)
			var transform := Transform3D(Basis(Vector3.UP, patch_yaw).scaled(patch_size), patch_position)
			if (index + int(side_sign)) % 5 == 0:
				light_transforms.append(transform)
			else:
				dark_transforms.append(transform)
	_add_multimesh_boxes(route_root, "%sEdgeGrassDark" % trail.name, dark_transforms, _materials[&"grass_dark"])
	_add_multimesh_boxes(route_root, "%sEdgeGrassLight" % trail.name, light_transforms, _materials[&"grass_light"])


func _build_route_junction(
	center: Vector3,
	radius: float,
	junction_name: StringName = &"HomesteadTrailJunction"
) -> void:
	var junction := MeshInstance3D.new()
	junction.name = junction_name
	junction.position = center
	var junction_mesh := CylinderMesh.new()
	junction_mesh.top_radius = radius
	junction_mesh.bottom_radius = radius
	junction_mesh.height = 0.018
	junction_mesh.radial_segments = 24
	junction.mesh = junction_mesh
	junction.material_override = _materials[&"trail"]
	route_root.add_child(junction)


func _build_stair_approach_taper() -> void:
	# One monotone strip replaces the overlapping circles that matched the broad
	# bounds but produced a bulb and an internal seam. These ground-plane sections
	# are the inverse projection of the approved overview silhouette. Midpoint
	# perturbations only move across a section, so no triangle can fold backward.
	var fixed_left := PackedVector3Array([
		Vector3(-0.757687, 4.096, 4.24309),
		Vector3(-1.723715, 4.096, 5.442652),
		Vector3(-2.69721, 4.096, 5.565138),
		Vector3(-3.080605, 4.096, 5.442771),
	])
	var fixed_right := PackedVector3Array([
		Vector3(-2.868521, 4.096, 2.640942),
		Vector3(-3.353494, 4.096, 3.353078),
		Vector3(-3.636266, 4.096, 3.885453),
		Vector3(-3.399239, 4.096, 5.200916),
	])
	var midpoint_left_offsets := PackedFloat32Array([0.025, 0.030, 0.020])
	var midpoint_right_offsets := PackedFloat32Array([-0.025, -0.025, -0.020])
	var left_sections := PackedVector3Array()
	var right_sections := PackedVector3Array()
	for section_index: int in range(fixed_left.size() - 1):
		left_sections.append(fixed_left[section_index])
		right_sections.append(fixed_right[section_index])
		var left_midpoint: Vector3 = fixed_left[section_index].lerp(fixed_left[section_index + 1], 0.5)
		var right_midpoint: Vector3 = fixed_right[section_index].lerp(fixed_right[section_index + 1], 0.5)
		var section_side: Vector3 = (right_midpoint - left_midpoint).normalized()
		left_sections.append(left_midpoint + section_side * midpoint_left_offsets[section_index])
		right_sections.append(right_midpoint + section_side * midpoint_right_offsets[section_index])
	left_sections.append(fixed_left[-1])
	right_sections.append(fixed_right[-1])

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section_index: int in range(left_sections.size() - 1):
		surface.add_vertex(left_sections[section_index])
		surface.add_vertex(right_sections[section_index + 1])
		surface.add_vertex(right_sections[section_index])
		surface.add_vertex(left_sections[section_index])
		surface.add_vertex(left_sections[section_index + 1])
		surface.add_vertex(right_sections[section_index + 1])
	surface.generate_normals()
	var approach := MeshInstance3D.new()
	approach.name = "StairApproachTaper"
	approach.mesh = surface.commit()
	approach.material_override = _materials[&"trail"]
	route_root.add_child(approach)


func _build_stairs() -> void:
	var stair_root := Node3D.new()
	stair_root.name = "StoneStair"
	stair_root.add_to_group("homestead_3d_landmark")
	route_root.add_child(stair_root)
	var horizontal_delta := Vector3(
		STAIR_BOTTOM.x - NORTH_TRAIL_END.x,
		0.0,
		STAIR_BOTTOM.z - NORTH_TRAIL_END.z
	)
	var stair_run: float = horizontal_delta.length()
	var stair_direction: Vector3 = horizontal_delta / stair_run
	var stair_yaw: float = atan2(stair_direction.x, stair_direction.z)
	var lower_tangent := Vector3(-1.44512, STAIR_BOTTOM.y, 6.621445) - STAIR_BOTTOM
	lower_tangent.y = 0.0
	lower_tangent = lower_tangent.normalized()
	var bottom_landing := _add_visual_box(
		stair_root,
		"StairBottomLanding",
		STAIR_BOTTOM + lower_tangent * 0.28 + Vector3(0.0, -0.005, 0.0),
		Vector3(2.2, 0.08, 1.2),
		_materials[&"trail"]
	)
	bottom_landing.rotation.y = atan2(lower_tangent.x, lower_tangent.z)
	var step_count: int = 6
	var stair_rise: float = NORTH_TRAIL_END.y - STAIR_BOTTOM.y
	var step_depth: float = stair_run / float(step_count)
	var step_height: float = stair_rise / float(step_count)
	var slab_thickness: float = 0.18
	for index: int in range(step_count):
		var stair_progress: float = float(index) / float(step_count - 1)
		var visible_step_width: float = lerpf(STAIR_TOP_WIDTH, STAIR_WIDTH, stair_progress)
		var top_height: float = stair_rise - float(index) * step_height
		var center: Vector3 = NORTH_TRAIL_END + stair_direction * ((float(index) + 0.5) * step_depth)
		center.y = STAIR_BOTTOM.y + top_height - slab_thickness * 0.5 + 0.055
		var tread := _add_visual_box(stair_root, "StoneTread", center, Vector3(visible_step_width, slab_thickness, step_depth + 0.12), _materials[&"stair_stone"])
		tread.rotation.y = stair_yaw
		var riser_center := NORTH_TRAIL_END + stair_direction * (float(index + 1) * step_depth - 0.04)
		riser_center.y = STAIR_BOTTOM.y + top_height - step_height * 0.5 + 0.055
		var riser := _add_visual_box(stair_root, "StoneRiser", riser_center, Vector3(visible_step_width, step_height + 0.04, 0.16), _materials[&"stair_tread"])
		riser.rotation.y = stair_yaw
	var ramp := StaticBody3D.new()
	ramp.name = "SmoothRampCollision"
	ramp.collision_layer = 2
	ramp.collision_mask = 1
	ramp.position = Vector3(
		(NORTH_TRAIL_END.x + STAIR_BOTTOM.x) * 0.5,
		STAIR_BOTTOM.y + stair_rise * 0.5,
		(NORTH_TRAIL_END.z + STAIR_BOTTOM.z) * 0.5
	)
	ramp.rotation.y = stair_yaw
	ramp.rotation.x = atan2(stair_rise, stair_run)
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = Vector3(STAIR_WIDTH - 0.12, 0.12, sqrt(stair_rise * stair_rise + stair_run * stair_run))
	var collision := CollisionShape3D.new()
	collision.shape = ramp_shape
	ramp.add_child(collision)
	stair_root.add_child(ramp)
	_build_steep_stair_traversal(stair_root, stair_run, stair_yaw)


func _build_steep_stair_traversal(
	stair_root: Node3D,
	stair_run: float,
	stair_yaw: float
) -> void:
	# The compact reference silhouette needs a steeper flight than ordinary world
	# terrain. This non-water sensor changes only the player's floor policy while
	# their capsule is inside the stair envelope; movement still uses the real ramp.
	var traversal_area := Area3D.new()
	traversal_area.name = "SteepStairTraversalArea"
	traversal_area.position = (NORTH_TRAIL_END + STAIR_BOTTOM) * 0.5
	traversal_area.rotation.y = stair_yaw
	traversal_area.collision_layer = 0
	traversal_area.collision_mask = 1
	traversal_area.monitoring = true
	traversal_area.monitorable = false
	var traversal_shape := BoxShape3D.new()
	traversal_shape.size = Vector3(
		STAIR_TOP_WIDTH + 0.8,
		NORTH_TRAIL_END.y - STAIR_BOTTOM.y + 1.2,
		stair_run + 1.2
	)
	var traversal_collision := CollisionShape3D.new()
	traversal_collision.shape = traversal_shape
	traversal_area.add_child(traversal_collision)
	traversal_area.body_entered.connect(_on_steep_stair_body_entered)
	traversal_area.body_exited.connect(_on_steep_stair_body_exited)
	stair_root.add_child(traversal_area)

	var navigation_link := NavigationLink3D.new()
	navigation_link.name = "SteepStairNavigationLink"
	navigation_link.start_position = STAIR_NAVIGATION_TOP
	navigation_link.end_position = STAIR_NAVIGATION_BOTTOM
	navigation_link.bidirectional = true
	route_root.add_child(navigation_link)


func _on_steep_stair_body_entered(body: Node3D) -> void:
	if body.has_method(&"set_steep_stair_traversal_active"):
		body.call(&"set_steep_stair_traversal_active", true)


func _on_steep_stair_body_exited(body: Node3D) -> void:
	if body.has_method(&"set_steep_stair_traversal_active"):
		body.call(&"set_steep_stair_traversal_active", false)


func _build_bridge() -> void:
	var bridge_root := Node3D.new()
	bridge_root.name = "TimberBridge"
	bridge_root.add_to_group("homestead_3d_landmark")
	route_root.add_child(bridge_root)
	var bridge_vector: Vector3 = BRIDGE_SOUTH - BRIDGE_NORTH
	var bridge_length: float = Vector2(bridge_vector.x, bridge_vector.z).length()
	bridge_root.position = (BRIDGE_NORTH + BRIDGE_SOUTH) * 0.5
	bridge_root.rotation.y = atan2(bridge_vector.x, bridge_vector.z)
	# The authored route endpoints remain fixed. This offset and the matching
	# asymmetric half-span keep the accepted right silhouette locked while
	# retracting only the left edge four overview pixels with no screen-Y drift.
	var visual_root := Node3D.new()
	visual_root.name = "BridgeVisuals"
	visual_root.position = Vector3(-0.120460, 0.0, -0.1350954)
	bridge_root.add_child(visual_root)
	# The coupled X/Z extension follows the camera's zero-screen-Y ground vector.
	# Its reduced magnitude preserves the right edge while pulling only the left
	# rail, posts, piles, and plank ends inward.
	var side_extension := Vector3(0.321228, 0.0, 0.3602544)
	var plank_cross_half_axis := Vector3(1.225, 0.0, 0.0) + side_extension
	var plank_depth: float = 0.28
	var plank_end_margin: float = 0.25
	var plank_run_half_axis := Vector3(
		0.0,
		0.0,
		bridge_length * 0.5 - plank_end_margin + plank_depth * 0.5
	)
	# The physical deck is the convex hull of the real rendered walking surfaces:
	# four corners from the sheared plank run plus four corners from each centered
	# endpoint connector. One shape therefore backs the entire visible deck while
	# preserving the original endpoint-aligned route handoffs.
	var deck_footprint := PackedVector3Array([
		visual_root.position - plank_cross_half_axis - plank_run_half_axis,
		visual_root.position - plank_cross_half_axis + plank_run_half_axis,
		visual_root.position + plank_cross_half_axis + plank_run_half_axis,
		visual_root.position + plank_cross_half_axis - plank_run_half_axis,
	])
	var connector_half_axis := Vector3(1.1, 0.0, 0.0)
	var connector_depth_half_axis := Vector3(0.0, 0.0, plank_depth * 0.5)
	for connector_index: int in range(2):
		var connector_side: float = -1.0 + float(connector_index) * 2.0
		var connector_center := Vector3(
			0.0,
			0.0,
			connector_side * (bridge_length * 0.5 - plank_depth * 0.5)
		)
		deck_footprint.append(
			connector_center - connector_half_axis - connector_depth_half_axis
		)
		deck_footprint.append(
			connector_center - connector_half_axis + connector_depth_half_axis
		)
		deck_footprint.append(
			connector_center + connector_half_axis + connector_depth_half_axis
		)
		deck_footprint.append(
			connector_center + connector_half_axis - connector_depth_half_axis
		)
	_add_bridge_deck_collision(bridge_root, deck_footprint, 0.21)
	# Broad boards with visible water gaps match the reference's hand-built deck.
	# Thin rails and sparse posts own the outer envelope, avoiding a solid slab.
	var plank_count: int = 12
	for index: int in range(plank_count):
		var z_value: float = -bridge_length * 0.5 + plank_end_margin + float(index) * ((bridge_length - plank_end_margin * 2.0) / float(plank_count - 1))
		var material: Material = _materials[&"bridge_wood"] if index % 4 != 0 else _materials[&"bridge_dark"]
		_add_bridge_visual_prism(
			visual_root,
			"BridgePlank%02d" % index,
			Vector3(0.0, -0.125, z_value),
			plank_cross_half_axis,
			plank_depth,
			0.18,
			material
		)
	# These narrow centerline boards cover the visual handoff to both route
	# ribbons. They stay within the established silhouette and directly above the
	# unchanged collision deck.
	for connector_index: int in range(2):
		var connector_side: float = -1.0 + float(connector_index) * 2.0
		_add_visual_box(
			bridge_root,
			"BridgeConnectorPlank%02d" % connector_index,
			Vector3(0.0, -0.125, connector_side * (bridge_length * 0.5 - plank_depth * 0.5)),
			Vector3(2.2, 0.18, plank_depth),
			_materials[&"bridge_wood"]
		)
	for side_index: int in range(2):
		var side: float = -1.0 + float(side_index) * 2.0
		var side_center := side * (Vector3(1.42, 0.0, 0.0) + side_extension)
		for post_index: int in range(3):
			var post_z: float = -bridge_length * 0.5 + 0.25 + float(post_index) * ((bridge_length - 0.5) / 2.0)
			_add_visual_box(
				visual_root,
				"BridgePost%02d%02d" % [side_index, post_index],
				side_center + Vector3(0.0, 0.42, post_z),
				Vector3(0.16, 1.35, 0.16),
				_materials[&"bridge_dark"]
			)
		_add_visual_box(
			visual_root,
			"BridgeRail%02d" % side_index,
			side_center + Vector3(0.0, 0.67, 0.0),
			Vector3(0.12, 0.12, bridge_length - 0.3),
			_materials[&"bridge_wood"]
		)
	for pile_side_index: int in range(2):
		var pile_side: float = -1.0 + float(pile_side_index) * 2.0
		var pile_side_center := pile_side * (Vector3(0.76, 0.0, 0.0) + side_extension)
		for pile_z_index: int in range(2):
			var pile_z: float = (-1.0 + float(pile_z_index) * 2.0) * bridge_length * 0.37
			_add_visual_box(
				visual_root,
				"BridgePile%02d%02d" % [pile_side_index, pile_z_index],
				pile_side_center + Vector3(0.0, -0.35, pile_z),
				Vector3(0.26, 0.6, 0.26),
				_materials[&"bridge_dark"]
			)


func _add_bridge_deck_collision(
	parent: Node3D,
	footprint_points: PackedVector3Array,
	height: float
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "BridgeDeckCollision"
	body.collision_layer = 2
	body.collision_mask = 1
	body.position = Vector3(0.0, -0.16, 0.0)
	body.visible = false
	var shape_points := PackedVector3Array()
	var half_height: float = height * 0.5
	for footprint_point: Vector3 in footprint_points:
		shape_points.append(
			Vector3(footprint_point.x, -half_height, footprint_point.z)
		)
		shape_points.append(
			Vector3(footprint_point.x, half_height, footprint_point.z)
		)
	var shape := ConvexPolygonShape3D.new()
	shape.points = shape_points
	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func _add_bridge_visual_prism(
	parent: Node3D,
	mesh_name: String,
	center: Vector3,
	cross_half_axis: Vector3,
	depth: float,
	height: float,
	material: Material
) -> MeshInstance3D:
	var depth_half_axis := Vector3(0.0, 0.0, depth * 0.5)
	var height_half_axis := Vector3(0.0, height * 0.5, 0.0)
	var left_north := -cross_half_axis - depth_half_axis
	var left_south := -cross_half_axis + depth_half_axis
	var right_south := cross_half_axis + depth_half_axis
	var right_north := cross_half_axis - depth_half_axis
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_bridge_prism_quad(
		surface,
		left_north + height_half_axis,
		left_south + height_half_axis,
		right_south + height_half_axis,
		right_north + height_half_axis,
		Vector3.UP
	)
	_add_bridge_prism_quad(
		surface,
		left_north - height_half_axis,
		right_north - height_half_axis,
		right_south - height_half_axis,
		left_south - height_half_axis,
		Vector3.DOWN
	)
	_add_bridge_prism_quad(
		surface,
		right_north - height_half_axis,
		right_north + height_half_axis,
		right_south + height_half_axis,
		right_south - height_half_axis,
		Vector3.RIGHT
	)
	_add_bridge_prism_quad(
		surface,
		left_north - height_half_axis,
		left_south - height_half_axis,
		left_south + height_half_axis,
		left_north + height_half_axis,
		Vector3.LEFT
	)
	var south_normal := Vector3(
		-cross_half_axis.z,
		0.0,
		cross_half_axis.x
	).normalized()
	_add_bridge_prism_quad(
		surface,
		left_south - height_half_axis,
		right_south - height_half_axis,
		right_south + height_half_axis,
		left_south + height_half_axis,
		south_normal
	)
	_add_bridge_prism_quad(
		surface,
		left_north - height_half_axis,
		left_north + height_half_axis,
		right_north + height_half_axis,
		right_north - height_half_axis,
		-south_normal
	)
	var prism := MeshInstance3D.new()
	prism.name = mesh_name
	prism.position = center
	prism.mesh = surface.commit()
	prism.material_override = material
	parent.add_child(prism)
	return prism


func _add_bridge_prism_quad(
	surface: SurfaceTool,
	point_a: Vector3,
	point_b: Vector3,
	point_c: Vector3,
	point_d: Vector3,
	outward_normal: Vector3
) -> void:
	# Godot's visible front face is clockwise, so its geometric cross product is
	# opposite the desired generated normal.
	if (point_b - point_a).cross(point_c - point_a).dot(outward_normal) > 0.0:
		var swap := point_b
		point_b = point_d
		point_d = swap
	var points: Array[Vector3] = [
		point_a, point_b, point_c,
		point_a, point_c, point_d,
	]
	var uvs: Array[Vector2] = [
		Vector2(0.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0),
		Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(1.0, 0.0),
	]
	for index: int in range(points.size()):
		surface.set_normal(outward_normal)
		surface.set_uv(uvs[index])
		surface.add_vertex(points[index])


func _build_homestead() -> void:
	var compound := WorldInteractable.new()
	compound.name = "HomesteadCompound"
	compound.position = Vector3(4.0, 2.0, 4.5)
	compound.configure(
		"Trailkeeper Homestead",
		"The cottage is warm, but the open trail is calling. Your Field Guide tracks creatures, supplies, and badges.",
		Vector3(-1.5, 2.08, -3.0) + COTTAGE_LAYOUT_OFFSET,
		3.0
	)
	compound.add_to_group("homestead_3d_landmark")
	props_root.add_child(compound)
	var structure_root := Node3D.new()
	structure_root.name = "CottageStructureScale"
	var cottage_scale := Vector3(0.73, 0.84, 0.84)
	var cottage_pivot := Vector3(2.0, 2.0, -4.7)
	structure_root.scale = cottage_scale
	structure_root.position = cottage_pivot * (Vector3.ONE - cottage_scale) + COTTAGE_LAYOUT_OFFSET
	compound.add_child(structure_root)
	# The cottage is assembled from visible cuboids on every side. Its collision
	# volumes are the same volumes that define the foundation and walls; there is
	# no camera-facing artwork hiding proxy geometry.
	_add_static_box(structure_root, "HouseFoundation", Vector3(2.0, 2.22, -4.7), Vector3(6.5, 0.42, 5.6), _materials[&"stone"])
	for x_index: int in range(8):
		var block_x: float = -0.85 + float(x_index) * 0.82
		var block_tone: Material = _materials[&"stone_light"] if x_index % 3 == 0 else _materials[&"stone"]
		_add_visual_box(structure_root, "FoundationFrontBlock", Vector3(block_x, 2.38, -1.86), Vector3(0.74, 0.46, 0.38), block_tone)
		_add_visual_box(structure_root, "FoundationRearBlock", Vector3(block_x, 2.38, -7.54), Vector3(0.74, 0.46, 0.38), block_tone)
	for z_index: int in range(7):
		var block_z: float = -7.1 + float(z_index) * 0.81
		var side_tone: Material = _materials[&"stone"] if z_index % 2 == 0 else _materials[&"cliff_dark"]
		_add_visual_box(structure_root, "FoundationSideBlock", Vector3(-1.28, 2.38, block_z), Vector3(0.38, 0.46, 0.72), side_tone)
		_add_visual_box(structure_root, "FoundationSideBlock", Vector3(5.28, 2.38, block_z), Vector3(0.38, 0.46, 0.72), side_tone)
	# The wall shell is authored directly under the unscaled compound. In
	# particular, the rotated west wall therefore gives its BoxMesh and
	# BoxShape3D the same orthonormal transform instead of inheriting a sheared
	# basis from the cottage's non-uniform presentation scale. Its exterior
	# corners project to 50 pixels on the west face and 38 on the south face at
	# the locked overview camera, matching the reference facade ratio.
	var wall_shell := Node3D.new()
	wall_shell.name = "CottageWallShell"
	compound.add_child(wall_shell)
	var west_wall := _add_static_box(
		wall_shell,
		"CottageWestWall",
		Vector3(2.142716, 3.512000, -5.457196),
		Vector3(0.240000, 2.688000, 4.228665),
		_materials[&"plaster"]
	)
	west_wall.rotation.y = 0.2506746603
	_add_static_box(
		wall_shell,
		"CottageSouthWall",
		Vector3(3.916821, 3.512000, -3.621429),
		Vector3(3.083291, 2.688000, 0.252000),
		_materials[&"plaster"]
	)
	_add_static_box(
		wall_shell,
		"CottageEastWall",
		Vector3(5.202967, 3.512000, -5.427429),
		Vector3(0.219000, 2.688000, 4.116000),
		_materials[&"plaster"]
	)
	_add_static_box(
		wall_shell,
		"CottageRearWall",
		Vector3(3.422112, 3.512000, -7.233429),
		Vector3(4.072710, 2.688000, 0.252000),
		_materials[&"plaster"]
	)
	# This real projecting bay preserves the accepted west door and stoop plane.
	# Its west face exactly meets the scaled door panel, while its east edge
	# overlaps the diagonal wall across the full bay depth.
	_add_static_box(
		wall_shell,
		"CottageWestEntranceBay",
		Vector3(1.958807, 3.512000, -5.322429),
		Vector3(0.897900, 2.688000, 1.848000),
		_materials[&"plaster"]
	)
	# Repartition the timber frame onto the new honest wall faces. The shared
	# south-west post sits just behind WindowLeft so the real window remains
	# readable instead of being replaced by a camera-only opening.
	for front_post: Vector3 in [
		Vector3(0.605368, 3.92, -2.52),
		Vector3(2.0, 3.92, -2.36),
		Vector3(4.429055, 3.92, -2.36),
	]:
		_add_visual_box(structure_root, "HouseTimberPost", front_post, Vector3(0.28, 3.08, 0.25), _materials[&"wood_dark"])
	_add_visual_box(structure_root, "HouseBeam", Vector3(2.517211, 4.58, -2.36), Vector3(4.103687, 0.28, 0.28), _materials[&"wood_dark"])
	_add_visual_box(structure_root, "HouseSill", Vector3(2.517211, 2.65, -2.36), Vector3(4.103687, 0.25, 0.28), _materials[&"wood"])
	for rear_x: float in [-0.75, 1.839527, 4.429055]:
		_add_visual_box(structure_root, "HouseTimberPost", Vector3(rear_x, 3.92, -7.04), Vector3(0.28, 3.08, 0.25), _materials[&"wood_dark"])
	_add_visual_box(structure_root, "HouseBeam", Vector3(1.839527, 4.58, -7.04), Vector3(5.459055, 0.28, 0.28), _materials[&"wood_dark"])
	_add_visual_box(structure_root, "HouseSill", Vector3(1.839527, 2.65, -7.04), Vector3(5.459055, 0.25, 0.28), _materials[&"wood"])
	var west_beam := _add_visual_box(
		wall_shell,
		"HouseSideBeamWest",
		Vector3(2.026466, 4.167200, -5.427429),
		Vector3(0.190000, 0.235200, 3.797902),
		_materials[&"wood_dark"]
	)
	west_beam.rotation.y = 0.2506746603
	for west_post_center: Vector3 in [
		Vector3(1.628548, 3.638000, -6.981429),
		Vector3(2.424385, 3.638000, -3.873429),
	]:
		var west_post := _add_visual_box(
			wall_shell,
			"HouseSidePostWest",
			west_post_center,
			Vector3(0.190000, 2.520000, 0.240000),
			_materials[&"wood_dark"]
		)
		west_post.rotation.y = 0.2506746603
	for timber_z: float in [-6.55, -4.7, -2.85]:
		_add_visual_box(structure_root, "HouseSidePost", Vector3(4.459055, 3.95, timber_z), Vector3(0.25, 3.0, 0.28), _materials[&"wood_dark"])
	_add_visual_box(structure_root, "HouseSideBeam", Vector3(4.459055, 4.58, -4.7), Vector3(0.25, 0.28, 4.38), _materials[&"wood_dark"])
	# The entrance is authored on the true west wall. Swapping the thin and wide
	# axes keeps the complete door assembly flush to that face in every orbit.
	# The panel and contrasting frame span a projected 19-pixel entrance at the
	# locked overview angle. This keeps the physically correct west-wall location
	# readable instead of merging into the adjacent structural posts.
	_add_visual_box(structure_root, "Door", Vector3(-0.88, 2.628, -4.575), Vector3(0.20, 2.127, 1.70), _materials[&"door_panel"])
	# The foundation projects farther west than the wall and clips the lower eight
	# pixels of the leaf. This backed plinth section touches the main door's outer
	# face, embeds into the real foundation volume, and carries the same 3D width
	# down to the stoop without moving the accepted upper frame.
	_add_visual_box(
		structure_root,
		"DoorLowerPanel",
		Vector3(-1.235, 2.4511, -4.575),
		Vector3(0.510, 0.8050, 1.70),
		_materials[&"door_lower_panel"]
	)
	_add_visual_box(structure_root, "DoorInset", Vector3(-1.01, 2.578, -4.575), Vector3(0.10, 1.60, 1.05), _materials[&"wood"])
	_add_visual_box(structure_root, "DoorLintel", Vector3(-1.01, 3.816, -4.575), Vector3(0.32, 0.25, 2.00), _materials[&"wood"])
	for jamb_index: int in range(2):
		var jamb_z: float = [-5.45, -3.70][jamb_index]
		var jamb_name := "DoorJambBack" if jamb_index == 0 else "DoorJambFront"
		_add_visual_box(structure_root, jamb_name, Vector3(-0.99, 2.628, jamb_z), Vector3(0.28, 2.127, 0.25), _materials[&"wood"])
	# These three pre-scaled boxes live directly under the unscaled compound.
	# Their meshes and primitive colliders therefore share identical dimensions,
	# while the compact diagonal flight leaves the west wall along -X and steps
	# toward the courtyard in +Z. It projects to the measured 30 by 20 pixel
	# envelope without the previous four-meter-wide fan.
	_add_static_box(compound, "DoorStepTop", Vector3(1.188857, 2.08, -4.225212907), Vector3(0.35, 0.16, 1.15), _materials[&"stone_light"])
	_add_static_box(compound, "DoorStepMiddle", Vector3(0.770107, 2.035, -4.345841707), Vector3(0.65, 0.14, 1.15), _materials[&"stone"])
	_add_static_box(compound, "DoorStepBottom", Vector3(0.351357, 1.955, -4.466470506), Vector3(0.45, 0.12, 1.15), _materials[&"stone_light"])
	# Two shallow cuboid windows sit flush to the true south wall. Their exact
	# centers reproduce the two distinct teal openings in the target while
	# remaining honest from orbit instead of using camera-facing cards.
	_add_visual_box(structure_root, "Window", Vector3(2.766403, 3.617743, -2.31), Vector3(0.50, 0.54, 0.18), _materials[&"window_glass"])
	_add_visual_box(structure_root, "WindowLeft", Vector3(0.659350, 3.825409, -2.31), Vector3(0.50, 0.54, 0.18), _materials[&"window_glass"])
	# The west side window yielded to the entrance; retain the east-side window.
	_add_visual_box(structure_root, "SideWindow", Vector3(4.519055, 3.7, -4.5), Vector3(0.18, 0.82, 0.72), _materials[&"teal_dark"])
	_add_visual_box(structure_root, "SideWindowCross", Vector3(4.629055, 3.7, -4.5), Vector3(0.08, 0.86, 0.12), _materials[&"wood_dark"])
	# Stepped roof tiles create a true gable with readable eaves and rear depth.
	for roof_side: float in [-1.0, 1.0]:
		for roof_row: int in range(ROOF_SLOPE_ROW_COUNT):
			var roof_x: float = 2.206371605 + roof_side * (
				ROOF_OUTER_ROW_OFFSET - float(roof_row) * ROOF_ROW_INSET
			)
			var roof_y: float = 5.471703709 + float(roof_row) * ROOF_ROW_RISE
			for roof_column: int in range(10):
				var stagger := 0.0
				if roof_row % 2 == 1 and roof_column < 9:
					stagger = 0.233416157
				var roof_z: float = -6.821199059 + float(roof_column) * 0.466832314 + stagger
				var roof_tone: Material = _materials[&"roof_light"] if (roof_row + roof_column) % 5 == 0 else _materials[&"roof"]
				if (roof_row * 3 + roof_column) % 7 == 0:
					roof_tone = _materials[&"roof_dark"]
				_add_visual_box(structure_root, "RoofTile", Vector3(roof_x, roof_y, roof_z), ROOF_TILE_SIZE, roof_tone)
	for ridge_column: int in range(10):
		_add_visual_box(
			structure_root,
			"RoofRidgeTile",
			Vector3(2.206371605, 6.131703709, -6.761199059 + float(ridge_column) * 0.466832314),
			Vector3(0.74, 0.18, 0.44),
			_materials[&"roof_dark"] if ridge_column % 4 == 0 else _materials[&"roof"]
		)
	# The short upper stack matches the readable target silhouette. A contiguous
	# lower shaft keeps it rooted at the original roof-embedded base, so rotating
	# the honest 3D camera cannot reveal a floating chimney assembly.
	_add_visual_box(structure_root, "ChimneyLowerShaft", Vector3(0.153, 6.600433242, -5.325453644), Vector3(0.72, 1.255833517, 0.72), _materials[&"stone_light"])
	_add_visual_box(structure_root, "Chimney", Vector3(0.153, 7.57835, -5.325453644), Vector3(0.72, 0.70, 0.72), _materials[&"stone_light"])
	_add_visual_box(structure_root, "ChimneyCap", Vector3(0.153, 8.4506, -5.325453644), Vector3(0.94, 0.26, 0.94), _materials[&"stone"])
	_add_visual_box(structure_root, "ChimneyOpening", Vector3(0.153, 8.6006, -5.325453644), Vector3(0.55, 0.08, 0.55), _materials[&"black"])
	_add_flat_shadow(structure_root, Vector3(2.8, 2.066, -4.4), Vector2(7.5, 4.8))
	# The approved composition requires the cottage, detached shed, and cultivated
	# yard to move independently. Each root keeps real 3D children and colliders;
	# these are layout transforms, not camera-facing artwork or visual overlays.
	var shed_scale_root := Node3D.new()
	shed_scale_root.name = "DetachedShedScale"
	var shed_scale := Vector3(0.61, 0.75, 0.75)
	shed_scale_root.scale = shed_scale
	shed_scale_root.position = Vector3(2.0, 2.0, -4.7) * (Vector3.ONE - shed_scale) + SHED_LAYOUT_OFFSET
	compound.add_child(shed_scale_root)
	_build_shed(shed_scale_root)
	var yard_root := Node3D.new()
	yard_root.name = "HomesteadYardLayout"
	yard_root.position = YARD_LAYOUT_OFFSET
	compound.add_child(yard_root)
	var garden_root := Node3D.new()
	garden_root.name = "HomesteadGardenLayout"
	garden_root.position = GARDEN_LAYOUT_OFFSET
	garden_root.rotation.y = deg_to_rad(GARDEN_YAW_DEGREES)
	yard_root.add_child(garden_root)
	_build_garden(garden_root)
	var fence_root := Node3D.new()
	fence_root.name = "HomesteadFenceLayout"
	fence_root.position = FENCE_LAYOUT_OFFSET
	yard_root.add_child(fence_root)
	_build_fence(fence_root)
	_build_lantern(fence_root, Vector3(-0.437, 2.0, -1.085))
	_build_lantern(fence_root, Vector3(7.6975, 2.0, -2.445))
	_build_lantern(fence_root, Vector3(4.0, 2.0, -0.2775))
	_build_stone_waymarker(fence_root, Vector3(7.6105, 2.0, 0.0625))


func _build_shed(parent: Node3D) -> void:
	var shed_root := Node3D.new()
	shed_root.name = "DetachedShed"
	shed_root.position = Vector3(-4.0, 0.0, -1.5)
	parent.add_child(shed_root)
	_add_visual_box(shed_root, "ShedFoundation", Vector3(-3.0, 2.13, -3.2), Vector3(2.85, 0.26, 2.65), _materials[&"stone"])
	_add_static_box(shed_root, "ShedWalls", Vector3(-3.0, 3.0, -3.2), Vector3(2.4, 2.0, 2.2), _materials[&"wood"])
	_add_visual_box(shed_root, "ShedDoor", Vector3(-3.0, 2.85, -2.08), Vector3(0.8, 1.45, 0.16), _materials[&"wood_dark"])
	_add_visual_box(shed_root, "ShedStep", Vector3(-3.0, 2.18, -1.78), Vector3(1.35, 0.24, 0.55), _materials[&"stone_light"])
	_add_visual_box(shed_root, "ShedBench", Vector3(-1.35, 2.34, -2.25), Vector3(1.25, 0.18, 0.5), _materials[&"wood"])
	_add_visual_box(shed_root, "ShedBenchLeg", Vector3(-1.72, 2.16, -2.25), Vector3(0.16, 0.42, 0.16), _materials[&"wood_dark"])
	_add_visual_box(shed_root, "ShedBenchLeg", Vector3(-0.98, 2.16, -2.25), Vector3(0.16, 0.42, 0.16), _materials[&"wood_dark"])
	for shed_row: int in range(5):
		for shed_column: int in range(5):
			var shed_x: float = -4.3 + float(shed_row) * 0.65
			var shed_z: float = -4.45 + float(shed_column) * 0.62
			var shed_y: float = 4.1 + (0.18 if shed_row in [1, 2, 3] else 0.0) + (0.18 if shed_row == 2 else 0.0)
			_add_visual_box(shed_root, "ShedRoofTile", Vector3(shed_x, shed_y, shed_z), Vector3(0.72, 0.22, 0.7), _materials[&"teal"] if (shed_row + shed_column) % 4 != 0 else _materials[&"teal_dark"])
	for corner_x: float in [-4.08, -1.92]:
		for corner_z: float in [-4.18, -2.22]:
			_add_visual_box(shed_root, "ShedCornerPost", Vector3(corner_x, 3.0, corner_z), Vector3(0.22, 2.1, 0.22), _materials[&"wood_dark"])
	_add_flat_shadow(shed_root, Vector3(-3.0, 2.066, -3.2), Vector2(1.8, 1.5))


func _build_garden(parent: Node3D) -> void:
	var garden_center_x: float = 6.5
	var garden_center_z: float = 0.25
	# A single recessed soil bed keeps the cultivated plot readable as one
	# authored rectangle. The three planted rows sit just above it; their narrow
	# soil strips provide furrow relief without breaking the bed into fragments.
	_add_visual_box(
		parent,
		"GardenBedBase",
		Vector3(garden_center_x, 2.06, garden_center_z),
		Vector3(
			4.1 * GARDEN_WIDTH_SCALE,
			0.12,
			2.7 * GARDEN_DEPTH_SCALE
		),
		_materials[&"earth"]
	)
	for row: int in range(3):
		var unscaled_row_z: float = 1.0 - float(row) * 0.75
		var row_z: float = garden_center_z + (unscaled_row_z - garden_center_z) * GARDEN_DEPTH_SCALE
		_add_visual_box(parent, "GardenSoil", Vector3(garden_center_x, 2.1, row_z), Vector3(4.1 * GARDEN_WIDTH_SCALE, 0.16, 0.58 * GARDEN_DEPTH_SCALE), _materials[&"earth"])
		for plant: int in range(5):
			var unscaled_plant_x: float = 5.05 + float(plant) * 0.72
			var plant_x: float = garden_center_x + (unscaled_plant_x - garden_center_x) * GARDEN_WIDTH_SCALE
			var plant_height: float = 0.3 + float(posmod(row * 5 + plant * 3, 4)) * 0.07
			var plant_tone: Material = _materials[&"leaf_light"] if (row + plant) % 3 == 0 else _materials[&"leaf"]
			_add_visual_box(parent, "GardenPlant", Vector3(plant_x, 2.15 + plant_height * 0.5, row_z), Vector3(0.3, plant_height, 0.3), plant_tone)
			_add_visual_box(parent, "GardenPlantLobe", Vector3(plant_x + 0.12, 2.18 + plant_height * 0.44, row_z - 0.1), Vector3(0.2, plant_height * 0.68, 0.2), _materials[&"leaf_dark"] if plant % 4 == 0 else plant_tone)
			if (row + plant) % 3 != 1:
				var crop_tone: Material = _materials[&"flower"] if (row + plant) % 2 == 0 else _materials[&"wheat_light"]
				_add_visual_box(parent, "GardenCrop", Vector3(plant_x - 0.08, 2.21 + plant_height, row_z + 0.08), Vector3(0.16, 0.14, 0.16), crop_tone)
	var garden_min_z: float = garden_center_z + (-1.1 - garden_center_z) * GARDEN_DEPTH_SCALE
	var garden_max_z: float = garden_center_z + (1.6 - garden_center_z) * GARDEN_DEPTH_SCALE
	for x_value: float in [garden_center_x - 2.0 * GARDEN_WIDTH_SCALE, garden_center_x + 2.0 * GARDEN_WIDTH_SCALE]:
		for z_value: float in [garden_min_z, garden_max_z]:
			_add_static_box(parent, "GardenPost", Vector3(x_value, 2.38, z_value), Vector3(0.2, 0.76, 0.2), _materials[&"wood_dark"])
		for rail_y: float in [2.26, 2.5]:
			_add_static_box(parent, "GardenSideRail", Vector3(x_value, rail_y, garden_center_z), Vector3(0.14, 0.14, 2.7 * GARDEN_DEPTH_SCALE), _materials[&"wood"])
	for z_value: float in [garden_min_z, garden_max_z]:
		for rail_y: float in [2.26, 2.5]:
			_add_static_box(parent, "GardenEndRail", Vector3(garden_center_x, rail_y, z_value), Vector3(4.18 * GARDEN_WIDTH_SCALE, 0.14, 0.14), _materials[&"wood"])


func _build_fence(parent: Node3D) -> void:
	var fence_center_x: float = 4.0
	var fence_center_z: float = -4.4
	var fence_min_x: float = fence_center_x + (-2.0 - fence_center_x) * FENCE_WIDTH_SCALE
	var fence_max_x: float = fence_center_x + (10.0 - fence_center_x) * FENCE_WIDTH_SCALE + FENCE_EAST_EXTENSION
	var fence_north_z: float = fence_center_z + (-10.2 - fence_center_z) * FENCE_DEPTH_SCALE
	var fence_south_z: float = fence_center_z + (1.4 - fence_center_z) * FENCE_DEPTH_SCALE
	for post_index: int in range(7):
		var x_value: float = lerpf(fence_min_x, fence_max_x, float(post_index) / 6.0)
		_add_static_box(parent, "FencePost", Vector3(x_value, 2.65, fence_north_z), Vector3(0.22, 1.3, 0.22), _materials[&"wood_dark"])
		_add_static_box(parent, "FencePost", Vector3(x_value, 2.65, fence_south_z), Vector3(0.22, 1.3, 0.22), _materials[&"wood_dark"])
	_add_static_box(
		parent,
		"FenceNorth",
		Vector3((fence_min_x + fence_max_x) * 0.5, 2.73, fence_north_z),
		Vector3(fence_max_x - fence_min_x, 0.18, 0.18),
		_materials[&"wood"]
	)
	# Preserve a physical two-metre gate around the courtyard entry instead of
	# running the southern rail through the trail junction.
	var gate_min_x: float = fence_center_x + (0.0 - fence_center_x) * FENCE_WIDTH_SCALE
	var gate_max_x: float = fence_center_x + (2.0 - fence_center_x) * FENCE_WIDTH_SCALE
	_add_static_box(parent, "FenceSouthLeft", Vector3((fence_min_x + gate_min_x) * 0.5, 2.73, fence_south_z), Vector3(gate_min_x - fence_min_x, 0.18, 0.18), _materials[&"wood"])
	_add_static_box(parent, "FenceSouthRight", Vector3((gate_max_x + fence_max_x) * 0.5, 2.73, fence_south_z), Vector3(fence_max_x - gate_max_x, 0.18, 0.18), _materials[&"wood"])
	for post_index: int in range(7):
		var z_value: float = lerpf(fence_north_z, fence_south_z, float(post_index) / 6.0)
		_add_static_box(parent, "FencePost", Vector3(fence_max_x, 2.65, z_value), Vector3(0.22, 1.3, 0.22), _materials[&"wood_dark"])
	_add_static_box(parent, "FenceEast", Vector3(fence_max_x, 2.73, fence_center_z), Vector3(0.18, 0.18, fence_south_z - fence_north_z), _materials[&"wood"])


func _build_lantern(parent: Node3D, base_position: Vector3) -> void:
	var lantern_parts: Array[MeshInstance3D] = [
		_add_visual_box(parent, "LanternFoundation", base_position + Vector3(0.0, 0.15, 0.0), Vector3(0.82, 0.3, 0.82), _materials[&"stone"]),
		_add_visual_box(parent, "LanternPlinth", base_position + Vector3(0.0, 0.42, 0.0), Vector3(0.56, 0.28, 0.56), _materials[&"stone_light"]),
		_add_visual_box(parent, "LanternPost", base_position + Vector3(0.0, 1.35, 0.0), Vector3(0.28, 1.65, 0.28), _materials[&"wood_dark"]),
		_add_visual_box(parent, "LanternGlow", base_position + Vector3(0.0, 2.16, 0.0), Vector3(0.5, 0.58, 0.5), _materials[&"gold"]),
		_add_visual_box(parent, "LanternFrame", base_position + Vector3(0.0, 2.16, 0.0), Vector3(0.64, 0.12, 0.64), _materials[&"black"]),
		_add_visual_box(parent, "LanternCap", base_position + Vector3(0.0, 2.52, 0.0), Vector3(0.86, 0.2, 0.86), _materials[&"wood_dark"]),
		_add_visual_box(parent, "LanternRoof", base_position + Vector3(0.0, 2.72, 0.0), Vector3(0.52, 0.2, 0.52), _materials[&"roof_dark"]),
	]
	# Tall, narrow voxel lamps create severe triangular sun shadows at this fixed
	# camera angle. Preserve their 3D geometry while grounding them with a compact
	# authored contact shadow that cannot tear across the courtyard route.
	for lantern_part: MeshInstance3D in lantern_parts:
		lantern_part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_flat_shadow(parent, base_position + Vector3(0.0, 0.066, 0.0), Vector2(0.82, 0.62))


func _build_stone_waymarker(parent: Node3D, base_position: Vector3) -> void:
	var foundation := _add_static_box(parent, "WaymarkerFoundation", base_position + Vector3(0.0, 0.22, 0.0), Vector3(1.35, 0.44, 1.35), _materials[&"stone"])
	var waymarker_parts: Array[MeshInstance3D] = [
		foundation.get_child(0) as MeshInstance3D,
		_add_visual_box(parent, "WaymarkerPlinth", base_position + Vector3(0.0, 0.55, 0.0), Vector3(1.0, 0.3, 1.0), _materials[&"stone_light"]),
		_add_visual_box(parent, "WaymarkerColumn", base_position + Vector3(0.0, 1.35, 0.0), Vector3(0.72, 1.5, 0.72), _materials[&"cliff_mid"]),
		_add_visual_box(parent, "WaymarkerInset", base_position + Vector3(0.0, 1.48, -0.39), Vector3(0.42, 0.58, 0.08), _materials[&"black"]),
		_add_visual_box(parent, "WaymarkerGlow", base_position + Vector3(0.0, 1.48, -0.44), Vector3(0.24, 0.36, 0.08), _materials[&"gold"]),
		_add_visual_box(parent, "WaymarkerCollar", base_position + Vector3(0.0, 2.15, 0.0), Vector3(1.05, 0.28, 1.05), _materials[&"stone"]),
		_add_visual_box(parent, "WaymarkerCap", base_position + Vector3(0.0, 2.48, 0.0), Vector3(0.78, 0.4, 0.78), _materials[&"roof_dark"]),
		_add_visual_box(parent, "WaymarkerCrown", base_position + Vector3(0.0, 2.75, 0.0), Vector3(0.34, 0.22, 0.34), _materials[&"stone_light"]),
	]
	for waymarker_part: MeshInstance3D in waymarker_parts:
		waymarker_part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_flat_shadow(parent, base_position + Vector3(0.0, 0.066, 0.0), Vector2(1.15, 0.9))


func _build_wheat_field() -> void:
	var field := StaticBody3D.new()
	field.name = "WheatField"
	field.collision_layer = 2
	field.collision_mask = 1
	# Align the cultivated rectangle to the locked camera's ground-plane axes.
	# It remains genuine rotated 3D geometry, but its long edge now reads as the
	# broad horizontal field in the authored composition instead of a thin wedge.
	# The latest overview audit measured the surviving gold mass about five pixels
	# right and six pixels high. Move along the field's camera-horizontal local
	# axis; the asymmetric depth distribution below supplies the vertical correction.
	# Both remain real ground-plane placement rather than screen-facing artwork.
	field.position = Vector3(WHEAT_CENTER_X - 0.201, 0.0, WHEAT_CENTER_Z - 0.479)
	field.rotation.y = deg_to_rad(-34.785)
	field.add_to_group("homestead_3d_landmark")
	props_root.add_child(field)
	var field_shape := BoxShape3D.new()
	field_shape.size = Vector3(12.4, 1.45, 7.9)
	var field_collision := CollisionShape3D.new()
	field_collision.position = Vector3(0.0, WHEAT_TOP_HEIGHT + 0.72, 0.0)
	field_collision.shape = field_shape
	field.add_child(field_collision)
	var wheat_random := RandomNumberGenerator.new()
	wheat_random.seed = 0x6B1D3A
	for row: int in range(34):
		for column: int in range(52):
			# More numerous, finer stalks replace the coarse rods while preserving
			# the target's total gold occupancy. The mild eastward probability
			# gradient restores the measured four-pixel centroid shift without moving
			# the physical field, terrace, or collision volume.
			var x_amount: float = float(column) / 51.0
			var retention: float = lerpf(0.30, 0.52, x_amount)
			if wheat_random.randf() > retention:
				continue
			var jitter_x: float = wheat_random.randf_range(-0.12, 0.12)
			var x_value: float = -6.0 + float(column) * (12.0 / 51.0) + jitter_x
			# Independent continuous depth sampling forms small natural tufts and
			# eliminates the remaining screen-visible row bands. The column still
			# provides a stable lateral density gradient.
			# Preserve the accepted stalk count while extending the lower silhouette.
			# Positive local Z projects straight down under the locked camera because
			# this field's authored yaw aligns its local axes to the image plane.
			var z_value: float = wheat_random.randf_range(-3.25, 4.45)
			var height: float = wheat_random.randf_range(0.56, 0.88)
			var tone: Material = _materials[&"wheat_light"] if posmod(row * 3 + column * 5, 7) < 2 else _materials[&"wheat"]
			_add_visual_box(field, "WheatStalk", Vector3(x_value, WHEAT_TOP_HEIGHT + height * 0.5, z_value), Vector3(0.08, height, 0.08), tone)
			_add_visual_box(field, "WheatHead", Vector3(x_value, WHEAT_TOP_HEIGHT + height + 0.055, z_value), Vector3(0.14, 0.15, 0.14), tone)
	_add_flat_shadow(field, Vector3(0.0, WHEAT_TOP_HEIGHT + 0.066, 0.6), Vector2(11.8, 7.6))


func _build_forest_frame() -> void:
	var tree_positions := [
		Vector3(-16.5, 0.0, -23.0), Vector3(-15.0, 0.0, -21.0),
		Vector3(-10.0, 0.0, -24.0), Vector3(-10.0, 0.0, -18.0),
		Vector3(-5.0, 0.0, -30.0), Vector3(3.0, 0.0, -28.0), Vector3(10.5, 0.0, -33.0),
		Vector3(7.0, 0.0, -23.0), Vector3(20.0, 0.0, -18.0),
		Vector3(0.0, 0.0, -18.0), Vector3(-2.0, 0.0, -12.5),
		Vector3(15.5, 0.0, -22.0), Vector3(-14.0, 0.0, -14.0), Vector3(30.5, 0.0, -15.0),
		Vector3(24.0, 0.0, -10.0), Vector3(-10.0, 0.0, -8.0),
		Vector3(-16.0, 0.0, -6.0), Vector3(5.5, 0.0, -8.0), Vector3(24.0, 0.0, -6.0),
		Vector3(-11.0, 0.0, 3.0),
		Vector3(-15.5, 0.0, 0.0), Vector3(18.0, 0.0, 0.0), Vector3(-14.5, 0.0, 10.0),
		Vector3(14.5, 0.0, 10.2), Vector3(-16.5, 0.0, 22.0), Vector3(-11.0, 0.0, 24.0),
		Vector3(15.0, 0.0, 25.0), Vector3(17.0, 0.0, 30.5), Vector3(-16.0, 0.0, 32.0),
		Vector3(-12.0, 0.0, 31.0), Vector3(13.0, 0.0, 33.5), Vector3(-8.0, 0.0, 38.0),
		Vector3(1.0, 0.0, 38.5), Vector3(16.5, 0.0, 38.0),
		Vector3(24.0, 0.0, -28.0), Vector3(28.0, 0.0, -20.0), Vector3(29.5, 0.0, -10.0),
		Vector3(27.0, 0.0, 0.0), Vector3(24.0, 0.0, 8.0), Vector3(27.0, 0.0, 25.0),
		Vector3(23.0, 0.0, 32.0), Vector3(29.0, 0.0, 39.0),
	]
	for tree_position: Vector3 in tree_positions:
		if _is_in_river(Vector2(tree_position.x, tree_position.z), 1.1):
			continue
		_build_tree(tree_position.x, tree_position.z)
	var rock_positions := [Vector3(-11.0, 0.0, -9.0), Vector3(9.0, 0.0, -11.0), Vector3(-10.0, 0.0, 10.0), Vector3(11.0, 0.0, 23.0), Vector3(-12.0, 0.0, 32.0)]
	for rock_position: Vector3 in rock_positions:
		var height: float = _ground_height(rock_position.x, rock_position.z)
		_build_moss_rock(Vector3(rock_position.x, height, rock_position.z), int(absf(rock_position.x + rock_position.z)))
	_build_landmark_boulder(Vector3(4.0, 0.0, 11.8))


func _build_tree(x_value: float, z_value: float) -> void:
	var floor_height: float = _ground_height(x_value, z_value)
	var tree := Node3D.new()
	tree.name = "VoxelTree"
	props_root.add_child(tree)
	var variant: int = posmod(int(round(absf(x_value * 7.0 + z_value * 11.0))), 5)
	var trunk_height: float = 3.3 + float(variant) * 0.1
	var canopy_scale: float = 0.82 + float(variant) * 0.035
	var canopy_stretch_x: float = 0.86 + float(posmod(variant * 3, 5)) * 0.055
	var canopy_stretch_z: float = 1.04 - float(posmod(variant * 2, 5)) * 0.04
	var canopy_vertical_scale: float = 0.9 + float(posmod(variant + 2, 5)) * 0.025
	_add_static_box(tree, "TreeTrunk", Vector3(x_value, floor_height + trunk_height * 0.5, z_value), Vector3(0.72, trunk_height, 0.72), _materials[&"wood_dark"])
	for root_index: int in range(4):
		var root_angle: float = float(root_index) * TAU / 4.0 + float(variant) * 0.17
		_add_visual_box(
			tree,
			"TreeRoot",
			Vector3(x_value + cos(root_angle) * 0.55, floor_height + 0.18, z_value + sin(root_angle) * 0.55),
			Vector3(0.75 if root_index % 2 == 0 else 0.42, 0.32, 0.42 if root_index % 2 == 0 else 0.75),
			_materials[&"wood_dark"]
		)
	_add_visual_box(tree, "TreeBranch", Vector3(x_value - 0.55, floor_height + 2.85, z_value), Vector3(1.35, 0.34, 0.34), _materials[&"wood"])
	_add_visual_box(tree, "TreeBranch", Vector3(x_value + 0.3, floor_height + 3.1, z_value - 0.52), Vector3(0.34, 0.34, 1.25), _materials[&"wood"])
	var canopy_random := RandomNumberGenerator.new()
	canopy_random.seed = int(absf(x_value * 13007.0 + z_value * 7919.0)) + variant * 991
	var cluster_count: int = 22 + variant
	for cluster_index: int in range(cluster_count):
		var height_band: int = cluster_index % 4
		var layer_radius: float = 2.0 - float(height_band) * 0.3
		var cluster_angle: float = canopy_random.randf_range(0.0, TAU)
		var cluster_radius: float = sqrt(canopy_random.randf()) * layer_radius
		var cluster := Vector3(
			cos(cluster_angle) * cluster_radius * canopy_scale * canopy_stretch_x,
			(3.05 + float(height_band) * 0.62 + canopy_random.randf_range(-0.2, 0.22)) * canopy_vertical_scale,
			sin(cluster_angle) * cluster_radius * canopy_scale * canopy_stretch_z
		)
		var tone: Material = _materials[&"leaf"]
		if cluster_index % 7 == 0:
			tone = _materials[&"leaf_light"]
		elif cluster_index % 5 == 0:
			tone = _materials[&"leaf_dark"]
		var cluster_size := Vector3(
			canopy_random.randf_range(0.68, 1.04) * canopy_scale * canopy_stretch_x,
			canopy_random.randf_range(0.60, 0.88) * canopy_scale,
			canopy_random.randf_range(0.68, 1.04) * canopy_scale * canopy_stretch_z
		)
		_add_visual_box(tree, "LeafVoxel", Vector3(x_value, floor_height, z_value) + cluster, cluster_size, tone)
	var core_clusters := [
		Vector3(-0.58, 3.12, 0.22), Vector3(0.46, 3.18, -0.42),
		Vector3(0.0, 3.72, 0.0), Vector3(-0.5, 4.18, -0.28),
		Vector3(0.48, 4.42, 0.3), Vector3(0.12, 5.02, -0.08),
	]
	for core_index: int in range(core_clusters.size()):
		var core_offset: Vector3 = core_clusters[core_index]
		var core_tone: Material = _materials[&"leaf_light"] if core_index == 5 and variant % 2 == 0 else _materials[&"leaf"]
		_add_visual_box(
			tree,
			"LeafCore",
			Vector3(x_value, floor_height, z_value) + Vector3(core_offset.x * canopy_stretch_x, core_offset.y * canopy_vertical_scale, core_offset.z * canopy_stretch_z),
			Vector3(1.05 * canopy_stretch_x, 0.88, 1.05 * canopy_stretch_z) * canopy_scale,
			core_tone
		)
	_add_visual_box(tree, "LeafCrown", Vector3(x_value + 0.18, floor_height + 5.58 * canopy_vertical_scale, z_value - 0.12), Vector3(0.88 * canopy_stretch_x, 0.76, 0.88 * canopy_stretch_z) * canopy_scale, _materials[&"leaf_light"] if variant % 2 == 0 else _materials[&"leaf"])
	_add_flat_shadow(tree, Vector3(x_value, floor_height + 0.066, z_value), Vector2(2.3 * canopy_scale * canopy_stretch_x, 1.5 * canopy_scale * canopy_stretch_z))


func _build_ground_details() -> void:
	var detail_positions := [
		Vector3(-12.0, 0, -18.0), Vector3(-5.0, 0, -17.0), Vector3(12.0, 0, -10.0),
		Vector3(-12.0, 0, -4.0), Vector3(12.0, 0, 0.0), Vector3(-8.0, 0, 7.0),
		Vector3(10.0, 0, 10.0), Vector3(-12.0, 0, 22.0), Vector3(12.0, 0, 21.0),
		Vector3(-8.0, 0, 26.0), Vector3(9.0, 0, 27.0), Vector3(-12.0, 0, 34.0),
		Vector3(-14.0, 0, -11.0), Vector3(-5.0, 0, -11.5), Vector3(14.0, 0, -16.0),
		Vector3(14.0, 0, -4.0), Vector3(-13.0, 0, 1.0), Vector3(8.0, 0, 1.5),
		Vector3(-8.0, 0, 7.8), Vector3(8.0, 0, 7.5), Vector3(-14.0, 0, 24.0),
		Vector3(14.0, 0, 25.0), Vector3(-4.0, 0, 21.0), Vector3(10.0, 0, 34.0),
		Vector3(-14.0, 0, 38.0), Vector3(4.0, 0, 38.0),
		Vector3(-16.0, 0, 11.1), Vector3(-12.0, 0, 11.2), Vector3(-8.0, 0, 11.0),
		Vector3(9.0, 0, 11.1), Vector3(13.0, 0, 11.0), Vector3(16.0, 0, 11.2),
		Vector3(-15.0, 0, 18.2), Vector3(-10.0, 0, 18.15), Vector3(-5.0, 0, 18.1),
		Vector3(10.0, 0, 18.2), Vector3(14.5, 0, 18.15),
		Vector3(-7.2, 0, -10.0), Vector3(-6.4, 0, -5.2),
		Vector3(-5.1, 0, 0.6), Vector3(-8.1, 0, 2.8),
		Vector3(5.8, 0, -13.4), Vector3(8.0, 0, -11.8),
		Vector3(10.2, 0, -1.8), Vector3(13.2, 0, -13.0),
	]
	for index: int in range(detail_positions.size()):
		var detail_position: Vector3 = detail_positions[index] as Vector3
		var floor_height: float = _ground_height(detail_position.x, detail_position.z)
		_build_shrub_cluster(Vector3(detail_position.x, floor_height, detail_position.z), 1.0, index)


func _build_homestead_dressing() -> void:
	# The reference nests the cottage in intentional vegetation instead of
	# leaving a clean procedural exclusion rectangle around the compound.
	var shrub_positions := PackedVector2Array([
		Vector2(-4.1, -0.7), Vector2(-3.6, 3.5), Vector2(-1.7, 5.4),
		Vector2(1.4, -3.1), Vector2(5.2, -4.7), Vector2(10.8, -4.7),
		Vector2(14.7, -2.4), Vector2(14.8, 4.5), Vector2(12.7, 7.65),
		Vector2(8.3, 7.72), Vector2(3.2, 7.55), Vector2(-3.0, 7.25),
	])
	for index: int in range(shrub_positions.size()):
		var point: Vector2 = shrub_positions[index] + Vector2(0.0, -1.5)
		_build_shrub_cluster(Vector3(point.x, _ground_height(point.x, point.y), point.y), 0.62 + float(index % 3) * 0.12, 410 + index)
	# Compact clusters fill the target's planted inner-yard pockets without adding
	# more mass to the already dense perimeter or entering a route clearance.
	_build_shrub_cluster(Vector3(3.32, _ground_height(3.32, -1.92), -1.92), 0.72, 430)
	_build_shrub_cluster(Vector3(11.30, _ground_height(11.30, 1.75), 1.75), 0.38, 432)
	_build_shrub_cluster(Vector3(7.50, _ground_height(7.50, -6.15), -6.15), 0.50, 431)
	_build_shrub_cluster(Vector3(11.15, _ground_height(11.15, 5.70), 5.70), 0.42, 433)
	var paving_positions := PackedVector2Array([
		Vector2(-1.55, 0.05), Vector2(-1.0, 0.85), Vector2(-0.45, 1.65),
		Vector2(2.45, 0.45), Vector2(3.3, 1.15), Vector2(7.4, 4.65),
		Vector2(8.25, 4.85), Vector2(9.15, 4.72), Vector2(13.75, 1.25),
	])
	for index: int in range(paving_positions.size()):
		var point: Vector2 = paving_positions[index] + Vector2(0.0, -1.5)
		var height: float = _ground_height(point.x, point.y)
		var size := Vector3(0.52 + float(index % 3) * 0.09, 0.1, 0.42 + float((index + 1) % 3) * 0.08)
		_add_visual_box(props_root, "YardPavingStone", Vector3(point.x, height + 0.07, point.y), size, _materials[&"stone"] if index % 2 == 0 else _materials[&"stone_light"])
	var flower_positions := PackedVector2Array([
		Vector2(2.9, 6.95), Vector2(3.35, 7.18), Vector2(5.35, 7.62),
		Vector2(6.15, 7.48), Vector2(7.2, 7.68), Vector2(8.2, 7.5),
		Vector2(9.85, 7.72), Vector2(10.35, 7.58), Vector2(11.45, 7.42),
		Vector2(12.15, 7.62), Vector2(13.15, 7.3), Vector2(14.1, 6.85),
	])
	for index: int in range(flower_positions.size()):
		var point: Vector2 = flower_positions[index] + Vector2(0.0, -1.5)
		var height: float = _ground_height(point.x, point.y)
		var flower_height: float = 0.24 + float(index % 2) * 0.06
		_add_visual_box(props_root, "YardFlowerStem", Vector3(point.x, height + flower_height * 0.5, point.y), Vector3(0.08, flower_height, 0.08), _materials[&"leaf_dark"])
		_add_visual_box(props_root, "YardWhiteFlower", Vector3(point.x, height + flower_height + 0.05, point.y), Vector3(0.21, 0.15, 0.21), _materials[&"flower_white"])
		if index % 2 == 0:
			_add_visual_box(props_root, "YardFlowerCompanion", Vector3(point.x + 0.22, height + flower_height * 0.86, point.y - 0.16), Vector3(0.16, 0.13, 0.16), _materials[&"flower"])


func _build_homestead_cliff_dressing() -> void:
	var cliff_clusters := [
		Vector3(-4.0, 4.08, 3.1), Vector3(2.2, 4.08, 7.55),
		Vector3(6.9, 4.08, 7.72), Vector3(8.7, 4.08, 7.65),
		Vector3(11.6, 4.08, 7.45), Vector3(14.2, 4.08, 5.15),
		Vector3(6.3, 4.08, 5.45), Vector3(5.35, 4.08, 7.8),
		Vector3(0.0, 0.08, 6.15), Vector3(4.8, 0.08, 8.95),
	]
	for index: int in range(cliff_clusters.size()):
		var cluster_scale: float = 1.0 + float(index % 3) * 0.14
		if index in [2, 6, 7]:
			cluster_scale = 0.24
		_build_shrub_cluster(cliff_clusters[index], cluster_scale, 560 + index)
	# Dense shoulders frame the stair without entering its reusable clearance
	# corridor, matching the planted terrace cut in the approved composition.
	_build_shrub_cluster(Vector3(6.95, 4.08, 7.3), 0.24, 566)
	_build_shrub_cluster(Vector3(3.05, 4.08, 4.65), 0.92, 567)
	_build_shrub_cluster(Vector3(1.2, 4.08, 5.2), 0.78, 570)
	_build_shrub_cluster(Vector3(9.8, 4.08, 7.7), 0.86, 571)
	_build_shrub_cluster(Vector3(-2.35, 0.08, 7.15), 0.82, 568)
	_build_shrub_cluster(Vector3(0.35, 0.08, 8.1), 0.9, 569)
	_build_moss_rock(Vector3(12.9, 4.08, 6.55), 572)
	# A compact ribbon of small 3D shrubs turns the terrace cut into the planted,
	# irregular lip visible in the target. The cluster helper preserves the stair
	# clearance corridor automatically.
	for lip_index: int in range(11):
		var lip_x: float = -1.2 + float(lip_index) * 1.48
		var lip_z: float = _main_edge_z(lip_x)
		var lip_scale: float = 0.52 + float(posmod(lip_index * 5, 4)) * 0.08
		var upper_lip_scale: float = 0.22 if lip_index in [4, 5, 6] else lip_scale
		_build_shrub_cluster(Vector3(lip_x, 4.08, lip_z - 0.42), upper_lip_scale, 610 + lip_index)
		if lip_index % 2 == 0:
			_build_shrub_cluster(Vector3(lip_x + 0.42, 0.08, lip_z + 0.62), lip_scale * 0.72, 640 + lip_index)
	# Broad protrusions interrupt the ruler-flat retaining face without creating a
	# second collision owner or a dense wallpaper of tiny masonry.
	var relief_dark: Array[Transform3D] = []
	var relief_light: Array[Transform3D] = []
	for relief_index: int in range(-23, 24):
		var relief_x: float = float(relief_index) * 0.72
		if relief_x > -4.8 and relief_x < -0.8:
			continue
		var relief_edge_z: float = _main_edge_z(relief_x)
		var relief_row: int = posmod(relief_index * 7, 6)
		var relief_size := Vector3(
			0.48 + float(posmod(relief_index * 3, 4)) * 0.12,
			0.34 + float(posmod(relief_index * 5, 3)) * 0.08,
			0.24 + float(posmod(relief_index * 11, 3)) * 0.06
		)
		var relief_origin := Vector3(
			relief_x + (0.16 if relief_row % 2 == 0 else -0.1),
			0.46 + float(relief_row) * 0.61,
			relief_edge_z - 0.36
		)
		var relief_transform := Transform3D(Basis.IDENTITY.scaled(relief_size), relief_origin)
		if relief_index % 4 == 0:
			relief_light.append(relief_transform)
		else:
			relief_dark.append(relief_transform)
	_add_multimesh_boxes(terrain_root, "HomesteadCliffReliefDark", relief_dark, _materials[&"cliff_dark"])
	_add_multimesh_boxes(terrain_root, "HomesteadCliffReliefLight", relief_light, _materials[&"cliff_mid"])


func _build_cliff_vegetation() -> void:
	var main_lip_x_values: Array[float] = [
		-16.0, -13.5, -11.0, -8.5, -6.0, -3.5, -1.0,
		1.5, 4.5, 7.0, 10.0, 13.0, 16.0, 19.0, 22.0,
	]
	for index: int in range(main_lip_x_values.size()):
		var x_value: float = main_lip_x_values[index]
		var edge_z: float = _main_edge_z(x_value)
		_build_shrub_cluster(Vector3(x_value, 4.08, edge_z - 0.55), 0.86 if index % 3 == 0 else 0.68, 230 + index)
		if index % 3 != 0:
			_build_shrub_cluster(Vector3(x_value + 0.55, 0.08, edge_z + 0.62), 0.44 + float(index % 2) * 0.08, 260 + index)
	var wheat_lip_positions := [
		Vector3(WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.25),
		Vector3(WHEAT_CENTER_X - 3.8, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.1),
		Vector3(WHEAT_CENTER_X + 3.2, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.15),
		Vector3(WHEAT_CENTER_X + WHEAT_TERRACE_HALF_WIDTH - 0.2, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.3),
		Vector3(WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH + 0.4, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 + 0.25),
		Vector3(WHEAT_CENTER_X + WHEAT_TERRACE_HALF_WIDTH - 0.7, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 + 0.2),
	]
	for index: int in range(wheat_lip_positions.size()):
		_build_shrub_cluster(wheat_lip_positions[index], 0.62, 290 + index)
	var wheat_border_positions := [
		Vector3(WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH + 0.2, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 + 0.25),
		Vector3(WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH + 0.25, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z),
		Vector3(WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH + 0.3, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.25),
		Vector3(WHEAT_CENTER_X - 3.8, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 + 0.1),
		Vector3(WHEAT_CENTER_X + 2.8, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 + 0.15),
		Vector3(WHEAT_CENTER_X + WHEAT_TERRACE_HALF_WIDTH - 0.25, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 + 1.2),
		Vector3(WHEAT_CENTER_X + WHEAT_TERRACE_HALF_WIDTH - 0.2, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z),
		Vector3(WHEAT_CENTER_X + WHEAT_TERRACE_HALF_WIDTH - 0.25, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.2),
		Vector3(WHEAT_CENTER_X - 4.8, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.05),
		Vector3(WHEAT_CENTER_X + 3.5, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 - 0.05),
	]
	for index: int in range(wheat_border_positions.size()):
		_build_shrub_cluster(wheat_border_positions[index], 0.48 + float(index % 3) * 0.1, 740 + index)
	_build_moss_rock(Vector3(WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH - 0.15, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z - 2.3), 760)
	_build_moss_rock(Vector3(WHEAT_CENTER_X + WHEAT_TERRACE_HALF_WIDTH + 0.15, WHEAT_TOP_HEIGHT + 0.08, WHEAT_CENTER_Z + 1.0), 761)


func _build_micro_ground_cover() -> void:
	var cover_positions := [
		Vector3(-15, 0, -22), Vector3(-7, 0, -22), Vector3(-3, 0, -20), Vector3(15, 0, -21),
		Vector3(-13, 0, -16), Vector3(-6, 0, -15), Vector3(0, 0, -11), Vector3(13, 0, -12),
		Vector3(-15, 0, -8), Vector3(-11, 0, -6), Vector3(11, 0, -7), Vector3(15, 0, -3),
		Vector3(-14, 0, 0), Vector3(-10, 0, 2), Vector3(9, 0, 0), Vector3(14, 0, 1),
		Vector3(-16, 0, 7), Vector3(-11, 0, 8), Vector3(-7, 0, 11.3), Vector3(-2, 0, 11.2),
		Vector3(8, 0, 11), Vector3(12, 0, 10.5), Vector3(16, 0, 9),
		Vector3(-16, 0, 18.1), Vector3(-11, 0, 18.35), Vector3(-5, 0, 18.1), Vector3(1, 0, 18.25),
		Vector3(10, 0, 18.2), Vector3(15, 0, 18.3), Vector3(-14, 0, 23), Vector3(-8, 0, 24),
		Vector3(-2, 0, 19.5), Vector3(13, 0, 20.0), Vector3(16, 0, 24), Vector3(-16, 0, 27),
		Vector3(-10, 0, 31), Vector3(-4, 0, 28), Vector3(3, 0, 29), Vector3(14, 0, 31),
		Vector3(-15, 0, 36), Vector3(-8, 0, 35), Vector3(-2, 0, 38), Vector3(5, 0, 36),
		Vector3(15, 0, 37),
	]
	for index: int in range(cover_positions.size()):
		var cover_position: Vector3 = cover_positions[index]
		var floor_height: float = _ground_height(cover_position.x, cover_position.z)
		_build_shrub_cluster(Vector3(cover_position.x, floor_height, cover_position.z), 0.5 if index % 3 != 0 else 0.68, index + 71)
		if index % 2 == 0:
			var companion_offset := Vector3(0.65 if index % 4 == 0 else -0.55, 0.0, 0.42 if index % 3 == 0 else -0.38)
			_build_shrub_cluster(Vector3(cover_position.x, floor_height, cover_position.z) + companion_offset, 0.36, index + 151)


func _build_biome_scatter() -> void:
	var leaf_transforms: Array[Transform3D] = []
	var light_leaf_transforms: Array[Transform3D] = []
	var stone_transforms: Array[Transform3D] = []
	var flower_transforms: Array[Transform3D] = []
	var scatter_regions: Array[Rect2] = [
		Rect2(-31.0, -30.0, 13.0, 38.0),
		Rect2(-18.0, -30.0, 36.0, 18.0),
		Rect2(-18.0, -11.0, 12.0, 18.0),
		Rect2(10.0, -10.0, 8.0, 18.0),
		Rect2(-18.0, 22.0, 36.0, 17.0),
		Rect2(18.0, -30.0, 13.0, 38.0),
		Rect2(18.0, 22.0, 13.0, 17.0),
	]
	var random := RandomNumberGenerator.new()
	random.seed = 0xC071A6E
	var sample_index: int = 0
	for region: Rect2 in scatter_regions:
		for _sample: int in range(104):
			var x_value: float = random.randf_range(region.position.x, region.end.x)
			var z_value: float = random.randf_range(region.position.y, region.end.y)
			if not _is_scatter_clear(Vector2(x_value, z_value)):
				continue
			var floor_height: float = _ground_height(x_value, z_value)
			var cluster_radius: float = random.randf_range(0.22, 0.58)
			var voxel_count: int = random.randi_range(3, 6)
			for voxel_index: int in range(voxel_count):
				var angle: float = random.randf_range(0.0, TAU)
				var radius: float = random.randf_range(0.0, cluster_radius)
				var voxel_size := Vector3(
					random.randf_range(0.24, 0.48),
					random.randf_range(0.22, 0.55),
					random.randf_range(0.24, 0.48)
				)
				var origin := Vector3(
					x_value + cos(angle) * radius,
					floor_height + voxel_size.y * 0.5 + 0.04,
					z_value + sin(angle) * radius
				)
				var transform := Transform3D(Basis.IDENTITY.scaled(voxel_size), origin)
				if (sample_index + voxel_index) % 5 == 0:
					light_leaf_transforms.append(transform)
				else:
					leaf_transforms.append(transform)
			if sample_index % 5 == 0:
				var rock_size := Vector3(random.randf_range(0.35, 0.72), random.randf_range(0.18, 0.4), random.randf_range(0.3, 0.62))
				stone_transforms.append(Transform3D(Basis.IDENTITY.scaled(rock_size), Vector3(x_value + 0.75, floor_height + rock_size.y * 0.5, z_value - 0.35)))
			if sample_index % 7 == 0:
				var flower_size := Vector3.ONE * random.randf_range(0.12, 0.2)
				flower_transforms.append(Transform3D(Basis.IDENTITY.scaled(flower_size), Vector3(x_value - 0.22, floor_height + 0.42, z_value + 0.12)))
			sample_index += 1
	_add_multimesh_boxes(props_root, "BiomeLeaves", leaf_transforms, _materials[&"leaf"])
	_add_multimesh_boxes(props_root, "BiomeLightLeaves", light_leaf_transforms, _materials[&"leaf_light"])
	_add_multimesh_boxes(props_root, "BiomeStones", stone_transforms, _materials[&"stone"])
	_add_multimesh_boxes(props_root, "BiomeFlowers", flower_transforms, _materials[&"flower"])


func _is_scatter_clear(point: Vector2) -> bool:
	if _is_in_river(point, 0.75):
		return false
	for patch: Vector3 in [
		Vector3(-0.757687, 4.24309, 1.206675225),
		Vector3(-1.723715, 5.442652, 0.9),
		Vector3(-2.468737, 6.264397, 0.65),
	]:
		if point.distance_to(Vector2(patch.x, patch.y)) < patch.z + 0.45:
			return false
	if point.x > 0.5 and point.x < 16.0 and point.y > -12.0 and point.y < 7.5:
		return false
	if point.x > WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH - 0.5 and point.y > WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 - 0.5 and point.y < WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 + 0.5:
		return false
	var route_points := PackedVector2Array([
		Vector2(30.0, -55.0), Vector2(22.8, -41.4), Vector2(15.2, -29.1),
		Vector2(9.05, -20.05), Vector2(1.3, -13.2), Vector2(-1.05, -6.05),
		Vector2(0.0, -1.0), Vector2(-0.54512, 1.771445),
		Vector2(STAIR_APPROACH_START.x, STAIR_APPROACH_START.z),
		Vector2(NORTH_TRAIL_END.x, NORTH_TRAIL_END.z),
		Vector2(STAIR_BOTTOM.x, STAIR_BOTTOM.z),
		Vector2(-1.44512, 6.621445),
		Vector2(BRIDGE_NORTH.x, BRIDGE_NORTH.z),
		Vector2(BRIDGE_SOUTH.x, BRIDGE_SOUTH.z),
		Vector2(-4.2, 25.3), Vector2(-6.2, 31.0), Vector2(-9.2, 40.0),
	])
	for index: int in range(route_points.size() - 1):
		if _distance_to_segment(point, route_points[index], route_points[index + 1]) < 1.8:
			return false
	return true


func _is_in_river(point: Vector2, margin: float = 0.0) -> bool:
	if RiverShoreProfile.is_land_at_x(point.x):
		return false
	var shores: Vector2 = RiverShoreProfile.sample_effective_shores(point.x)
	return point.y > shores.x - margin and point.y < shores.y + margin


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment: Vector2 = segment_end - segment_start
	var length_squared: float = segment.length_squared()
	if is_zero_approx(length_squared):
		return point.distance_to(segment_start)
	var amount: float = clampf((point - segment_start).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(segment_start + segment * amount)


func _build_riverbank_foliage() -> void:
	var bank_x_values: Array[float] = [
		-27.0, -22.0, -17.0, -12.0, -7.0, -3.5, 3.0, 7.5, 12.0, 17.0, 22.0, 27.0,
	]
	var cluster_index: int = 0
	for side_index: int in range(2):
		var land_direction: float = -1.0 if side_index == 0 else 1.0
		for x_value: float in bank_x_values:
			if x_value > BRIDGE_NORTH.x - 2.2 and x_value < BRIDGE_NORTH.x + 2.2:
				continue
			if RiverShoreProfile.is_land_at_x(x_value):
				continue
			var shores: Vector2 = RiverShoreProfile.sample_effective_shores(x_value)
			var shore_z: float = shores.x if side_index == 0 else shores.y
			var bank_position := Vector3(x_value, 0.0, shore_z + land_direction * 0.22)
			_build_reed_cluster(bank_position, cluster_index)
			if cluster_index % 5 == 0:
				_build_moss_rock(bank_position + Vector3(0.55, 0.08, land_direction * 0.72), 700 + cluster_index)
			if cluster_index % 4 == 1:
				_build_shrub_cluster(
					bank_position + Vector3(-0.65, 0.08, land_direction * 1.15),
					0.55 + float(cluster_index % 3) * 0.07,
					760 + cluster_index
				)
			cluster_index += 1


func _build_shrub_cluster(base_position: Vector3, size_scale: float, variant: int) -> void:
	var stair_distance: float = _distance_to_segment(
		Vector2(base_position.x, base_position.z),
		Vector2(NORTH_TRAIL_END.x, NORTH_TRAIL_END.z),
		Vector2(STAIR_BOTTOM.x, STAIR_BOTTOM.z)
	)
	if stair_distance < STAIR_WIDTH * 0.95:
		return
	_add_flat_shadow(props_root, base_position + Vector3.UP * 0.045, Vector2(1.0, 0.65) * size_scale)
	for cluster_index: int in range(7):
		var angle: float = float(cluster_index) * TAU / 7.0 + float(variant) * 0.37
		var radius: float = (0.22 + float(cluster_index % 3) * 0.15) * size_scale
		var height: float = (0.34 + float((cluster_index + variant) % 3) * 0.11) * size_scale
		var tone: Material = _materials[&"leaf_light"] if (cluster_index + variant) % 4 == 0 else _materials[&"leaf"]
		if (cluster_index + variant) % 6 == 0:
			tone = _materials[&"leaf_dark"]
		_add_visual_box(
			props_root,
			"ShrubVoxel",
			base_position + Vector3(cos(angle) * radius, height * 0.5, sin(angle) * radius),
			Vector3(0.52 * size_scale, height, 0.52 * size_scale),
			tone
		)
	if variant % 3 == 0:
		_add_visual_box(props_root, "ShrubFlower", base_position + Vector3(0.12, 0.48 * size_scale, -0.08), Vector3.ONE * 0.17 * size_scale, _materials[&"flower"])


func _build_reed_cluster(base_position: Vector3, variant: int) -> void:
	for reed_index: int in range(7):
		var angle: float = float(reed_index) * 2.1 + float(variant)
		var radius: float = 0.2 + float(reed_index % 3) * 0.13
		var reed_height: float = 0.55 + float((reed_index * 5 + variant) % 4) * 0.16
		var reed_position := base_position + Vector3(cos(angle) * radius, reed_height * 0.5, sin(angle) * radius)
		_add_visual_box(props_root, "RiverReed", reed_position, Vector3(0.11, reed_height, 0.11), _materials[&"reed"])
		if reed_index % 2 == 0:
			_add_visual_box(props_root, "RiverReedTip", reed_position + Vector3.UP * (reed_height * 0.56), Vector3(0.17, 0.22, 0.17), _materials[&"reed_tip"])
	for stone_index: int in range(3):
		var stone_offset := Vector3(-0.55 + float(stone_index) * 0.5, 0.1, 0.32 if stone_index % 2 == 0 else -0.25)
		_add_visual_box(props_root, "RiverbankStone", base_position + stone_offset, Vector3(0.55, 0.22, 0.48), _materials[&"stone"] if stone_index != 1 else _materials[&"moss"])


func _build_moss_rock(base_position: Vector3, variant: int) -> void:
	_add_static_box(props_root, "MossRock", base_position + Vector3(0.0, 0.38, 0.0), Vector3(1.2, 0.75, 0.9), _materials[&"stone"])
	_add_visual_box(props_root, "MossRockCap", base_position + Vector3(-0.12, 0.77, -0.04), Vector3(0.86, 0.16, 0.66), _materials[&"moss"])
	if variant % 2 == 0:
		_add_visual_box(props_root, "MossRockChip", base_position + Vector3(0.62, 0.17, 0.25), Vector3(0.38, 0.32, 0.35), _materials[&"stone_light"])


func _build_landmark_boulder(base_position: Vector3) -> void:
	var core := _add_static_box(props_root, "LandmarkBoulder", base_position + Vector3(0.0, 0.66, 0.0), Vector3(2.0, 1.32, 1.62), _materials[&"boulder"])
	core.rotation.y = 0.24
	var shoulder := _add_visual_box(props_root, "LandmarkBoulderShoulder", base_position + Vector3(-0.98, 0.46, 0.26), Vector3(1.28, 0.92, 1.2), _materials[&"boulder"])
	shoulder.rotation.y = -0.32
	var rear_lobe := _add_visual_box(props_root, "LandmarkBoulderRearLobe", base_position + Vector3(0.74, 0.5, 0.38), Vector3(1.18, 1.0, 1.08), _materials[&"boulder"])
	rear_lobe.rotation.y = 0.48
	var crown := _add_visual_box(props_root, "LandmarkBoulderCrown", base_position + Vector3(0.08, 1.38, -0.08), Vector3(1.48, 0.5, 1.12), _materials[&"boulder_light"])
	crown.rotation.y = -0.18
	var moss_cap := _add_visual_box(props_root, "LandmarkBoulderMoss", base_position + Vector3(-0.1, 1.7, -0.06), Vector3(1.0, 0.16, 0.7), _materials[&"moss_light"])
	moss_cap.rotation.y = 0.12
	_add_visual_box(props_root, "LandmarkBoulderChip", base_position + Vector3(1.28, 0.22, -0.3), Vector3(0.58, 0.44, 0.5), _materials[&"stone"])
	_add_flat_shadow(props_root, base_position + Vector3.UP * 0.066, Vector2(2.8, 1.9))


func _build_water_hazards() -> void:
	_add_segmented_water_area(
		RiverShoreProfile.WEST_WATER_OWNER,
		RiverLayout.WORLD_MIN_X,
		RiverShoreProfile.WEST_OWNER_MAX_X
	)
	_add_segmented_water_area(
		RiverShoreProfile.EAST_WATER_OWNER,
		RiverShoreProfile.EAST_OWNER_MIN_X,
		RiverLayout.WORLD_MAX_X
	)


func _river_profile_ranges(min_x: float, max_x: float) -> Array[Vector2]:
	var cuts := PackedFloat32Array([min_x, max_x])
	for boundary: float in [
		RiverShoreProfile.FULL_OCCLUSION_MIN_X,
		RiverShoreProfile.FULL_OCCLUSION_MAX_X,
	]:
		if boundary > min_x and boundary < max_x:
			cuts.append(boundary)
	cuts.sort()
	var ranges: Array[Vector2] = []
	for index: int in range(cuts.size() - 1):
		ranges.append(Vector2(cuts[index], cuts[index + 1]))
	return ranges


func _add_segmented_water_area(area_name: StringName, min_x: float, max_x: float) -> void:
	var area := Area3D.new()
	area.name = area_name
	area.collision_layer = 4
	area.collision_mask = 1
	area.body_entered.connect(_on_water_body_entered)
	hazards_root.add_child(area)
	const HAZARD_STEP := 0.5
	const HAZARD_BANK_INSET := 0.275
	const HAZARD_TOP_Y := 0.9
	const HAZARD_BOTTOM_Y := -1.1
	var shape_index: int = 0
	for x_range: Vector2 in _river_profile_ranges(min_x, max_x):
		var samples: PackedVector4Array = _river_geometry_samples(
			x_range.x,
			x_range.y,
			HAZARD_STEP
		)
		for index: int in range(samples.size() - 1):
			var left: Vector4 = samples[index]
			var right: Vector4 = samples[index + 1]
			var center_x: float = (left.x + right.x) * 0.5
			if RiverShoreProfile.is_land_at_x(center_x):
				continue
			var left_north: float = left.y + HAZARD_BANK_INSET
			var left_south: float = left.z - HAZARD_BANK_INSET
			var right_north: float = right.y + HAZARD_BANK_INSET
			var right_south: float = right.z - HAZARD_BANK_INSET
			if (
				left_south - left_north < RiverShoreProfile.MIN_PASSABLE_WATER_WIDTH
				or right_south - right_north < RiverShoreProfile.MIN_PASSABLE_WATER_WIDTH
			):
				continue
			var shape := ConvexPolygonShape3D.new()
			shape.points = PackedVector3Array([
				Vector3(left.x, HAZARD_TOP_Y, left_north),
				Vector3(left.x, HAZARD_TOP_Y, left_south),
				Vector3(right.x, HAZARD_TOP_Y, right_south),
				Vector3(right.x, HAZARD_TOP_Y, right_north),
				Vector3(left.x, HAZARD_BOTTOM_Y, left_north),
				Vector3(left.x, HAZARD_BOTTOM_Y, left_south),
				Vector3(right.x, HAZARD_BOTTOM_Y, right_south),
				Vector3(right.x, HAZARD_BOTTOM_Y, right_north),
			])
			var collision := CollisionShape3D.new()
			collision.name = "WaterPrism%03d" % shape_index
			collision.shape = shape
			area.add_child(collision)
			shape_index += 1


func _on_water_body_entered(body: Node3D) -> void:
	water_entered.emit(body)


func _ground_height(x_value: float, z_value: float) -> float:
	if z_value >= WHEAT_CENTER_Z - WHEAT_TERRACE_DEPTH * 0.5 and z_value <= WHEAT_CENTER_Z + WHEAT_TERRACE_DEPTH * 0.5 and x_value >= WHEAT_CENTER_X - WHEAT_TERRACE_HALF_WIDTH and x_value <= WHEAT_CENTER_X + WHEAT_TERRACE_HALF_WIDTH:
		return WHEAT_TOP_HEIGHT
	if z_value <= _main_edge_z(x_value):
		return 4.0
	return 0.0


func _main_edge_z(x_value: float) -> float:
	var contour_side: StringName = UpperPromontoryFront.side_for_x(x_value)
	if not contour_side.is_empty():
		return UpperPromontoryFront.sample_front_z(contour_side, x_value)
	if x_value >= -27.0 and x_value <= -23.0:
		return 1.3
	if x_value >= -20.0 and x_value <= -16.0:
		return 2.0
	if x_value >= -13.0 and x_value < -9.0:
		return -2.94
	if x_value < -9.0:
		return 0.0
	if x_value >= NORTH_TRAIL_END.x - 2.05 and x_value <= NORTH_TRAIL_END.x + 2.05:
		return NORTH_TRAIL_END.z - 0.4
	if x_value <= 1.0:
		return 3.0
	if x_value <= 6.1:
		return 5.7
	if x_value <= 12.0:
		return 8.2
	if x_value >= 15.0 and x_value <= 19.0:
		return 4.5
	if x_value >= 24.0 and x_value <= 28.0:
		return 3.8
	return 2.0


func _add_terrain_section(section_name: String, center: Vector3, size: Vector3, top_center_y: float) -> void:
	_add_static_box(terrain_root, section_name, center, size, _materials[&"cliff"] if size.y > 1.5 else _materials[&"earth"])
	_add_visual_box(
		terrain_root,
		section_name + "Top",
		Vector3(center.x, top_center_y, center.z),
		Vector3(size.x + 0.06, 0.08, size.z + 0.06),
		_materials[&"grass"]
	)


func _make_material(color: Color, roughness: float, transparent: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return material


func _make_textured_material(
	texture: Texture2D,
	tint: Color,
	roughness: float,
	tile_scale: float,
	transparent: bool = false,
	world_triplanar: bool = true
) -> StandardMaterial3D:
	var material := _make_material(tint, roughness, transparent)
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.texture_repeat = true
	material.uv1_scale = Vector3(tile_scale, tile_scale, tile_scale)
	material.uv1_triplanar = world_triplanar
	material.uv1_world_triplanar = world_triplanar
	return material


func _add_flat_shadow(parent: Node3D, center: Vector3, size: Vector2) -> MeshInstance3D:
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	shadow.position = center
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.5
	shadow_mesh.bottom_radius = 0.5
	shadow_mesh.height = 0.018
	shadow_mesh.radial_segments = 32
	shadow.mesh = shadow_mesh
	shadow.scale = Vector3(size.x, 1.0, size.y)
	shadow.material_override = _materials[&"shadow"]
	parent.add_child(shadow)
	return shadow


func _add_tile_field(field_name: String, x_min: float, x_max: float, z_min: float, z_max: float, top_y: float) -> void:
	var transforms_by_tone: Array[Array] = [[], [], []]
	var z_value: float = z_min
	var row: int = 0
	while z_value <= z_max:
		var x_value: float = x_min
		var column: int = 0
		while x_value <= x_max:
			var tone_index: int = posmod(row * 5 + column * 3, 3)
			var tile_transform := Transform3D(Basis.IDENTITY, Vector3(x_value, top_y, z_value))
			transforms_by_tone[tone_index].append(tile_transform)
			x_value += 2.0
			column += 1
		z_value += 2.0
		row += 1
	var materials: Array[Material] = [_materials[&"grass_dark"], _materials[&"grass_mid"], _materials[&"grass_light"]]
	for tone_index: int in range(3):
		var transforms: Array = transforms_by_tone[tone_index]
		if transforms.is_empty():
			continue
		var tile_mesh := BoxMesh.new()
		tile_mesh.size = Vector3(1.94, 0.025, 1.94)
		var multi_mesh := MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.mesh = tile_mesh
		multi_mesh.instance_count = transforms.size()
		for index: int in range(transforms.size()):
			multi_mesh.set_instance_transform(index, transforms[index] as Transform3D)
		var instance := MultiMeshInstance3D.new()
		instance.name = "%s_%d" % [field_name, tone_index]
		instance.multimesh = multi_mesh
		instance.material_override = materials[tone_index]
		terrain_root.add_child(instance)


func _add_multimesh_boxes(parent: Node3D, instance_name: String, transforms: Array[Transform3D], material: Material) -> MultiMeshInstance3D:
	var instance := MultiMeshInstance3D.new()
	instance.name = instance_name
	if transforms.is_empty():
		parent.add_child(instance)
		return instance
	var voxel_mesh := BoxMesh.new()
	voxel_mesh.size = Vector3.ONE
	var multi_mesh := MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = voxel_mesh
	multi_mesh.instance_count = transforms.size()
	for index: int in range(transforms.size()):
		multi_mesh.set_instance_transform(index, transforms[index])
	instance.multimesh = multi_mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _add_static_box(parent: Node3D, body_name: String, center: Vector3, size: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = body_name
	body.collision_layer = 2
	body.collision_mask = 1
	body.position = center
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


func _add_visual_box(parent: Node3D, mesh_name: String, center: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = mesh_name
	mesh_instance.position = center
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _count_type(root: Node, requested_type: Variant) -> int:
	var count: int = 0
	for child: Node in root.get_children():
		if is_instance_of(child, requested_type):
			count += 1
		count += _count_type(child, requested_type)
	return count

class_name HomesteadWorld3D
extends Node3D

const TrailRibbon = preload("res://features/homestead_3d/trail_ribbon_3d.gd")
const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")
const WorldInteractable = preload("res://features/mouse_navigation/world_interactable_3d.gd")
const CHROMA_SHADER = preload("res://features/homestead_3d/player_chroma_3d.gdshader")
const LIGHT_BACKGROUND_SHADER = preload("res://features/homestead_3d/light_background_cutout_3d.gdshader")
const HOMESTEAD_TREE_TEXTURE: Texture2D = preload("res://assets/voxel/homestead_tree_v2.png")
const RIVERBANK_TEXTURE: Texture2D = preload("res://assets/voxel/homestead_riverbank_v2.png")
const GRASS_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_grass_top_v3.png")
const CLIFF_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_cliff_face_v2.png")
const STONE_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_cliff_3d.png")
const TRAIL_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_trail_3d.png")
const WATER_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_water_3d.png")
const WOOD_TEXTURE: Texture2D = preload("res://assets/voxel/terrain_wood_3d.png")

signal water_entered(body: Node3D)

const SPAWN_POSITION := Vector3(-5.0, 4.08, -1.2)
const NORTH_TRAIL_END := Vector3(-5.0, 4.085, 3.0)
const STAIR_BOTTOM := Vector3(-5.0, 0.085, 7.8)
const BRIDGE_NORTH := Vector3(2.0, 0.265, 12.0)
const BRIDGE_SOUTH := Vector3(6.0, 0.265, 20.0)

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
	_build_micro_ground_cover()
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
	}


func get_stair_slope_degrees() -> float:
	var rise: float = absf(NORTH_TRAIL_END.y - STAIR_BOTTOM.y)
	var run: float = Vector2(
		NORTH_TRAIL_END.x - STAIR_BOTTOM.x,
		NORTH_TRAIL_END.z - STAIR_BOTTOM.z
	).length()
	return rad_to_deg(atan2(rise, run))


func _create_materials() -> void:
	_materials[&"grass"] = _make_textured_material(GRASS_TEXTURE, Color("#666d43"), 1.0, 0.32)
	_materials[&"grass_light"] = _make_textured_material(GRASS_TEXTURE, Color("#72784a"), 1.0, 0.32)
	_materials[&"grass_dark"] = _make_material(Color("#4d6422"), 1.0)
	_materials[&"grass_mid"] = _make_material(Color("#778d33"), 1.0)
	_materials[&"earth"] = _make_material(Color("#4d3d20"), 1.0)
	_materials[&"cliff"] = _make_textured_material(CLIFF_TEXTURE, Color("#d1c69d"), 1.0, 0.28)
	_materials[&"cliff_dark"] = _make_textured_material(CLIFF_TEXTURE, Color("#9c9575"), 1.0, 0.28)
	_materials[&"trail"] = _make_textured_material(TRAIL_TEXTURE, Color("#766f59"), 1.0, 0.24, false)
	_materials[&"trail_edge"] = _make_material(Color("#ad985c"), 1.0)
	_materials[&"stone"] = _make_textured_material(STONE_TEXTURE, Color("#d0cbb0"), 0.95, 0.18)
	_materials[&"stone_light"] = _make_textured_material(STONE_TEXTURE, Color("#e0dcc2"), 0.95, 0.18)
	_materials[&"wood"] = _make_textured_material(WOOD_TEXTURE, Color("#7a745e"), 0.9, 0.18, false, false)
	_materials[&"wood_dark"] = _make_textured_material(WOOD_TEXTURE, Color("#4d493c"), 1.0, 0.18, false, false)
	_materials[&"plaster"] = _make_material(Color("#e3d5ac"), 1.0)
	_materials[&"roof"] = _make_material(Color("#a84e2b"), 0.92)
	_materials[&"roof_light"] = _make_material(Color("#c76c36"), 0.92)
	_materials[&"teal"] = _make_material(Color("#277a78"), 0.86)
	_materials[&"wheat"] = _make_material(Color("#d5a92f"), 1.0)
	_materials[&"wheat_light"] = _make_material(Color("#edca4d"), 1.0)
	_materials[&"leaf"] = _make_material(Color("#42651f"), 1.0)
	_materials[&"leaf_light"] = _make_material(Color("#668329"), 1.0)
	_materials[&"flower"] = _make_material(Color("#dc7044"), 1.0)
	_materials[&"water"] = _make_textured_material(WATER_TEXTURE, Color("#3c7772"), 0.25, 0.14, true)
	_materials[&"water_light"] = _make_material(Color(0.18, 0.68, 0.67, 0.86), 0.2, true)
	_materials[&"black"] = _make_material(Color("#241d15"), 1.0)
	_materials[&"gold"] = _make_material(Color("#f1b43c"), 0.8)
	var shadow_material := _make_material(Color(0.07, 0.09, 0.025, 0.085), 1.0, true)
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials[&"shadow"] = shadow_material


func _build_terrain() -> void:
	_add_terrain_section("MainWest", Vector3(-20.0, 1.92, -28.0), Vector3(24.0, 4.16, 64.0), 4.015)
	_add_terrain_section("MainCenter", Vector3(-4.0, 1.92, -28.5), Vector3(10.0, 4.16, 63.0), 4.015)
	_add_terrain_section("MainEast", Vector3(9.5, 1.92, -29.0), Vector3(17.0, 4.16, 62.0), 4.015)
	_add_terrain_section("HomesteadPromontory", Vector3(5.0, 1.92, 1.1), Vector3(14.0, 4.16, 14.2), 4.015)
	_add_static_box(terrain_root, "WheatTerrace", Vector3(8.0, 5.96, -16.0), Vector3(19.0, 4.0, 10.0), _materials[&"cliff"])
	_add_visual_box(terrain_root, "WheatTerraceTop", Vector3(8.0, 8.015, -16.0), Vector3(19.1, 0.08, 10.1), _materials[&"grass_light"])
	_add_terrain_section("NorthBankWest", Vector3(-20.0, -0.55, 8.1), Vector3(24.0, 1.1, 8.2), 0.015)
	_add_terrain_section("NorthBankCenter", Vector3(-4.0, -0.55, 7.6), Vector3(10.0, 1.1, 9.2), 0.015)
	_add_terrain_section("NorthBankEast", Vector3(9.5, -0.55, 7.1), Vector3(17.0, 1.1, 10.2), 0.015)
	_add_terrain_section("NorthBankFingerWest", Vector3(-12.0, -0.55, 12.15), Vector3(3.4, 1.1, 2.2), 0.015)
	_add_terrain_section("NorthBankFingerCenter", Vector3(-1.0, -0.55, 11.65), Vector3(4.2, 1.1, 1.8), 0.015)
	_add_terrain_section("NorthBankFingerEast", Vector3(12.0, -0.55, 11.35), Vector3(4.6, 1.1, 1.6), 0.015)
	_add_terrain_section("SouthMeadowWest", Vector3(-14.5, -0.55, 31.75), Vector3(35.0, 1.1, 22.5), 0.015)
	_add_terrain_section("SouthMeadowCenter", Vector3(6.0, -0.55, 31.5), Vector3(6.0, 1.1, 23.0), 0.015)
	_add_terrain_section("SouthMeadowEast", Vector3(13.5, -0.55, 31.25), Vector3(9.0, 1.1, 23.5), 0.015)
	_add_terrain_section("SouthBankFingerWest", Vector3(-13.0, -0.55, 19.75), Vector3(4.0, 1.1, 2.0), 0.015)
	_add_terrain_section("SouthBankFingerCenter", Vector3(-2.0, -0.55, 20.0), Vector3(4.4, 1.1, 1.5), 0.015)
	_add_terrain_section("SouthBankFingerEast", Vector3(12.5, -0.55, 19.55), Vector3(4.8, 1.1, 2.1), 0.015)
	_add_visual_box(terrain_root, "RiverWater", Vector3(0.0, -0.16, 16.0), Vector3(64.0, 0.22, 9.0), _materials[&"water"])
	for x_value: float in [-15.0, -10.0, -5.0, 0.0, 9.0, 14.0]:
		_add_visual_box(terrain_root, "WaterGlint", Vector3(x_value, -0.035, 15.0 + fmod(absf(x_value), 2.0)), Vector3(2.2, 0.025, 0.12), _materials[&"water_light"])
	_build_retaining_blocks()


func _build_retaining_blocks() -> void:
	for x_index: int in range(-9, 10):
		if x_index in [-3, -2]:
			continue
		var x_value: float = float(x_index) * 1.85
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
			_materials[&"grass_light"] if x_index % 3 == 0 else _materials[&"grass"]
		)
	for x_index: int in range(-1, 10):
		var x_value: float = -1.0 + float(x_index) * 1.85
		for row_index: int in range(5):
			var row_y: float = 4.4 + float(row_index) * 0.78
			var row_offset: float = 0.22 if row_index % 2 == 1 else 0.0
			var row_tone: Material = _materials[&"cliff"] if (x_index + row_index) % 3 != 0 else _materials[&"cliff_dark"]
			_add_visual_box(
				terrain_root,
				"HighRetainingBlock",
				Vector3(x_value + row_offset, row_y, -10.955),
				Vector3(1.7, 0.72, 0.2),
				row_tone
			)


func _build_route() -> void:
	var north_points := PackedVector3Array([
		Vector3(-12.0, 4.085, -55.0), Vector3(-13.0, 4.085, -48.0),
		Vector3(-11.0, 4.085, -42.0), Vector3(-12.5, 4.085, -36.0),
		Vector3(-12.5, 4.085, -33.0), Vector3(-11.8, 4.085, -30.0),
		Vector3(-10.8, 4.085, -27.0), Vector3(-12.0, 4.085, -24.0),
		Vector3(-10.2, 4.085, -21.5), Vector3(-8.8, 4.085, -18.5), Vector3(-9.5, 4.085, -15.5),
		Vector3(-10.5, 4.085, -12.5), Vector3(-8.0, 4.085, -9.5),
		Vector3(-5.8, 4.085, -7.0), Vector3(-5.2, 4.085, -4.2),
		Vector3(-5.0, 4.085, -1.2), Vector3(-5.0, 4.085, 1.0),
		Vector3(-5.0, 4.085, 2.15), NORTH_TRAIL_END,
	])
	var lower_points := PackedVector3Array([
		STAIR_BOTTOM, Vector3(-4.2, 0.085, 8.6), Vector3(-3.0, 0.085, 9.2),
		Vector3(0.7, 0.085, 10.1), Vector3(1.33, 0.16, 10.8),
		BRIDGE_NORTH,
	])
	var south_points := PackedVector3Array([
		BRIDGE_SOUTH, Vector3(6.67, 0.16, 21.34), Vector3(7.2, 0.085, 23.5),
		Vector3(8.5, 0.085, 25.5), Vector3(7.5, 0.085, 28.0),
		Vector3(8.5, 0.085, 31.0), Vector3(7.5, 0.085, 34.0),
		Vector3(9.2, 0.085, 36.0), Vector3(10.5, 0.085, 38.0),
		Vector3(11.5, 0.085, 40.0),
	])
	var north_trail := TrailRibbon.new() as TrailRibbon3D
	north_trail.name = "NorthTrail"
	north_trail.configure(north_points, 1.34, _materials[&"trail"])
	route_root.add_child(north_trail)
	var lower_trail := TrailRibbon.new() as TrailRibbon3D
	lower_trail.name = "LowerTrail"
	lower_trail.configure(lower_points, 1.34, _materials[&"trail"])
	route_root.add_child(lower_trail)
	var south_trail := TrailRibbon.new() as TrailRibbon3D
	south_trail.name = "SouthTrail"
	south_trail.configure(south_points, 1.34, _materials[&"trail"])
	route_root.add_child(south_trail)
	_build_stairs()
	_build_bridge()
	_route_endpoints = {
		&"north_trail_end": north_trail.get_end_point(),
		&"stair_top": NORTH_TRAIL_END,
		&"stair_bottom": STAIR_BOTTOM,
		&"lower_trail_start": lower_trail.get_start_point(),
		&"lower_trail_end": lower_trail.get_end_point(),
		&"bridge_north": BRIDGE_NORTH,
		&"bridge_south": BRIDGE_SOUTH,
		&"south_trail_start": south_trail.get_start_point(),
	}


func _build_stairs() -> void:
	var stair_root := Node3D.new()
	stair_root.name = "StoneStair"
	stair_root.add_to_group("homestead_3d_landmark")
	route_root.add_child(stair_root)
	var step_count: int = 10
	var stair_rise: float = NORTH_TRAIL_END.y - STAIR_BOTTOM.y
	var stair_run: float = STAIR_BOTTOM.z - NORTH_TRAIL_END.z
	var step_depth: float = stair_run / float(step_count)
	for index: int in range(step_count):
		var top_height: float = stair_rise - float(index) * (stair_rise / float(step_count))
		var center_z: float = NORTH_TRAIL_END.z + (float(index) + 0.5) * step_depth
		_add_visual_box(stair_root, "StoneTread", Vector3(-5.0, top_height * 0.5, center_z), Vector3(2.45, top_height, step_depth + 0.03), _materials[&"stone"] if index % 2 == 0 else _materials[&"stone_light"])
	var ramp := StaticBody3D.new()
	ramp.name = "SmoothRampCollision"
	ramp.collision_layer = 2
	ramp.collision_mask = 1
	ramp.position = Vector3(-5.0, STAIR_BOTTOM.y + stair_rise * 0.5, (NORTH_TRAIL_END.z + STAIR_BOTTOM.z) * 0.5)
	ramp.rotation.x = atan2(stair_rise, stair_run)
	var ramp_shape := BoxShape3D.new()
	ramp_shape.size = Vector3(2.34, 0.12, sqrt(stair_rise * stair_rise + stair_run * stair_run))
	var collision := CollisionShape3D.new()
	collision.shape = ramp_shape
	ramp.add_child(collision)
	stair_root.add_child(ramp)
	for side: float in [-1.42, 1.42]:
		_add_visual_box(stair_root, "StairCheek", Vector3(-5.0 + side, stair_rise * 0.5, (NORTH_TRAIL_END.z + STAIR_BOTTOM.z) * 0.5), Vector3(0.3, stair_rise, stair_run + 0.2), _materials[&"cliff_dark"])


func _build_bridge() -> void:
	var bridge_root := Node3D.new()
	bridge_root.name = "TimberBridge"
	bridge_root.add_to_group("homestead_3d_landmark")
	route_root.add_child(bridge_root)
	var bridge_vector: Vector3 = BRIDGE_SOUTH - BRIDGE_NORTH
	var bridge_length: float = Vector2(bridge_vector.x, bridge_vector.z).length()
	bridge_root.position = (BRIDGE_NORTH + BRIDGE_SOUTH) * 0.5
	bridge_root.rotation.y = atan2(bridge_vector.x, bridge_vector.z)
	var deck := _add_static_box(bridge_root, "BridgeDeckCollision", Vector3(0.0, -0.16, 0.0), Vector3(2.65, 0.21, bridge_length), _materials[&"wood"])
	deck.visible = false
	var plank_count: int = 18
	for index: int in range(plank_count):
		var z_value: float = -bridge_length * 0.5 + 0.25 + float(index) * ((bridge_length - 0.5) / float(plank_count - 1))
		var material: Material = _materials[&"wood"] if index % 3 != 0 else _materials[&"wood_dark"]
		_add_visual_box(bridge_root, "BridgePlank", Vector3(0.0, -0.125, z_value), Vector3(2.85, 0.22, 0.45), material)
	for side: float in [-1.62, 1.62]:
		for post_index: int in range(5):
			var post_z: float = -bridge_length * 0.5 + 0.25 + float(post_index) * ((bridge_length - 0.5) / 4.0)
			_add_visual_box(bridge_root, "BridgePost", Vector3(side, 0.42, post_z), Vector3(0.22, 1.35, 0.22), _materials[&"wood_dark"])
		_add_visual_box(bridge_root, "BridgeRail", Vector3(side, 0.67, 0.0), Vector3(0.18, 0.18, bridge_length - 0.3), _materials[&"wood"])
	for pile_x: float in [-1.2, 1.2]:
		for pile_z: float in [-bridge_length * 0.37, bridge_length * 0.37]:
			_add_visual_box(bridge_root, "BridgePile", Vector3(pile_x, -0.8, pile_z), Vector3(0.35, 1.5, 0.35), _materials[&"wood_dark"])


func _build_homestead() -> void:
	var compound := WorldInteractable.new()
	compound.name = "HomesteadCompound"
	compound.position = Vector3(-1.0, 2.0, 6.0)
	compound.configure(
		"Trailkeeper Homestead",
		"The cottage is warm, but the open trail is calling. Your Field Guide tracks creatures, supplies, and badges.",
		Vector3(-2.0, 2.08, -3.0),
		3.0
	)
	compound.add_to_group("homestead_3d_landmark")
	props_root.add_child(compound)
	_add_static_box(compound, "HouseFoundation", Vector3(2.0, 2.22, -4.7), Vector3(6.5, 0.42, 5.6), _materials[&"stone"])
	_add_static_box(compound, "HouseWalls", Vector3(2.0, 3.8, -4.7), Vector3(5.5, 3.2, 4.6), _materials[&"plaster"])
	_add_visual_box(compound, "HouseTimberLeft", Vector3(-0.45, 3.9, -2.36), Vector3(0.28, 3.0, 0.25), _materials[&"wood_dark"])
	_add_visual_box(compound, "HouseTimberRight", Vector3(4.45, 3.9, -2.36), Vector3(0.28, 3.0, 0.25), _materials[&"wood_dark"])
	_add_visual_box(compound, "HouseBeam", Vector3(2.0, 4.55, -2.34), Vector3(5.15, 0.28, 0.28), _materials[&"wood_dark"])
	_add_visual_box(compound, "Door", Vector3(1.25, 3.25, -2.33), Vector3(1.05, 1.95, 0.20), _materials[&"wood_dark"])
	for window_x: float in [3.0, 4.05]:
		_add_visual_box(compound, "Window", Vector3(window_x, 3.72, -2.31), Vector3(0.62, 0.78, 0.18), _materials[&"teal"])
	_add_visual_box(compound, "RoofLower", Vector3(2.0, 5.58, -4.7), Vector3(6.55, 0.52, 5.5), _materials[&"roof"])
	_add_visual_box(compound, "RoofMiddle", Vector3(2.0, 6.0, -4.7), Vector3(5.35, 0.48, 4.35), _materials[&"roof_light"])
	_add_visual_box(compound, "RoofRidge", Vector3(2.0, 6.42, -4.7), Vector3(2.1, 0.48, 3.2), _materials[&"roof"])
	_add_visual_box(compound, "Chimney", Vector3(0.15, 6.75, -5.45), Vector3(0.65, 1.5, 0.65), _materials[&"stone_light"])
	_build_shed(compound)
	_build_garden(compound)
	_build_fence(compound)
	_build_lantern(compound, Vector3(-1.1, 2.0, -0.5))
	_hide_mesh_descendants(compound)
	_add_flat_shadow(compound, Vector3(2.8, 2.066, -4.4), Vector2(7.5, 4.8))
	_add_chroma_sprite(
		compound,
		"HomesteadArtwork",
		VoxelAssets.HOMESTEAD_COMPOUND,
		VoxelAssets.get_prop_source_rect(VoxelAssets.HOMESTEAD_COMPOUND, 9),
		0.0176,
		Vector3(2.6, 2.02, -4.2)
	)


func _build_shed(parent: Node3D) -> void:
	_add_static_box(parent, "ShedWalls", Vector3(-1.2, 3.0, -7.8), Vector3(2.4, 2.0, 2.2), _materials[&"wood"])
	_add_visual_box(parent, "ShedRoof", Vector3(-1.2, 4.15, -7.8), Vector3(2.8, 0.35, 2.6), _materials[&"teal"])
	_add_visual_box(parent, "ShedDoor", Vector3(-1.2, 2.85, -6.68), Vector3(0.8, 1.45, 0.16), _materials[&"wood_dark"])


func _build_garden(parent: Node3D) -> void:
	for row: int in range(3):
		_add_visual_box(parent, "GardenSoil", Vector3(6.5, 2.09, -0.4 - float(row) * 0.75), Vector3(3.7, 0.13, 0.52), _materials[&"earth"])
		for plant: int in range(6):
			var plant_x: float = 5.1 + float(plant) * 0.55
			_add_visual_box(parent, "GardenPlant", Vector3(plant_x, 2.3, -0.4 - float(row) * 0.75), Vector3(0.3, 0.42, 0.3), _materials[&"leaf_light"])
	for x_value: float in [4.5, 8.5]:
		_add_static_box(parent, "GardenRail", Vector3(x_value, 2.35, -1.15), Vector3(0.18, 0.7, 2.7), _materials[&"wood_dark"])


func _build_fence(parent: Node3D) -> void:
	for x_value: float in range(-2, 12, 2):
		_add_static_box(parent, "FencePost", Vector3(x_value, 2.65, -10.2), Vector3(0.22, 1.3, 0.22), _materials[&"wood_dark"])
		_add_static_box(parent, "FencePost", Vector3(x_value, 2.65, 1.4), Vector3(0.22, 1.3, 0.22), _materials[&"wood_dark"])
	_add_static_box(parent, "FenceNorth", Vector3(4.0, 2.73, -10.2), Vector3(12.0, 0.18, 0.18), _materials[&"wood"])
	_add_static_box(parent, "FenceSouthLeft", Vector3(0.3, 2.73, 1.4), Vector3(4.6, 0.18, 0.18), _materials[&"wood"])
	_add_static_box(parent, "FenceSouthRight", Vector3(7.7, 2.73, 1.4), Vector3(4.6, 0.18, 0.18), _materials[&"wood"])
	for z_value: float in range(-10, 2, 2):
		_add_static_box(parent, "FencePost", Vector3(10.0, 2.65, z_value), Vector3(0.22, 1.3, 0.22), _materials[&"wood_dark"])
	_add_static_box(parent, "FenceEast", Vector3(10.0, 2.73, -4.4), Vector3(0.18, 0.18, 11.6), _materials[&"wood"])


func _build_lantern(parent: Node3D, base_position: Vector3) -> void:
	_add_visual_box(parent, "LanternPost", base_position + Vector3(0.0, 1.15, 0.0), Vector3(0.18, 2.3, 0.18), _materials[&"black"])
	_add_visual_box(parent, "LanternCap", base_position + Vector3(0.0, 2.35, 0.0), Vector3(0.7, 0.18, 0.7), _materials[&"black"])
	_add_visual_box(parent, "LanternGlow", base_position + Vector3(0.0, 2.0, 0.0), Vector3(0.42, 0.55, 0.42), _materials[&"gold"])


func _build_wheat_field() -> void:
	var field := StaticBody3D.new()
	field.name = "WheatField"
	field.collision_layer = 2
	field.collision_mask = 1
	field.add_to_group("homestead_3d_landmark")
	props_root.add_child(field)
	var field_shape := BoxShape3D.new()
	field_shape.size = Vector3(13.5, 1.45, 6.2)
	var field_collision := CollisionShape3D.new()
	field_collision.position = Vector3(8.0, 8.72, -16.0)
	field_collision.shape = field_shape
	field.add_child(field_collision)
	for row: int in range(9):
		for column: int in range(19):
			var x_value: float = 1.8 + float(column) * 0.68 + (0.22 if row % 2 == 1 else 0.0)
			var z_value: float = -18.7 + float(row) * 0.68
			var height: float = 0.75 + float((row * 7 + column * 3) % 5) * 0.08
			var tone: Material = _materials[&"wheat_light"] if (row + column) % 4 == 0 else _materials[&"wheat"]
			_add_visual_box(field, "WheatStalk", Vector3(x_value, 8.0 + height * 0.5, z_value), Vector3(0.16, height, 0.16), tone)
			_add_visual_box(field, "WheatHead", Vector3(x_value, 8.0 + height + 0.08, z_value), Vector3(0.25, 0.22, 0.25), tone)
	_hide_mesh_descendants(field)
	_add_flat_shadow(field, Vector3(8.0, 8.066, -16.0), Vector2(10.5, 4.5))
	_add_chroma_sprite(
		field,
		"WheatArtwork",
		VoxelAssets.WHEAT_FIELD,
		VoxelAssets.get_prop_source_rect(VoxelAssets.WHEAT_FIELD, 10),
		0.0107,
		Vector3(8.0, 8.02, -16.0),
		Color("#b7a16f")
	)


func _build_forest_frame() -> void:
	var tree_positions := [
		Vector3(-16.5, 0.0, -23.0), Vector3(-15.0, 0.0, -21.0),
		Vector3(-5.0, 0.0, -30.0), Vector3(3.0, 0.0, -28.0), Vector3(10.5, 0.0, -33.0),
		Vector3(0.0, 0.0, -18.0), Vector3(-2.0, 0.0, -12.5),
		Vector3(15.5, 0.0, -22.0), Vector3(-14.0, 0.0, -14.0), Vector3(16.5, 0.0, -15.0),
		Vector3(-16.0, 0.0, -6.0), Vector3(14.0, 0.0, -8.0), Vector3(16.0, 0.0, -1.5),
		Vector3(-15.5, 0.0, 0.0), Vector3(14.5, 0.0, 1.0), Vector3(-14.5, 0.0, 10.0),
		Vector3(14.5, 0.0, 10.2), Vector3(-16.5, 0.0, 22.0), Vector3(-11.0, 0.0, 24.0),
		Vector3(15.0, 0.0, 25.0), Vector3(17.0, 0.0, 30.5), Vector3(-16.0, 0.0, 32.0),
		Vector3(-12.0, 0.0, 31.0), Vector3(13.0, 0.0, 33.5), Vector3(-8.0, 0.0, 38.0),
		Vector3(1.0, 0.0, 38.5), Vector3(16.5, 0.0, 38.0),
	]
	for tree_position: Vector3 in tree_positions:
		_build_tree(tree_position.x, tree_position.z)
	var rock_positions := [Vector3(-11.0, 0.0, -9.0), Vector3(13.0, 0.0, -11.0), Vector3(-10.0, 0.0, 10.0), Vector3(11.0, 0.0, 23.0), Vector3(-12.0, 0.0, 32.0)]
	for rock_position: Vector3 in rock_positions:
		var height: float = _ground_height(rock_position.x, rock_position.z)
		var rock_body := _add_static_box(props_root, "MossRock", Vector3(rock_position.x, height + 0.38, rock_position.z), Vector3(1.2, 0.75, 0.9), _materials[&"stone"])
		_hide_mesh_descendants(rock_body)
		_add_chroma_sprite(
			props_root,
			"RockArtwork",
			VoxelAssets.ROCK,
			VoxelAssets.get_prop_source_rect(VoxelAssets.ROCK, 4),
			0.0052,
			Vector3(rock_position.x, height + 0.02, rock_position.z)
		)


func _build_tree(x_value: float, z_value: float) -> void:
	var floor_height: float = _ground_height(x_value, z_value)
	var tree := Node3D.new()
	tree.name = "VoxelTree"
	props_root.add_child(tree)
	_add_static_box(tree, "TreeTrunk", Vector3(x_value, floor_height + 1.65, z_value), Vector3(0.8, 3.3, 0.8), _materials[&"wood_dark"])
	var clusters := [
		Vector3(0.0, 3.5, 0.0), Vector3(-0.9, 3.25, 0.2), Vector3(0.9, 3.35, 0.1),
		Vector3(0.0, 4.35, 0.0), Vector3(-0.55, 4.1, -0.7), Vector3(0.65, 4.0, -0.6),
	]
	for index: int in range(clusters.size()):
		var cluster: Vector3 = clusters[index]
		var tone: Material = _materials[&"leaf_light"] if index % 3 == 0 else _materials[&"leaf"]
		_add_visual_box(tree, "LeafCluster", Vector3(x_value, floor_height, z_value) + cluster, Vector3(1.7, 1.35, 1.7), tone)
	_hide_mesh_descendants(tree)
	_add_flat_shadow(tree, Vector3(x_value, floor_height + 0.066, z_value), Vector2(2.3, 1.5))
	var tree_sprite := _add_light_background_sprite(
		tree,
		"TreeArtwork",
		HOMESTEAD_TREE_TEXTURE,
		Rect2(179.0, 91.0, 895.0, 1024.0),
		0.0039 + float(posmod(int(round(absf(x_value * 7.0 + z_value * 11.0))), 4)) * 0.00035,
		Vector3(x_value, floor_height + 0.02, z_value)
	)
	tree_sprite.flip_h = int(absf(x_value * 3.0 + z_value)) % 2 == 0


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
		Vector3(-15.0, 0, 20.9), Vector3(-10.0, 0, 21.0), Vector3(-5.0, 0, 20.8),
		Vector3(10.0, 0, 20.9), Vector3(14.5, 0, 21.0),
	]
	for detail_position: Vector3 in detail_positions:
		var floor_height: float = _ground_height(detail_position.x, detail_position.z)
		_add_flat_shadow(props_root, Vector3(detail_position.x, floor_height + 0.066, detail_position.z), Vector2(1.0, 0.6))
		var shrub_sprite := _add_chroma_sprite(
			props_root,
			"MeadowShrubArtwork",
			VoxelAssets.MEADOW_SHRUB,
			VoxelAssets.get_prop_source_rect(VoxelAssets.MEADOW_SHRUB, 11),
			0.0040,
			Vector3(detail_position.x, floor_height + 0.02, detail_position.z),
			Color("#879166")
		)
		shrub_sprite.flip_h = int(absf(detail_position.x + detail_position.z)) % 2 == 0


func _build_micro_ground_cover() -> void:
	var cover_positions := [
		Vector3(-15, 0, -22), Vector3(-7, 0, -22), Vector3(-3, 0, -20), Vector3(15, 0, -21),
		Vector3(-13, 0, -16), Vector3(-6, 0, -15), Vector3(0, 0, -11), Vector3(13, 0, -12),
		Vector3(-15, 0, -8), Vector3(-11, 0, -6), Vector3(11, 0, -7), Vector3(15, 0, -3),
		Vector3(-14, 0, 0), Vector3(-10, 0, 2), Vector3(9, 0, 0), Vector3(14, 0, 1),
		Vector3(-16, 0, 7), Vector3(-11, 0, 8), Vector3(-7, 0, 11.3), Vector3(-2, 0, 11.2),
		Vector3(8, 0, 11), Vector3(12, 0, 10.5), Vector3(16, 0, 9),
		Vector3(-16, 0, 20.8), Vector3(-11, 0, 21.2), Vector3(-5, 0, 20.8), Vector3(1, 0, 21.1),
		Vector3(10, 0, 20.2), Vector3(15, 0, 21.0), Vector3(-14, 0, 25), Vector3(-8, 0, 26),
		Vector3(-2, 0, 21), Vector3(13, 0, 22), Vector3(16, 0, 26), Vector3(-16, 0, 29),
		Vector3(-10, 0, 31), Vector3(-4, 0, 28), Vector3(3, 0, 29), Vector3(14, 0, 31),
		Vector3(-15, 0, 36), Vector3(-8, 0, 35), Vector3(-2, 0, 38), Vector3(5, 0, 36),
		Vector3(15, 0, 37),
	]
	for index: int in range(cover_positions.size()):
		var cover_position: Vector3 = cover_positions[index]
		var floor_height: float = _ground_height(cover_position.x, cover_position.z)
		var cover_sprite := _add_chroma_sprite(
			props_root,
			"GroundCoverArtwork",
			VoxelAssets.MEADOW_SHRUB,
			VoxelAssets.get_prop_source_rect(VoxelAssets.MEADOW_SHRUB, 11),
			0.0020 if index % 3 != 0 else 0.0025,
			Vector3(cover_position.x, floor_height + 0.025, cover_position.z),
			Color("#7d895c")
		)
		cover_sprite.flip_h = index % 2 == 0


func _build_riverbank_foliage() -> void:
	var bank_positions := [
		Vector3(-16.0, 0.0, 11.25), Vector3(-11.5, 0.0, 11.2), Vector3(-7.0, 0.0, 11.25),
		Vector3(9.0, 0.0, 11.2), Vector3(13.5, 0.0, 11.25), Vector3(16.5, 0.0, 11.15),
		Vector3(-15.0, 0.0, 20.75), Vector3(-10.0, 0.0, 20.8), Vector3(-5.0, 0.0, 20.75),
		Vector3(10.0, 0.0, 20.8), Vector3(14.5, 0.0, 20.75),
	]
	for index: int in range(bank_positions.size()):
		var bank_position: Vector3 = bank_positions[index]
		var bank_sprite := _add_light_background_sprite(
			props_root,
			"RiverbankArtwork",
			RIVERBANK_TEXTURE,
			Rect2(141.0, 274.0, 1118.0, 561.0),
			0.0030 if index % 3 != 0 else 0.0034,
			bank_position
		)
		bank_sprite.flip_h = index % 2 == 0


func _build_water_hazards() -> void:
	_add_water_area("WestWater", Vector3(-15.75, -0.1, 16.0), Vector3(32.5, 2.0, 7.4))
	_add_water_area("EastWater", Vector3(18.0, -0.1, 16.0), Vector3(28.0, 2.0, 7.4))


func _add_water_area(area_name: String, center: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = area_name
	area.collision_layer = 4
	area.collision_mask = 1
	area.position = center
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_on_water_body_entered)
	hazards_root.add_child(area)


func _on_water_body_entered(body: Node3D) -> void:
	water_entered.emit(body)


func _ground_height(x_value: float, z_value: float) -> float:
	if z_value <= -11.0 and x_value >= -1.5:
		return 8.0
	if z_value <= _main_edge_z(x_value):
		return 4.0
	return 0.0


func _main_edge_z(x_value: float) -> float:
	if x_value < -9.0:
		return 4.0
	if x_value <= 1.0:
		return 3.0
	if x_value <= 12.0:
		return 8.2
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
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC
	material.texture_repeat = true
	material.uv1_scale = Vector3(tile_scale, tile_scale, tile_scale)
	material.uv1_triplanar = world_triplanar
	material.uv1_world_triplanar = world_triplanar
	return material


func _add_chroma_sprite(
	parent: Node3D,
	sprite_name: String,
	texture: Texture2D,
	region: Rect2,
	pixel_size: float,
	ground_position: Vector3,
	tint: Color = Color.WHITE
) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.pixel_size = pixel_size
	sprite.position = ground_position + Vector3.UP * region.size.y * pixel_size * 0.5
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var material := ShaderMaterial.new()
	material.shader = CHROMA_SHADER
	material.set_shader_parameter("sprite_texture", texture)
	material.set_shader_parameter("sprite_tint", Vector3(tint.r, tint.g, tint.b))
	sprite.material_override = material
	parent.add_child(sprite)
	return sprite


func _add_light_background_sprite(
	parent: Node3D,
	sprite_name: String,
	texture: Texture2D,
	region: Rect2,
	pixel_size: float,
	ground_position: Vector3
) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.pixel_size = pixel_size
	sprite.position = ground_position + Vector3.UP * region.size.y * pixel_size * 0.5
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var material := ShaderMaterial.new()
	material.shader = LIGHT_BACKGROUND_SHADER
	material.set_shader_parameter("sprite_texture", texture)
	sprite.material_override = material
	parent.add_child(sprite)
	return sprite


func _hide_mesh_descendants(root: Node) -> void:
	for child: Node in root.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
		_hide_mesh_descendants(child)


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

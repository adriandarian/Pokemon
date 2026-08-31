extends Node

const REGION: TerrainRegionDefinition = preload(
	"res://features/homestead_baseline/content/homestead_starter_region.tres"
)
const HOMESTEAD_WORLD: PackedScene = preload(
	"res://features/homestead_baseline/homestead_world.tscn"
)
const ADVENTURE_SCENE: PackedScene = preload(
	"res://features/adventure/adventure.tscn"
)

var _failures: Array[String] = []


func _ready() -> void:
	var chunks: Array[TerrainChunkData] = TerrainCompiler.compile_region(REGION)
	_expect(REGION.region_id == &"homestead_baseline", "The baseline uses its isolated terrain identity.")
	_expect(chunks.size() == 4, "The homestead compiles into the expected four chunks.")
	var query := TerrainQuery.new()
	_expect(query.configure(REGION, chunks), "The homestead query accepts every compiled chunk.")

	var north_meadow: TerrainSample = query.sample_cell(Vector2i(24, 24))
	var high_field: TerrainSample = query.sample_cell(Vector2i(48, 10))
	var river: TerrainSample = query.sample_cell(Vector2i(12, 47))
	var bridge: TerrainSample = query.sample_cell(Vector2i(38, 47))
	_expect(
		north_meadow.is_walkable() and is_equal_approx(north_meadow.elevation_level, 1.0),
		"The cottage meadow is a walkable raised terrace."
	)
	_expect(
		high_field.is_walkable() and is_equal_approx(high_field.elevation_level, 2.0),
		"The wheat field sits on a distinct high terrace."
	)
	_expect(
		river.valid and not river.is_walkable() and river.surface == TerrainChunkData.Surface.WATER,
		"The river is visible terrain but blocks walking."
	)
	_expect(
		bridge.is_walkable() and bridge.surface == TerrainChunkData.Surface.BRIDGE,
		"The timber bridge is the walkable crossing through the river."
	)
	_expect(
		query.can_traverse_cells(Vector2i(37, 34), Vector2i(37, 35)),
		"Adjacent stone stair treads form a valid elevation transition."
	)
	_expect(
		query.is_edge_blocked(Vector2i(18, 35), Vector2i(18, 36)),
		"The unstamped riverbank remains a blocked drop."
	)

	var terrain_world := HOMESTEAD_WORLD.instantiate() as TerrainWorld
	add_child(terrain_world)
	await get_tree().process_frame
	_expect(terrain_world.get_active_chunk_count() == 4, "The baseline materializes its complete terrain district.")
	_expect(terrain_world.get_collision_shape_count() > 0, "Terrain topology produces physical water and cliff barriers.")
	terrain_world.queue_free()

	GameSession.start_new_game("Homestead Tester")
	var adventure: Node = ADVENTURE_SCENE.instantiate()
	add_child(adventure)
	await get_tree().process_frame
	await get_tree().physics_frame
	var player := adventure.get_node_or_null("Actors/Player") as PlayerCharacter
	var settlement := adventure.get_node_or_null("SettlementRuntime") as SettlementRuntime
	var props := adventure.get_node_or_null("Actors/Props") as Node2D
	var wild_creatures := adventure.get_node_or_null("Actors/WildCreatures") as Node2D
	_expect(player != null, "The homestead opens with the controllable player on the yard path.")
	_expect(
		player != null and player.global_position.is_equal_approx(Vector2(1320.0, 1580.0)),
		"The player starts below-left of the cottage as shown in the composition."
	)
	_expect(
		player != null and is_equal_approx(player.get_ground_elevation_pixels(), 80.0),
		"The player is projected onto the raised cottage terrace."
	)
	_expect(settlement != null and settlement.get_active_prop_count() == 4, "Only the compound, wheat, stair, and bridge stream from settlement content.")
	_expect(wild_creatures != null and wild_creatures.get_child_count() == 0, "The clean starting baseline contains no old preserve encounters.")
	_expect(adventure.get_node_or_null("TerrainScatterRuntime") == null, "The previous biome-scatter renderer is disconnected from the live scene.")
	_expect(adventure.get_node_or_null("WorldCanvas/WaterSurface") == null, "The old decorative water surface is disconnected from the live scene.")
	_expect(adventure.get_node_or_null("WorldCanvas/RiverOverlay") == null, "The old river overlay is disconnected from the live scene.")

	var homestead_count: int = 0
	var wheat_count: int = 0
	var shrub_count: int = 0
	var crossing_count: int = 0
	var stair_count: int = 0
	var old_building_count: int = 0
	for child: Node in props.get_children():
		if not child is AdventureProp:
			continue
		var prop := child as AdventureProp
		match prop.kind:
			AdventureProp.Kind.HOMESTEAD_COMPOUND:
				homestead_count += 1
			AdventureProp.Kind.WHEAT_FIELD:
				wheat_count += 1
			AdventureProp.Kind.MEADOW_SHRUB:
				shrub_count += 1
			AdventureProp.Kind.RIVER_CROSSING:
				crossing_count += 1
			AdventureProp.Kind.RIVER_STAIR:
				stair_count += 1
			AdventureProp.Kind.HOUSE, AdventureProp.Kind.COTTAGE, AdventureProp.Kind.MARKET_STALL, AdventureProp.Kind.CIVIC_HALL:
				old_building_count += 1
	_expect(homestead_count == 1, "Exactly one coherent homestead compound anchors the baseline.")
	_expect(wheat_count == 1, "Exactly one dense wheat landmark fills the upper terrace.")
	_expect(shrub_count >= 16, "Low meadow vegetation breaks up the open ground around the authored route.")
	_expect(crossing_count == 1, "One detailed stair-and-bridge overlay grounds the traversable river connector.")
	_expect(stair_count == 1, "One fitted stone stair visually covers the upper elevation connector.")
	_expect(old_building_count == 0, "No former village building remains in the active render.")
	adventure.queue_free()

	if _failures.is_empty():
		print("HOMESTEAD_BASELINE_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("HOMESTEAD_BASELINE_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

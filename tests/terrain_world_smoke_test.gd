extends Node

const REGION: TerrainRegionDefinition = preload(
	"res://features/terrain_world/content/windfall_starter_region.tres"
)
const TERRAIN_WORLD_SCENE: PackedScene = preload(
	"res://features/terrain_world/terrain_world.tscn"
)
const SCATTER_PROFILE: TerrainScatterProfile = preload(
	"res://features/terrain_world/content/windfall_scatter_profile.tres"
)

class ElevationTarget:
	extends Node2D

	var ground_elevation_pixels: float = -1.0

	func set_ground_elevation_pixels(value: float) -> void:
		ground_elevation_pixels = value


var _failures: Array[String] = []


func _ready() -> void:
	var first_compile: Array[TerrainChunkData] = TerrainCompiler.compile_region(REGION)
	var second_compile: Array[TerrainChunkData] = TerrainCompiler.compile_region(REGION)
	_expect(first_compile.size() == 4, "The starter region compiles into a four-chunk district.")
	_expect(second_compile.size() == first_compile.size(), "Repeated compilation produces the same chunk count.")
	if first_compile.size() == 4 and second_compile.size() == 4:
		for index: int in range(first_compile.size()):
			_expect(
				first_compile[index].elevations == second_compile[index].elevations,
				"Repeated compilation produces byte-equivalent elevation fields for chunk %d." % index
			)
			_expect(
				first_compile[index].surface_ids == second_compile[index].surface_ids,
				"Repeated compilation produces byte-equivalent surface fields for chunk %d." % index
			)
			_expect(
				first_compile[index].biome_indices == second_compile[index].biome_indices,
				"Repeated compilation produces byte-equivalent biome fields for chunk %d." % index
			)
			_expect(
				first_compile[index].traversal_flags == second_compile[index].traversal_flags,
				"Repeated compilation produces byte-equivalent traversal fields for chunk %d." % index
			)

	var query := TerrainQuery.new()
	_expect(query.configure(REGION, first_compile), "The query accepts the complete compiled region.")
	var water: TerrainSample = query.sample_cell(Vector2i(2, 10))
	_expect(water.valid and not water.is_walkable(), "The authored river is a valid but blocked terrain sample.")
	_expect(water.surface == TerrainChunkData.Surface.WATER, "The river carries the water surface ID.")

	var lodge_parcel: TerrainSample = query.sample_cell(Vector2i(10, 10))
	_expect(
		lodge_parcel.valid
		and is_equal_approx(lodge_parcel.elevation_level, 1.0)
		and lodge_parcel.surface == TerrainChunkData.Surface.STONE,
		"The protected lodge parcel is flat stone on the middle terrace."
	)

	var lower_road: TerrainSample = query.sample_cell(Vector2i(10, 22))
	_expect(
		is_equal_approx(lower_road.elevation_level, 0.0)
		and lower_road.surface == TerrainChunkData.Surface.PATH,
		"The river approach remains a protected low road."
	)

	var stair_top: TerrainSample = query.sample_cell(Vector2i(15, 20))
	var stair_bottom: TerrainSample = query.sample_cell(Vector2i(15, 25))
	_expect(
		is_equal_approx(stair_top.elevation_level, 1.0)
		and is_equal_approx(stair_bottom.elevation_level, 0.0),
		"The wide front stair connects the middle terrace to the low road."
	)
	_expect(
		query.can_traverse_cells(Vector2i(15, 21), Vector2i(15, 22)),
		"Adjacent stair treads form a traversable elevation transition."
	)

	var ramp_start: TerrainSample = query.sample_cell(Vector2i(27, 12))
	var ramp_end: TerrainSample = query.sample_cell(Vector2i(35, 12))
	_expect(
		is_equal_approx(ramp_start.elevation_level, 1.0)
		and is_equal_approx(ramp_end.elevation_level, 2.0),
		"The broad eastern ramp connects village and highland elevations."
	)
	_expect(
		query.can_traverse_cells(Vector2i(30, 12), Vector2i(31, 12)),
		"Adjacent ramp cells remain traversable."
	)
	_expect(
		query.is_edge_blocked(Vector2i(8, 21), Vector2i(8, 22)),
		"An unstamped terrace edge is a blocked cliff."
	)
	var first_scatter: Array[TerrainScatterPlacement] = TerrainScatterGenerator.generate_chunk(
		SCATTER_PROFILE,
		REGION,
		query,
		Vector2i(0, 1)
	)
	var second_scatter: Array[TerrainScatterPlacement] = TerrainScatterGenerator.generate_chunk(
		SCATTER_PROFILE,
		REGION,
		query,
		Vector2i(0, 1)
	)
	_expect(not first_scatter.is_empty(), "The southern biome chunk produces deterministic scatter.")
	_expect(
		first_scatter.size() == second_scatter.size(),
		"Repeated biome scatter generation produces the same placement count."
	)
	for index: int in range(mini(first_scatter.size(), second_scatter.size())):
		_expect(
			first_scatter[index].world_position.is_equal_approx(second_scatter[index].world_position)
			and first_scatter[index].visual_id == second_scatter[index].visual_id,
			"Repeated biome scatter generation preserves placement %d." % index
		)
		var scatter_sample: TerrainSample = query.sample_at(first_scatter[index].world_position)
		_expect(
			scatter_sample.valid and scatter_sample.surface == TerrainChunkData.Surface.GRASS,
			"Biome scatter placement %d avoids roads, water, stairs, ramps, and parcels." % index
		)
	_expect(
		query.can_traverse_cells(Vector2i(35, 44), Vector2i(36, 44)),
		"The southern basin road crosses onto its raised shelf through a traversable ramp."
	)
	_expect(
		is_equal_approx(query.sample_cell(Vector2i(50, 54)).elevation_level, 2.0),
		"The expanded district reserves a second highland terrace for future settlement content."
	)

	var terrain_world := TERRAIN_WORLD_SCENE.instantiate() as TerrainWorld
	add_child(terrain_world)
	await get_tree().process_frame
	_expect(terrain_world.get_active_chunk_count() == 4, "The reusable runtime scene materializes the full four-chunk district.")
	_expect(terrain_world.get_collision_shape_count() > 0, "The runtime builds physical barriers from compiled topology.")

	var target := ElevationTarget.new()
	target.position = query.cell_to_world_center(Vector2i(10, 10))
	add_child(target)
	var follower: TerrainFollower2D = terrain_world.attach_follower(target, false)
	follower.sync_now()
	_expect(
		is_equal_approx(target.ground_elevation_pixels, REGION.elevation_step_pixels),
		"A terrain follower projects an explicitly supplied target onto the middle terrace."
	)

	terrain_world.enable_streaming(target, 0)
	_expect(
		terrain_world.get_active_chunk_count() == 1,
		"A zero-radius stream keeps only the focus chunk materialized."
	)
	target.position = query.cell_to_world_center(Vector2i(50, 50))
	await get_tree().physics_frame
	await get_tree().physics_frame
	_expect(
		terrain_world.get_active_chunk_count() == 1,
		"Crossing a chunk boundary swaps the active terrain node without loading the full district."
	)
	_expect(
		terrain_world.get_collision_shape_count() > 0,
		"The streamed destination activates its collision together with its presentation."
	)
	terrain_world.disable_streaming()
	_expect(
		terrain_world.get_active_chunk_count() == 4,
		"Disabling streaming restores every compiled chunk for editor previews."
	)

	terrain_world.queue_free()
	target.queue_free()
	if _failures.is_empty():
		print("TERRAIN_WORLD_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("TERRAIN_WORLD_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

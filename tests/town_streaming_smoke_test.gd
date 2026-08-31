extends Node

const REGION: TerrainRegionDefinition = preload(
	"res://features/terrain_world/content/mossglass_town_region.tres"
)
const TOWN_WORLD_SCENE: PackedScene = preload(
	"res://features/terrain_world/mossglass_town_world.tscn"
)
const TOWN: SettlementDefinition = preload(
	"res://features/settlement/content/mossglass_town.tres"
)
const SCATTER: TerrainScatterProfile = preload(
	"res://features/terrain_world/content/mossglass_town_scatter_profile.tres"
)
const ACTIVATION_BATCH_BUDGET_USEC: int = 100000

var _failures: Array[String] = []


func _ready() -> void:
	var first_compile: Array[TerrainChunkData] = TerrainCompiler.compile_region(REGION)
	var second_compile: Array[TerrainChunkData] = TerrainCompiler.compile_region(REGION)
	_expect(first_compile.size() == 12, "The town region compiles into a 4x3 twelve-chunk district.")
	_expect(second_compile.size() == first_compile.size(), "Repeated town compilation preserves chunk count.")
	for index: int in range(mini(first_compile.size(), second_compile.size())):
		_expect(
			first_compile[index].elevations == second_compile[index].elevations
			and first_compile[index].surface_ids == second_compile[index].surface_ids
			and first_compile[index].biome_indices == second_compile[index].biome_indices
			and first_compile[index].traversal_flags == second_compile[index].traversal_flags,
			"Town chunk %d is deterministic across compilation." % index
		)

	var query := TerrainQuery.new()
	_expect(query.configure(REGION, first_compile), "The town query accepts all twelve compiled chunks.")
	_expect(
		query.can_traverse_cells(Vector2i(31, 56), Vector2i(32, 56))
		and query.can_traverse_cells(Vector2i(63, 56), Vector2i(64, 56))
		and query.can_traverse_cells(Vector2i(95, 56), Vector2i(96, 56)),
		"The main town road crosses every horizontal chunk seam without a topology break."
	)
	_expect(
		is_equal_approx(query.sample_cell(Vector2i(60, 20)).elevation_level, 2.0)
		and is_equal_approx(query.sample_cell(Vector2i(60, 84)).elevation_level, 1.0),
		"The civic highland and southern service district retain distinct authored elevations."
	)
	_expect(TOWN.tier == SettlementDefinition.Tier.TOWN, "Mossglass is authored as a town-scale settlement.")
	_expect(TOWN.props.size() == 38, "The town contains thirty-eight authored, stable building definitions.")
	_expect(TOWN.get_prop_count(AdventureProp.Kind.CIVIC_HALL) == 1, "The town has one civic landmark.")
	_expect(TOWN.get_prop_count(AdventureProp.Kind.COTTAGE) == 30, "Thirty cottages establish residential scale.")
	_expect(TOWN.get_prop_count(AdventureProp.Kind.MARKET_STALL) == 6, "Six market stalls establish a commercial district.")
	_expect(TOWN.get_prop_count(AdventureProp.Kind.HOUSE) == 1, "The town inn reuses the larger lodge-scale building contract.")

	var terrain_world := TOWN_WORLD_SCENE.instantiate() as TerrainWorld
	add_child(terrain_world)
	await get_tree().process_frame
	var props := Node2D.new()
	props.name = "TownProps"
	props.y_sort_enabled = true
	add_child(props)
	var settlement_runtime := SettlementRuntime.new()
	add_child(settlement_runtime)
	var scatter_runtime := TerrainScatterRuntime.new()
	add_child(scatter_runtime)
	_expect(
		settlement_runtime.configure(TOWN, terrain_world, props, null),
		"The town's authored buildings bind to chunk activation."
	)
	_expect(
		scatter_runtime.configure(SCATTER, terrain_world, props, null),
		"The town's biome scatter binds to the same chunk lifecycle."
	)
	_expect(
		terrain_world.get_active_chunk_count() == 0,
		"A town-scale world starts cold instead of materializing all twelve chunks."
	)
	_expect(settlement_runtime.get_active_prop_count() == 0, "A cold town starts with no building nodes.")
	var focus := Node2D.new()
	focus.position = query.cell_to_world_center(Vector2i(60, 56))
	add_child(focus)
	var activation_started: int = Time.get_ticks_usec()
	terrain_world.enable_streaming(focus, 1)
	var initial_activation_usec: int = Time.get_ticks_usec() - activation_started
	_expect(
		terrain_world.get_active_chunk_count() <= terrain_world.max_chunk_activations_per_frame,
		"Initial town activation is capped to one staged batch."
	)
	_expect(
		initial_activation_usec <= ACTIVATION_BATCH_BUDGET_USEC,
		"The first activation batch stays below the %d usec smoke budget (measured %d)." % [
			ACTIVATION_BATCH_BUDGET_USEC,
			initial_activation_usec,
		]
	)
	for _frame: int in range(12):
		if terrain_world.is_streaming_settled():
			break
		await get_tree().physics_frame
	_expect(
		terrain_world.get_active_chunk_count() == 9,
		"A central town focus settles on only its 3x3 neighbor ring."
	)
	_expect(
		settlement_runtime.get_active_prop_count() == _expected_town_prop_count(terrain_world),
		"Central streaming activates exactly the buildings owned by the nine live chunks."
	)
	_expect(scatter_runtime.get_active_prop_count() > 0, "Biome scatter fills the unsettled river and boundary land.")
	_expect(
		terrain_world.get_peak_activation_batch_usec() <= ACTIVATION_BATCH_BUDGET_USEC,
		"Every staged activation batch stays below the %d usec budget (peak %d)." % [
			ACTIVATION_BATCH_BUDGET_USEC,
			terrain_world.get_peak_activation_batch_usec(),
		]
	)
	_expect(terrain_world.get_collision_shape_count() > 0, "Streamed town chunks activate collision with presentation.")

	focus.position = query.cell_to_world_center(Vector2i(112, 80))
	for _frame: int in range(12):
		await get_tree().physics_frame
		if terrain_world.is_streaming_settled():
			break
	_expect(
		terrain_world.get_active_chunk_count() == 4,
		"A corner focus retains only the four valid chunks in its clipped neighbor ring."
	)
	_expect(
		settlement_runtime.get_active_prop_count() == _expected_town_prop_count(terrain_world)
		and settlement_runtime.get_active_prop_count() < TOWN.props.size(),
		"Leaving the town center unloads every building outside the four live chunks."
	)
	print("TOWN_STREAMING_METRIC: initial_usec=%d peak_batch_usec=%d" % [
		initial_activation_usec,
		terrain_world.get_peak_activation_batch_usec(),
	])
	var active_before_focus_exit: int = terrain_world.get_active_chunk_count()
	focus.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	_expect(
		terrain_world.get_active_chunk_count() == active_before_focus_exit,
		"Losing the streaming focus stops work without eagerly materializing the whole town."
	)

	terrain_world.queue_free()
	props.queue_free()
	settlement_runtime.queue_free()
	scatter_runtime.queue_free()
	if _failures.is_empty():
		print("TOWN_STREAMING_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("TOWN_STREAMING_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expected_town_prop_count(terrain_world: TerrainWorld) -> int:
	var active_coords: Array[Vector2i] = terrain_world.get_active_chunk_coords()
	var count: int = 0
	for definition in TOWN.props:
		if definition != null and terrain_world.world_to_chunk(definition.world_position) in active_coords:
			count += 1
	return count

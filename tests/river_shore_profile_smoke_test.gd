extends Node

const RIVER_LAYOUT: Script = preload(
	"res://features/homestead_3d/river_layout_3d.gd"
)
const RIVER_SHORE_PROFILE: Script = preload(
	"res://features/homestead_3d/river_shore_profile_3d.gd"
)
const SAMPLE_STEP := 0.25

var _failures: Array[String] = []


func _ready() -> void:
	_verify_bridge_pin()
	_verify_full_occlusion_interval()
	_verify_widths_and_determinism()
	_verify_geometry_breakpoints_and_west_throat()
	_verify_two_owner_contract()
	_finish()


func _verify_bridge_pin() -> void:
	var base_sample: Vector2 = RIVER_LAYOUT.sample_at_x(
		RIVER_SHORE_PROFILE.BRIDGE_PIN_X
	)
	var effective_shores: Vector2 = RIVER_SHORE_PROFILE.sample_effective_shores(
		RIVER_SHORE_PROFILE.BRIDGE_PIN_X
	)
	_expect(
		base_sample.is_equal_approx(Vector2(16.4910831312, 4.2)),
		"The unchanged RiverLayout retains the approved bridge pin."
	)
	_expect(
		effective_shores.is_equal_approx(Vector2(12.291083, 15.291083))
		and is_equal_approx(effective_shores.y - effective_shores.x, 3.0),
		"The bridge pin owns the compact three-unit under-bridge water pocket."
	)
	_expect(
		not RIVER_SHORE_PROFILE.is_land_at_x(RIVER_SHORE_PROFILE.BRIDGE_PIN_X),
		"The bridge pin is water, not an occlusion island."
	)


func _verify_full_occlusion_interval() -> void:
	var occluded_points := PackedFloat32Array([
		RIVER_SHORE_PROFILE.FULL_OCCLUSION_MIN_X,
		0.0,
		RIVER_SHORE_PROFILE.FULL_OCCLUSION_MAX_X,
	])
	for world_x: float in occluded_points:
		var shores: Vector2 = RIVER_SHORE_PROFILE.sample_effective_shores(world_x)
		_expect(
			RIVER_SHORE_PROFILE.is_in_full_occlusion_interval(world_x),
			"The authored bridge-exit interval explicitly reports full occlusion."
		)
		_expect(
			RIVER_SHORE_PROFILE.is_land_at_x(world_x)
			and is_zero_approx(shores.y - shores.x),
			"A fully occluded sample resolves to collision-backed land with no open water."
		)
	_expect(
		not RIVER_SHORE_PROFILE.is_land_at_x(
			RIVER_SHORE_PROFILE.FULL_OCCLUSION_MIN_X - 0.001
		)
		and not RIVER_SHORE_PROFILE.is_land_at_x(
			RIVER_SHORE_PROFILE.FULL_OCCLUSION_MAX_X + 0.001
		),
		"Samples immediately outside the explicit interval remain passable water."
	)


func _verify_widths_and_determinism() -> void:
	var first_samples: PackedVector4Array = RIVER_SHORE_PROFILE.sample_world_segment(
		SAMPLE_STEP
	)
	var second_samples: PackedVector4Array = RIVER_SHORE_PROFILE.sample_world_segment(
		SAMPLE_STEP
	)
	_expect(
		first_samples == second_samples,
		"Repeated effective-shore sampling is byte-equivalent and deterministic."
	)
	_expect(
		first_samples.size() == 257,
		"A quarter-unit profile sample covers -32 through 32 inclusively."
	)
	for sample: Vector4 in first_samples:
		var open_width := sample.z - sample.y
		if is_equal_approx(sample.w, 1.0):
			_expect(
				open_width < RIVER_SHORE_PROFILE.MIN_PASSABLE_WATER_WIDTH,
				"Land samples never expose a subminimum water sliver."
			)
		else:
			_expect(
				open_width >= RIVER_SHORE_PROFILE.MIN_PASSABLE_WATER_WIDTH,
				"Every non-occluded sample has positive passable water width."
			)

	var cove_sample: Vector2 = RIVER_SHORE_PROFILE.sample_effective_shores(-12.0)
	var base_cove: Vector2 = RIVER_LAYOUT.sample_at_x(-12.0)
	_expect(
		cove_sample.x < base_cove.x - base_cove.y
		and cove_sample.y > base_cove.x + base_cove.y,
		"Negative insets expose the authored western cove on both banks."
	)


func _verify_two_owner_contract() -> void:
	var owner_names: PackedStringArray = RIVER_SHORE_PROFILE.get_water_area_owner_names()
	_expect(
		RIVER_SHORE_PROFILE.WATER_AREA_OWNER_COUNT == 2
		and owner_names == PackedStringArray([&"WestWater", &"EastWater"]),
		"The profile preserves exactly the existing WestWater and EastWater owners."
	)


func _verify_geometry_breakpoints_and_west_throat() -> void:
	var first_breakpoints: PackedFloat32Array = (
		RIVER_SHORE_PROFILE.get_geometry_breakpoints()
	)
	var second_breakpoints: PackedFloat32Array = (
		RIVER_SHORE_PROFILE.get_geometry_breakpoints()
	)
	_expect(
		first_breakpoints == second_breakpoints
		and first_breakpoints.has(-14.8)
		and first_breakpoints.has(-14.5)
		and first_breakpoints.has(-2.85),
		"Geometry builders receive deterministic base-curve and west-throat endpoints."
	)
	for index: int in range(first_breakpoints.size() - 1):
		_expect(
			first_breakpoints[index] < first_breakpoints[index + 1],
			"River geometry breakpoints remain strictly ordered."
		)
	var far_west_width: float = RIVER_SHORE_PROFILE.sample_open_width(-16.0)
	var west_basin_width: float = RIVER_SHORE_PROFILE.sample_open_width(-14.5)
	var throat_width: float = RIVER_SHORE_PROFILE.sample_open_width(-2.85)
	_expect(
		far_west_width >= 0.7 and far_west_width <= 1.0,
		"The far-west bank closes to the measured narrow inlet without collapsing."
	)
	_expect(
		west_basin_width >= 10.0,
		"The narrow inlet opens back into the broad western basin."
	)
	_expect(
		throat_width >= 1.0 and throat_width <= 1.4,
		"The west throat stays narrow while visibly connecting the basin to the bridge pocket."
	)
	var pocket_probe_x := -4.0
	while pocket_probe_x < RIVER_SHORE_PROFILE.FULL_OCCLUSION_MIN_X:
		_expect(
			not RIVER_SHORE_PROFILE.is_land_at_x(pocket_probe_x),
			"The basin-to-bridge pocket remains one continuous water surface."
		)
		pocket_probe_x += 0.05
	_expect(
		RIVER_SHORE_PROFILE.sample_effective_shores(4.25).is_equal_approx(
			Vector2(15.38, 21.68)
		),
		"The eastern shoreline trims 0.8 world unit symmetrically at its visible landmark."
	)
	_expect(
		RIVER_SHORE_PROFILE.water_area_owner_for_x(-32.0) == &"WestWater"
		and RIVER_SHORE_PROFILE.water_area_owner_for_x(32.0) == &"EastWater",
		"World-edge samples route to the two established Area3D owners."
	)
	_expect(
		RIVER_SHORE_PROFILE.WEST_OWNER_MAX_X >= -2.85
		and RIVER_SHORE_PROFILE.WEST_OWNER_MAX_X < RIVER_SHORE_PROFILE.BRIDGE_PIN_X
		and RIVER_SHORE_PROFILE.EAST_OWNER_MIN_X > RIVER_SHORE_PROFILE.FULL_OCCLUSION_MAX_X
		and RIVER_SHORE_PROFILE.EAST_OWNER_MIN_X - RIVER_SHORE_PROFILE.FULL_OCCLUSION_MAX_X <= 0.11,
		"The two hazard owners meet the visible throat and east occlusion without entering the bridge pocket."
	)
	_expect(
		RIVER_SHORE_PROFILE.water_area_owner_for_x(
			RIVER_SHORE_PROFILE.BRIDGE_PIN_X
		).is_empty(),
		"The bridge safety corridor does not invent a third water owner."
	)


func _finish() -> void:
	if _failures.is_empty():
		print("RIVER_SHORE_PROFILE_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("RIVER_SHORE_PROFILE_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

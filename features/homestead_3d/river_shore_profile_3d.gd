extends RefCounted

## Deterministic effective shoreline profile layered over the smooth base river.
##
## RiverLayout remains the authoritative continuous channel. This profile only
## describes authored coves and collision-backed land incursions used by water
## rendering, bank terrain, hazard shapes, and shoreline scatter. Segment
## samples are Vector4(world_x, north_z, south_z, is_land).

const RIVER_LAYOUT: Script = preload(
	"res://features/homestead_3d/river_layout_3d.gd"
)

const DEFAULT_SAMPLE_STEP := 0.5
const MIN_PASSABLE_WATER_WIDTH := 0.5
const BRIDGE_PIN_X := -2.05
const BRIDGE_HAZARD_CENTER_X := -1.022756
const OWNER_GAP_HALF_WIDTH := 1.73
const WEST_OWNER_MAX_X := BRIDGE_HAZARD_CENTER_X - OWNER_GAP_HALF_WIDTH
const EAST_OWNER_MIN_X := BRIDGE_HAZARD_CENTER_X + OWNER_GAP_HALF_WIDTH
const FULL_OCCLUSION_MIN_X := -1.15
const FULL_OCCLUSION_MAX_X := 0.7
const WATER_AREA_OWNER_COUNT := 2
const WEST_WATER_OWNER: StringName = &"WestWater"
const EAST_WATER_OWNER: StringName = &"EastWater"

# Positive values move land into the river. Negative values extend a cove away
# from the base bank. The half-unit-scale knots keep the silhouette irregular
# without separating render and collision: every consumer samples this profile.
static var _NORTH_LAND_INSET_CURVE := PackedVector2Array([
	Vector2(RIVER_LAYOUT.WORLD_MIN_X, 0.0),
	Vector2(-18.0, 4.0),
	Vector2(-16.0, 5.2),
	Vector2(-15.5, 4.55),
	Vector2(-15.0, 3.0),
	Vector2(-14.5, 1.9),
	Vector2(-14.0, 0.8),
	Vector2(-13.5, -1.35),
	Vector2(-13.0, -2.65),
	Vector2(-12.5, -3.55),
	Vector2(-12.0, -3.8),
	Vector2(-11.5, -3.35),
	Vector2(-11.0, -2.85),
	Vector2(-10.5, -1.85),
	Vector2(-10.0, -2.0),
	Vector2(-9.5, -2.35),
	Vector2(-9.0, -2.2),
	Vector2(-8.5, 0.25),
	Vector2(-8.0, 2.05),
	Vector2(-7.5, 3.25),
	Vector2(-7.0, 3.1),
	Vector2(-6.5, 3.7),
	Vector2(-6.27, 3.6),
	Vector2(-5.75, 3.85),
	Vector2(-5.25, 3.55),
	Vector2(-4.75, 3.95),
	Vector2(-4.25, 3.55),
	Vector2(-4.0, 3.5),
	Vector2(-3.5, 3.5),
	Vector2(-2.85, 3.3),
	Vector2(-2.5, 2.5),
	Vector2(BRIDGE_PIN_X, 0.0),
	Vector2(-1.7, 0.2),
	Vector2(-1.3, 0.7),
	Vector2(FULL_OCCLUSION_MIN_X, 0.8),
	Vector2(FULL_OCCLUSION_MAX_X, 2.0),
	Vector2(1.2, 1.9),
	Vector2(1.7, 1.65),
	Vector2(2.2, 1.6),
	Vector2(2.7, 1.2),
	Vector2(3.2, 1.0),
	Vector2(3.7, 0.65),
	Vector2(4.25, 0.5),
	Vector2(4.7, 0.35),
	Vector2(5.2, 0.2),
	Vector2(5.7, 0.1),
	Vector2(6.2, 0.2),
	Vector2(6.7, 0.4),
	Vector2(7.2, 0.45),
	Vector2(7.7, 0.4),
	Vector2(8.2, 0.4),
	Vector2(10.0, 0.35),
	Vector2(12.0, 0.25),
	Vector2(16.0, 0.15),
	Vector2(RIVER_LAYOUT.WORLD_MAX_X, 0.0),
])

static var _SOUTH_LAND_INSET_CURVE := PackedVector2Array([
	Vector2(RIVER_LAYOUT.WORLD_MIN_X, 0.0),
	Vector2(-18.0, 5.0),
	Vector2(-16.0, 7.4),
	Vector2(-15.5, 7.45),
	Vector2(-15.0, 6.8),
	Vector2(-14.75, 3.0),
	Vector2(-14.5, -0.6),
	Vector2(-14.0, -0.9),
	Vector2(-13.5, -1.2),
	Vector2(-13.0, -1.45),
	Vector2(-12.5, -1.25),
	Vector2(-12.0, -1.7),
	Vector2(-11.5, -1.0),
	Vector2(-11.0, -0.4),
	Vector2(-10.5, -0.1),
	Vector2(-10.0, 0.0),
	Vector2(-9.5, 0.15),
	Vector2(-9.0, 0.4),
	Vector2(-8.5, 0.8),
	Vector2(-8.0, 1.2),
	Vector2(-7.5, 1.0),
	Vector2(-7.0, 1.65),
	Vector2(-6.5, 1.9),
	Vector2(-6.27, 2.2),
	Vector2(-5.75, 1.9),
	Vector2(-5.25, 2.45),
	Vector2(-4.75, 2.15),
	Vector2(-4.25, 2.5),
	Vector2(-4.0, 2.55),
	Vector2(-3.5, 3.2),
	Vector2(-2.85, 4.0),
	Vector2(-2.5, 4.8),
	Vector2(BRIDGE_PIN_X, 5.4),
	Vector2(-1.7, 5.7),
	Vector2(-1.3, 6.8),
	Vector2(FULL_OCCLUSION_MIN_X, 6.9),
	Vector2(FULL_OCCLUSION_MAX_X, 2.1),
	Vector2(1.2, 2.0),
	Vector2(1.7, 1.75),
	Vector2(2.2, 1.6),
	Vector2(2.7, 1.3),
	Vector2(3.2, 1.15),
	Vector2(3.7, 1.0),
	Vector2(4.25, 1.0),
	Vector2(4.7, 1.3),
	Vector2(5.2, 1.55),
	Vector2(5.7, 1.75),
	Vector2(6.2, 1.7),
	Vector2(6.7, 1.3),
	Vector2(7.2, 0.85),
	Vector2(7.7, 0.5),
	Vector2(8.2, 0.4),
	Vector2(10.0, 0.35),
	Vector2(12.0, 0.3),
	Vector2(16.0, 0.2),
	Vector2(RIVER_LAYOUT.WORLD_MAX_X, 0.0),
])

static func sample_effective_shores(world_x: float) -> Vector2:
	var clamped_x := clampf(
		world_x,
		RIVER_LAYOUT.WORLD_MIN_X,
		RIVER_LAYOUT.WORLD_MAX_X
	)
	var base_sample: Vector2 = RIVER_LAYOUT.sample_at_x(clamped_x)
	if is_in_full_occlusion_interval(clamped_x):
		return Vector2(base_sample.x, base_sample.x)

	var north_z := (
		base_sample.x
		- base_sample.y
		+ _sample_linear_curve(_NORTH_LAND_INSET_CURVE, clamped_x)
	)
	var south_z := (
		base_sample.x
		+ base_sample.y
		- _sample_linear_curve(_SOUTH_LAND_INSET_CURVE, clamped_x)
	)
	if south_z - north_z < MIN_PASSABLE_WATER_WIDTH:
		var midpoint := (north_z + south_z) * 0.5
		return Vector2(midpoint, midpoint)
	return Vector2(north_z, south_z)


static func sample_open_width(world_x: float) -> float:
	var shores := sample_effective_shores(world_x)
	return maxf(0.0, shores.y - shores.x)


static func is_land_at_x(world_x: float) -> bool:
	return sample_open_width(world_x) < MIN_PASSABLE_WATER_WIDTH


static func is_in_full_occlusion_interval(world_x: float) -> bool:
	return world_x >= FULL_OCCLUSION_MIN_X and world_x <= FULL_OCCLUSION_MAX_X


static func sample_world_segment(step: float = DEFAULT_SAMPLE_STEP) -> PackedVector4Array:
	return sample_segment(RIVER_LAYOUT.WORLD_MIN_X, RIVER_LAYOUT.WORLD_MAX_X, step)


static func sample_segment(
	min_x: float,
	max_x: float,
	step: float = DEFAULT_SAMPLE_STEP
) -> PackedVector4Array:
	var samples := PackedVector4Array()
	if step <= 0.0 or max_x < min_x:
		return samples

	var clamped_min := clampf(min_x, RIVER_LAYOUT.WORLD_MIN_X, RIVER_LAYOUT.WORLD_MAX_X)
	var clamped_max := clampf(max_x, RIVER_LAYOUT.WORLD_MIN_X, RIVER_LAYOUT.WORLD_MAX_X)
	if clamped_max < clamped_min:
		return samples

	var interval_count := floori((clamped_max - clamped_min) / step + 0.000001)
	for index: int in range(interval_count + 1):
		_append_sample(samples, clamped_min + float(index) * step)
	if samples.is_empty() or not is_equal_approx(samples[-1].x, clamped_max):
		_append_sample(samples, clamped_max)
	return samples


static func get_water_area_owner_names() -> PackedStringArray:
	return PackedStringArray([WEST_WATER_OWNER, EAST_WATER_OWNER])


static func get_geometry_breakpoints() -> PackedFloat32Array:
	var breakpoints := PackedFloat32Array()
	for curve: PackedVector2Array in [
		_NORTH_LAND_INSET_CURVE,
		_SOUTH_LAND_INSET_CURVE,
		RIVER_LAYOUT.get_authored_centerline_points(),
	]:
		for point: Vector2 in curve:
			if not breakpoints.has(point.x):
				breakpoints.append(point.x)
	breakpoints.sort()
	return breakpoints


static func water_area_owner_for_x(world_x: float) -> StringName:
	if world_x <= WEST_OWNER_MAX_X:
		return WEST_WATER_OWNER
	if world_x >= EAST_OWNER_MIN_X:
		return EAST_WATER_OWNER
	return &""


static func _append_sample(samples: PackedVector4Array, world_x: float) -> void:
	var shores := sample_effective_shores(world_x)
	var is_land := shores.y - shores.x < MIN_PASSABLE_WATER_WIDTH
	samples.append(Vector4(world_x, shores.x, shores.y, 1.0 if is_land else 0.0))


static func _sample_linear_curve(points: PackedVector2Array, world_x: float) -> float:
	if points.is_empty():
		return 0.0
	if world_x <= points[0].x:
		return points[0].y
	if world_x >= points[-1].x:
		return points[-1].y

	for index: int in range(points.size() - 1):
		var left := points[index]
		var right := points[index + 1]
		if world_x <= right.x:
			return lerpf(left.y, right.y, inverse_lerp(left.x, right.x, world_x))
	return points[-1].y

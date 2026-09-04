extends RefCounted

## Deterministic authored river layout for the homestead world.
##
## Vector2 control points use (world_x, center_z). Segment samples use
## Vector3(world_x, center_z, half_width) so future render and collision builders
## can consume one compact, ordered data stream without owning river-shape state.

const WORLD_MIN_X := -32.0
const WORLD_MAX_X := 32.0
const DEFAULT_SAMPLE_STEP := 0.5

static var _AUTHORED_CENTERLINE_POINTS := PackedVector2Array([
	Vector2(-14.8, 9.5),
	Vector2(-6.27, 15.8),
	Vector2(-2.05, 16.4910831312),
	Vector2(4.25, 18.78),
])

# The edge controls continue the authored endpoint headings to the world bounds.
# They prevent either bank from turning abruptly at the visible world limits.
static var _CENTERLINE_CURVE := PackedVector2Array([
	Vector2(WORLD_MIN_X, -1.0),
	Vector2(-14.8, 9.5),
	Vector2(-6.27, 15.8),
	Vector2(-2.05, 16.4910831312),
	Vector2(4.25, 18.78),
	Vector2(WORLD_MAX_X, 30.0),
])

# Width narrows gradually from the broad western basin to the eastern channel.
static var _HALF_WIDTH_CURVE := PackedVector2Array([
	Vector2(WORLD_MIN_X, 8.5),
	Vector2(-14.8, 6.5),
	Vector2(-6.27, 4.5),
	Vector2(-2.05, 4.2),
	Vector2(4.25, 3.9),
	Vector2(WORLD_MAX_X, 3.0),
])


static func get_authored_centerline_points() -> PackedVector2Array:
	return _AUTHORED_CENTERLINE_POINTS.duplicate()


static func sample_at_x(world_x: float) -> Vector2:
	var clamped_x := clampf(world_x, WORLD_MIN_X, WORLD_MAX_X)
	return Vector2(
		_sample_curve(_CENTERLINE_CURVE, clamped_x),
		_sample_curve(_HALF_WIDTH_CURVE, clamped_x)
	)


static func sample_center_z(world_x: float) -> float:
	return sample_at_x(world_x).x


static func sample_half_width(world_x: float) -> float:
	return sample_at_x(world_x).y


static func sample_world_segment(step: float = DEFAULT_SAMPLE_STEP) -> PackedVector3Array:
	return sample_segment(WORLD_MIN_X, WORLD_MAX_X, step)


static func sample_segment(
	min_x: float,
	max_x: float,
	step: float = DEFAULT_SAMPLE_STEP
) -> PackedVector3Array:
	var samples := PackedVector3Array()
	if step <= 0.0 or max_x < min_x:
		return samples

	var clamped_min := clampf(min_x, WORLD_MIN_X, WORLD_MAX_X)
	var clamped_max := clampf(max_x, WORLD_MIN_X, WORLD_MAX_X)
	if clamped_max < clamped_min:
		return samples

	var interval_count := floori((clamped_max - clamped_min) / step + 0.000001)
	for index: int in range(interval_count + 1):
		_append_sample(samples, clamped_min + float(index) * step)
	if samples.is_empty() or not is_equal_approx(samples[-1].x, clamped_max):
		_append_sample(samples, clamped_max)
	return samples


static func _append_sample(samples: PackedVector3Array, world_x: float) -> void:
	var river_sample := sample_at_x(world_x)
	samples.append(Vector3(world_x, river_sample.x, river_sample.y))


static func _sample_curve(points: PackedVector2Array, world_x: float) -> float:
	if points.is_empty():
		return 0.0
	if world_x <= points[0].x:
		return points[0].y
	if world_x >= points[-1].x:
		return points[-1].y

	var segment := 0
	for index: int in range(points.size() - 1):
		if world_x <= points[index + 1].x:
			segment = index
			break

	var left := points[segment]
	var right := points[segment + 1]
	var span := right.x - left.x
	var t := (world_x - left.x) / span
	var left_tangent := _curve_tangent(points, segment)
	var right_tangent := _curve_tangent(points, segment + 1)
	var t_squared := t * t
	var t_cubed := t_squared * t
	var h00 := 2.0 * t_cubed - 3.0 * t_squared + 1.0
	var h10 := t_cubed - 2.0 * t_squared + t
	var h01 := -2.0 * t_cubed + 3.0 * t_squared
	var h11 := t_cubed - t_squared
	return (
		h00 * left.y
		+ h10 * span * left_tangent
		+ h01 * right.y
		+ h11 * span * right_tangent
	)


static func _curve_tangent(points: PackedVector2Array, index: int) -> float:
	if index <= 0:
		return _secant(points[0], points[1])
	if index >= points.size() - 1:
		return _secant(points[-2], points[-1])

	var left_slope := _secant(points[index - 1], points[index])
	var right_slope := _secant(points[index], points[index + 1])
	if is_zero_approx(left_slope) or is_zero_approx(right_slope):
		return 0.0
	if signf(left_slope) != signf(right_slope):
		return 0.0
	return (left_slope + right_slope) * 0.5


static func _secant(left: Vector2, right: Vector2) -> float:
	return (right.y - left.y) / (right.x - left.x)

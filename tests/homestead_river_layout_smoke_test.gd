extends Node

const RIVER_LAYOUT: Script = preload(
	"res://features/homestead_3d/river_layout_3d.gd"
)
const SAMPLE_STEP := 0.5
const MAX_CENTER_DELTA := 0.6
const MAX_WIDTH_DELTA := 0.18
# Curvature is the change in sampled tangent per world unit. At the 0.5-unit
# production sampling interval these bounds limit the centerline's second finite
# difference to 0.0325 units and either bank's to 0.00875 units. That permits the
# deliberate broad turn while still rejecting a visible or physical kink.
const MAX_CENTER_CURVATURE := 0.28
const MAX_WIDTH_CURVATURE := 0.075
const TANGENT_PROBE_STEP := 0.01
const MAX_CONTROL_TANGENT_GAP := 0.005

var _failures: Array[String] = []


func _ready() -> void:
	var authored_points: PackedVector2Array = RIVER_LAYOUT.get_authored_centerline_points()
	_expect(authored_points.size() == 4, "The layout owns the four approved centerline landmarks, including the pinned bridge sample.")
	_expect(
		authored_points.size() == 4
		and authored_points[0].is_equal_approx(Vector2(-14.8, 9.5))
		and authored_points[1].is_equal_approx(Vector2(-6.27, 15.8))
		and authored_points[2].is_equal_approx(Vector2(-2.05, 16.4910831312))
		and authored_points[3].is_equal_approx(Vector2(4.25, 18.78)),
		"The authored river landmarks preserve the measured bowl and exact bridge pin."
	)

	var first_samples: PackedVector3Array = RIVER_LAYOUT.sample_world_segment(SAMPLE_STEP)
	var second_samples: PackedVector3Array = RIVER_LAYOUT.sample_world_segment(SAMPLE_STEP)
	_expect(first_samples == second_samples, "Repeated river sampling is byte-equivalent and deterministic.")
	_expect(first_samples.size() == 129, "A 0.5-unit world sample covers -32 through 32 inclusively.")
	if first_samples.is_empty():
		_finish()
		return

	_expect(is_equal_approx(first_samples[0].x, -32.0), "The sampled segment starts at the western world edge.")
	_expect(is_equal_approx(first_samples[-1].x, 32.0), "The sampled segment ends at the eastern world edge.")

	var previous := first_samples[0]
	var previous_center_slope := 0.0
	var previous_width_slope := 0.0
	var max_center_tangent_change := 0.0
	var max_width_tangent_change := 0.0
	var max_center_tangent_x := first_samples[0].x
	var max_width_tangent_x := first_samples[0].x
	for index: int in range(first_samples.size()):
		var sample := first_samples[index]
		_expect(sample.z > 0.0, "River half-width remains positive at sample %d." % index)
		if index == 0:
			continue
		var delta_x := sample.x - previous.x
		var center_delta := sample.y - previous.y
		var width_delta := sample.z - previous.z
		_expect(delta_x > 0.0, "River samples have strictly monotonic x at sample %d." % index)
		_expect(
			absf(center_delta) <= MAX_CENTER_DELTA,
			"River centerline has no positional discontinuity at sample %d." % index
		)
		_expect(
			absf(width_delta) <= MAX_WIDTH_DELTA,
			"River width has no positional discontinuity at sample %d." % index
		)
		var center_slope := center_delta / delta_x
		var width_slope := width_delta / delta_x
		if index > 1:
			var center_tangent_change := absf(center_slope - previous_center_slope)
			var width_tangent_change := absf(width_slope - previous_width_slope)
			if center_tangent_change > max_center_tangent_change:
				max_center_tangent_change = center_tangent_change
				max_center_tangent_x = sample.x
			if width_tangent_change > max_width_tangent_change:
				max_width_tangent_change = width_tangent_change
				max_width_tangent_x = sample.x
		previous_center_slope = center_slope
		previous_width_slope = width_slope
		previous = sample

	var max_center_curvature := max_center_tangent_change / SAMPLE_STEP
	var max_width_curvature := max_width_tangent_change / SAMPLE_STEP
	print(
		"HOMESTEAD_RIVER_LAYOUT_METRICS: "
		+ "max_center_tangent_change=%.6f at x=%.1f, " % [max_center_tangent_change, max_center_tangent_x]
		+ "max_width_tangent_change=%.6f at x=%.1f, " % [max_width_tangent_change, max_width_tangent_x]
		+ "max_center_curvature=%.6f, max_width_curvature=%.6f"
		% [max_center_curvature, max_width_curvature]
	)
	_expect(
		max_center_curvature <= MAX_CENTER_CURVATURE,
		"River centerline curvature stays below the half-unit kink threshold."
	)
	_expect(
		max_width_curvature <= MAX_WIDTH_CURVATURE,
		"River bank-width curvature stays below the half-unit kink threshold."
	)

	var max_center_control_gap := 0.0
	var max_width_control_gap := 0.0
	for landmark: Vector2 in authored_points:
		var center_left_tangent: float = (
			RIVER_LAYOUT.sample_center_z(landmark.x)
			- RIVER_LAYOUT.sample_center_z(landmark.x - TANGENT_PROBE_STEP)
		) / TANGENT_PROBE_STEP
		var center_right_tangent: float = (
			RIVER_LAYOUT.sample_center_z(landmark.x + TANGENT_PROBE_STEP)
			- RIVER_LAYOUT.sample_center_z(landmark.x)
		) / TANGENT_PROBE_STEP
		var width_left_tangent: float = (
			RIVER_LAYOUT.sample_half_width(landmark.x)
			- RIVER_LAYOUT.sample_half_width(landmark.x - TANGENT_PROBE_STEP)
		) / TANGENT_PROBE_STEP
		var width_right_tangent: float = (
			RIVER_LAYOUT.sample_half_width(landmark.x + TANGENT_PROBE_STEP)
			- RIVER_LAYOUT.sample_half_width(landmark.x)
		) / TANGENT_PROBE_STEP
		max_center_control_gap = maxf(
			max_center_control_gap,
			absf(center_right_tangent - center_left_tangent)
		)
		max_width_control_gap = maxf(
			max_width_control_gap,
			absf(width_right_tangent - width_left_tangent)
		)
	_expect(
		max_center_control_gap <= MAX_CONTROL_TANGENT_GAP,
		"Centerline first derivatives remain continuous across authored controls."
	)
	_expect(
		max_width_control_gap <= MAX_CONTROL_TANGENT_GAP,
		"Bank-width first derivatives remain continuous across authored controls."
	)

	var west_sample: Vector2 = RIVER_LAYOUT.sample_at_x(-14.8)
	var center_sample: Vector2 = RIVER_LAYOUT.sample_at_x(0.0)
	var bridge_sample: Vector2 = RIVER_LAYOUT.sample_at_x(-2.05)
	var east_sample: Vector2 = RIVER_LAYOUT.sample_at_x(4.25)
	_expect(west_sample.is_equal_approx(Vector2(9.5, 6.5)), "The western bowl is broad without flooding the target shoreline silhouette.")
	_expect(center_sample.y >= 3.9 and center_sample.y <= 4.5, "The middle river remains approximately four units wide per bank.")
	_expect(bridge_sample.is_equal_approx(Vector2(16.4910831312, 4.2)), "The river preserves the bridge center while tightening both banks around its crossing.")
	_expect(east_sample.is_equal_approx(Vector2(18.78, 3.9)), "The eastern reach rises and narrows through the last authored landmark.")
	_expect(
		is_equal_approx(RIVER_LAYOUT.sample_center_z(-100.0), RIVER_LAYOUT.sample_center_z(-32.0))
		and is_equal_approx(RIVER_LAYOUT.sample_half_width(100.0), RIVER_LAYOUT.sample_half_width(32.0)),
		"Queries outside the authored world clamp deterministically to its edges."
	)

	_finish()


func _finish() -> void:
	if _failures.is_empty():
		print("HOMESTEAD_RIVER_LAYOUT_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("HOMESTEAD_RIVER_LAYOUT_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

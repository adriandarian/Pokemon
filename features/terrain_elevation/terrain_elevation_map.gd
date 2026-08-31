class_name TerrainElevationMap
extends RefCounted

const PIXELS_PER_LEVEL: float = 48.0
const VILLAGE_LEVEL: float = 1.0
const WILDS_LEVEL: float = 0.72
const RIDGE_LEVEL: float = 1.65
const WORLD_RECT := Rect2(0.0, 0.0, 2200.0, 1300.0)

static var VILLAGE_FOOTPRINT := PackedVector2Array([
	Vector2(300.0, 352.0), Vector2(518.0, 252.0), Vector2(895.0, 270.0),
	Vector2(1188.0, 410.0), Vector2(1228.0, 724.0), Vector2(1115.0, 840.0),
	Vector2(940.0, 930.0), Vector2(760.0, 954.0), Vector2(508.0, 928.0),
	Vector2(330.0, 830.0),
])
static var VILLAGE_RAMP := PackedVector2Array([
	Vector2(510.0, 895.0), Vector2(720.0, 910.0),
	Vector2(770.0, 1030.0), Vector2(500.0, 1045.0),
])
static var VILLAGE_FRONT_SEGMENTS: Array[PackedVector2Array] = [
	PackedVector2Array([
		Vector2(1228.0, 724.0), Vector2(1115.0, 840.0),
		Vector2(940.0, 930.0), Vector2(770.0, 952.0),
	]),
	PackedVector2Array([
		Vector2(500.0, 925.0), Vector2(330.0, 830.0), Vector2(300.0, 352.0),
	]),
]

static var WILDS_FOOTPRINT := PackedVector2Array([
	Vector2(1230.0, 246.0), Vector2(1435.0, 220.0), Vector2(1775.0, 234.0),
	Vector2(2010.0, 290.0), Vector2(2044.0, 510.0), Vector2(2020.0, 785.0),
	Vector2(1935.0, 960.0), Vector2(1605.0, 982.0), Vector2(1320.0, 930.0),
	Vector2(1202.0, 768.0),
])
static var WILDS_RAMP := PackedVector2Array([
	Vector2(1168.0, 640.0), Vector2(1375.0, 610.0),
	Vector2(1410.0, 790.0), Vector2(1180.0, 820.0),
])
static var WILDS_FRONT_SEGMENTS: Array[PackedVector2Array] = [
	PackedVector2Array([
		Vector2(2020.0, 785.0), Vector2(1935.0, 960.0),
		Vector2(1605.0, 982.0), Vector2(1390.0, 942.0),
	]),
	PackedVector2Array([
		Vector2(1248.0, 872.0), Vector2(1202.0, 768.0),
	]),
]

static var RIDGE_FOOTPRINT := PackedVector2Array([
	Vector2(0.0, 0.0), Vector2(2200.0, 0.0), Vector2(2200.0, 210.0),
	Vector2(1885.0, 198.0), Vector2(1660.0, 178.0), Vector2(1430.0, 205.0),
	Vector2(1220.0, 172.0), Vector2(1020.0, 198.0), Vector2(820.0, 168.0),
	Vector2(630.0, 202.0), Vector2(448.0, 174.0), Vector2(286.0, 212.0),
	Vector2(142.0, 184.0), Vector2(0.0, 204.0),
])
static var RIDGE_FRONT_SEGMENTS: Array[PackedVector2Array] = [
	PackedVector2Array([
		Vector2(0.0, 204.0), Vector2(142.0, 184.0), Vector2(286.0, 212.0),
		Vector2(448.0, 174.0), Vector2(630.0, 202.0), Vector2(820.0, 168.0),
		Vector2(1020.0, 198.0), Vector2(1220.0, 172.0), Vector2(1430.0, 205.0),
		Vector2(1660.0, 178.0), Vector2(1885.0, 198.0), Vector2(2200.0, 210.0),
	]),
]

static var LODGE_FOUNDATION := PackedVector2Array([
	Vector2(440.0, 606.0), Vector2(780.0, 606.0),
	Vector2(780.0, 634.0), Vector2(440.0, 634.0),
])


static func elevation_level_at(world_position: Vector2) -> float:
	if Geometry2D.is_point_in_polygon(world_position, RIDGE_FOOTPRINT):
		return RIDGE_LEVEL
	if Geometry2D.is_point_in_polygon(world_position, VILLAGE_RAMP):
		return clampf(inverse_lerp(1035.0, 900.0, world_position.y), 0.0, 1.0) * VILLAGE_LEVEL
	if Geometry2D.is_point_in_polygon(world_position, VILLAGE_FOOTPRINT):
		return VILLAGE_LEVEL
	if Geometry2D.is_point_in_polygon(world_position, WILDS_RAMP):
		return clampf(inverse_lerp(1172.0, 1370.0, world_position.x), 0.0, 1.0) * WILDS_LEVEL
	if Geometry2D.is_point_in_polygon(world_position, WILDS_FOOTPRINT):
		return WILDS_LEVEL
	return 0.0


static func elevation_pixels_at(world_position: Vector2) -> float:
	return elevation_level_at(world_position) * PIXELS_PER_LEVEL


static func trail_elevation_level_at(world_position: Vector2) -> float:
	if world_position.x < 1100.0:
		return clampf(inverse_lerp(1060.0, 840.0, world_position.y), 0.0, 1.0) * VILLAGE_LEVEL
	if world_position.x < 1390.0:
		return lerpf(
			VILLAGE_LEVEL,
			WILDS_LEVEL,
			clampf(inverse_lerp(1100.0, 1390.0, world_position.x), 0.0, 1.0)
		)
	return WILDS_LEVEL


static func to_view(world_position: Vector2, level_override: float = NAN) -> Vector2:
	var level: float = elevation_level_at(world_position) if is_nan(level_override) else level_override
	return world_position + Vector2.UP * level * PIXELS_PER_LEVEL


static func project_points(points: PackedVector2Array, level: float) -> PackedVector2Array:
	var projected := PackedVector2Array()
	for point: Vector2 in points:
		projected.append(to_view(point, level))
	return projected

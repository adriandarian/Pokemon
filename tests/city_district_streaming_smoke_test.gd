extends Node

const CITY: CityDefinition = preload(
	"res://features/settlement/content/mossglass_city.tres"
)
const LOAD_FRAME_LIMIT: int = 240

var _failures: Array[String] = []


func _ready() -> void:
	_expect(CITY.districts.size() == 3, "The city definition composes three independently loadable districts.")
	_expect(CITY.has_connected_district_graph(), "Every city district is reachable through the authored connection graph.")

	var district_host := Node2D.new()
	district_host.name = "DistrictHost"
	add_child(district_host)
	var runtime := CityDistrictRuntime.new()
	runtime.name = "CityDistrictRuntime"
	add_child(runtime)
	_expect(runtime.configure(CITY, district_host), "The city runtime accepts the connected district definition.")
	_expect(not runtime.request_district(&"unknown"), "Unknown city districts are rejected without mutating state.")

	_expect(runtime.request_district(&"harbor_ward"), "The harbor district starts a threaded load.")
	_expect(await _wait_for_district(runtime, &"harbor_ward"), "The harbor district finishes loading within the smoke-test frame limit.")
	_expect(runtime.get_active_group_count() == 1, "Exactly one district group is active after the first load.")
	_expect(district_host.get_child_count() == 1, "The district host contains one live group, never the whole city.")
	var harbor_group: CityDistrictGroup = runtime.get_active_group()
	_expect(harbor_group != null and harbor_group.get_terrain_world() != null, "A loaded district owns its cold terrain world.")
	_expect(
		harbor_group != null and harbor_group.get_terrain_world().get_active_chunk_count() == 0,
		"Loading a city district does not eagerly materialize its twelve terrain chunks."
	)

	_expect(runtime.request_district(&"market_crown"), "The connected market district starts loading.")
	_expect(runtime.get_active_group_count() == 1, "The current district remains available while its replacement loads.")
	_expect(await _wait_for_district(runtime, &"market_crown"), "The market district replaces the harbor district.")
	_expect(runtime.get_active_group_count() == 1, "District replacement still leaves exactly one active group.")
	_expect(district_host.get_child_count() == 1, "The retired harbor group is removed before the market group is attached.")
	_expect(
		not is_instance_valid(harbor_group) or harbor_group.get_parent() == null,
		"The previously active district is detached from the live tree."
	)

	_expect(runtime.request_district(&"garden_heights"), "The final connected district starts loading.")
	_expect(await _wait_for_district(runtime, &"garden_heights"), "The garden district activates successfully.")
	_expect(runtime.get_active_group_count() == 1, "Cycling across the city never retains a second district group.")
	_expect(district_host.get_child_count() == 1, "Only the selected city district remains in the scene tree.")

	district_host.queue_free()
	runtime.queue_free()
	if _failures.is_empty():
		print("CITY_DISTRICT_STREAMING_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("CITY_DISTRICT_STREAMING_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _wait_for_district(runtime: CityDistrictRuntime, district_id: StringName) -> bool:
	for _frame: int in range(LOAD_FRAME_LIMIT):
		if runtime.get_active_district_id() == district_id and not runtime.is_loading():
			return true
		await get_tree().process_frame
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

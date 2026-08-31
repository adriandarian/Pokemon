class_name CityDistrictRuntime
extends Node

signal district_load_started(district_id: StringName)
signal district_activated(district_id: StringName, group: CityDistrictGroup)
signal district_deactivated(district_id: StringName)
signal district_load_failed(district_id: StringName, reason: String)

var _definition: CityDefinition
var _district_host: Node
var _active_id: StringName
var _active_group: CityDistrictGroup
var _pending_definition: CityDistrictDefinition


func configure(definition: CityDefinition, district_host: Node) -> bool:
	if _pending_definition != null:
		push_error("CityDistrictRuntime cannot be reconfigured while a district load is pending.")
		return false
	if definition == null or district_host == null or not definition.has_connected_district_graph():
		push_error("CityDistrictRuntime requires a valid connected city definition and host.")
		return false
	_clear_active_group()
	_definition = definition
	_district_host = district_host
	_pending_definition = null
	set_process(false)
	return true


func request_district(district_id: StringName) -> bool:
	if _definition == null or _district_host == null or _pending_definition != null:
		return false
	if district_id == _active_id and is_instance_valid(_active_group):
		return true
	var district: CityDistrictDefinition = _definition.get_district(district_id)
	if district == null or not district.is_valid():
		return false
	var request_error: Error = ResourceLoader.load_threaded_request(
		district.scene_path,
		"PackedScene",
		true,
		ResourceLoader.CACHE_MODE_REUSE
	)
	if request_error != OK:
		district_load_failed.emit(district_id, error_string(request_error))
		return false
	_pending_definition = district
	set_process(true)
	district_load_started.emit(district_id)
	return true


func get_active_district_id() -> StringName:
	return _active_id


func get_active_group_count() -> int:
	return 1 if is_instance_valid(_active_group) and _active_group.get_parent() == _district_host else 0


func get_active_group() -> CityDistrictGroup:
	return _active_group


func is_loading() -> bool:
	return _pending_definition != null


func _exit_tree() -> void:
	_pending_definition = null
	set_process(false)
	_clear_active_group()


func _process(_delta: float) -> void:
	if _pending_definition == null:
		set_process(false)
		return
	var progress: Array = []
	var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(
		_pending_definition.scene_path,
		progress
	)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		ResourceLoader.THREAD_LOAD_LOADED:
			_finish_pending_load()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			var failed_id: StringName = _pending_definition.district_id
			_pending_definition = null
			set_process(false)
			district_load_failed.emit(failed_id, "Threaded district resource load failed.")


func _finish_pending_load() -> void:
	var loaded: Resource = ResourceLoader.load_threaded_get(_pending_definition.scene_path)
	var packed_scene := loaded as PackedScene
	var loaded_definition: CityDistrictDefinition = _pending_definition
	_pending_definition = null
	set_process(false)
	if packed_scene == null:
		district_load_failed.emit(loaded_definition.district_id, "District resource is not a PackedScene.")
		return
	var group := packed_scene.instantiate() as CityDistrictGroup
	if group == null or group.district_id != loaded_definition.district_id:
		if group != null:
			group.queue_free()
		district_load_failed.emit(loaded_definition.district_id, "District scene identity does not match its definition.")
		return
	_clear_active_group()
	_active_group = group
	_active_id = loaded_definition.district_id
	_district_host.add_child(_active_group)
	district_activated.emit(_active_id, _active_group)


func _clear_active_group() -> void:
	if not is_instance_valid(_active_group):
		_active_group = null
		_active_id = &""
		return
	var previous_id: StringName = _active_id
	if _active_group.get_parent() != null:
		_active_group.get_parent().remove_child(_active_group)
	_active_group.queue_free()
	_active_group = null
	_active_id = &""
	district_deactivated.emit(previous_id)

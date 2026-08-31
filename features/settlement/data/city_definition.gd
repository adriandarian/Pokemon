class_name CityDefinition
extends Resource

@export var city_id: StringName
@export var display_name: String = "City"
@export var districts: Array[CityDistrictDefinition] = []


func get_district(district_id: StringName) -> CityDistrictDefinition:
	for district: CityDistrictDefinition in districts:
		if district != null and district.district_id == district_id:
			return district
	return null


func has_connected_district_graph() -> bool:
	if districts.is_empty():
		return false
	var known: Dictionary[StringName, CityDistrictDefinition] = {}
	for district: CityDistrictDefinition in districts:
		if district == null or not district.is_valid() or known.has(district.district_id):
			return false
		known[district.district_id] = district
	for district: CityDistrictDefinition in districts:
		for neighbor_id: StringName in district.neighbor_ids:
			if not known.has(neighbor_id):
				return false
	var visited: Dictionary[StringName, bool] = {}
	var pending: Array[StringName] = [districts.front().district_id]
	while not pending.is_empty():
		var current_id: StringName = pending.pop_front()
		if visited.has(current_id):
			continue
		visited[current_id] = true
		var current: CityDistrictDefinition = known[current_id]
		for neighbor_id: StringName in current.neighbor_ids:
			if not visited.has(neighbor_id):
				pending.append(neighbor_id)
	return visited.size() == districts.size()


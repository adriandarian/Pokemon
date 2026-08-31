class_name SettlementDefinition
extends Resource

enum Tier {
	OUTPOST,
	VILLAGE,
	TOWN,
	CITY,
}

@export var settlement_id: StringName
@export var display_name: String = "Settlement"
@export var tier: Tier = Tier.OUTPOST
@export var world_bounds: Rect2
@export var props: Array[SettlementPropDefinition] = []


func get_prop_count(kind: AdventureProp.Kind) -> int:
	var count: int = 0
	for prop: SettlementPropDefinition in props:
		if prop != null and prop.kind == kind:
			count += 1
	return count


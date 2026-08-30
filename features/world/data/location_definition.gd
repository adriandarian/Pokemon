class_name LocationDefinition
extends Resource

enum Kind {
	TOWN,
	ROUTE,
	CAVE,
	DUNGEON,
	SHRINE,
	ARENA,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: Kind = Kind.ROUTE
@export_range(1, 100, 1) var recommended_level: int = 1
@export var required_badge_ids: Array[StringName] = []
@export_file("*.tscn") var scene_path: String


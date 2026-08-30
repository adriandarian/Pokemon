class_name ItemDefinition
extends Resource

enum Kind {
	CAPTURE_TOOL,
	MEDICINE,
	KEY_ITEM,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var kind: Kind = Kind.MEDICINE
@export_range(1, 999, 1) var max_stack: int = 99
@export var accent_color: Color = Color.WHITE

class_name BadgeDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var element: ElementDefinition
@export_range(0, 100, 1) var obedience_level: int = 10


class_name MoveDefinition
extends Resource

enum Category {
	PHYSICAL,
	ELEMENTAL,
	STATUS,
}

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var element: ElementDefinition
@export var category: Category = Category.PHYSICAL
@export_range(0, 250, 1) var power: int = 10
@export_range(0.0, 1.0, 0.01) var accuracy: float = 1.0
@export_range(1, 40, 1) var max_uses: int = 20


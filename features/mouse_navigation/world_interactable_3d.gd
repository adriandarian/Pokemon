class_name WorldInteractable3D
extends Node3D

@export var interaction_title: String = "Trail Notes"
@export_multiline var interaction_text: String = ""
@export var interaction_position: Vector3 = Vector3.ZERO
@export_range(0.25, 6.0, 0.05) var interaction_distance: float = 1.8


func _ready() -> void:
	add_to_group(&"mouse_interactable")


func configure(
	title: String,
	text: String,
	local_interaction_position: Vector3,
	max_distance: float = 1.8
) -> void:
	interaction_title = title
	interaction_text = text
	interaction_position = local_interaction_position
	interaction_distance = max_distance


func get_interaction() -> Dictionary:
	return {
		"title": interaction_title,
		"text": interaction_text,
	}


func get_interaction_position(_from_position: Vector3) -> Vector3:
	return to_global(interaction_position)


func can_interact_from(from_position: Vector3) -> bool:
	return from_position.distance_to(get_interaction_position(from_position)) <= interaction_distance

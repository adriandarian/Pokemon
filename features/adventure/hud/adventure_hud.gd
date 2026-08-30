class_name AdventureHUD
extends Control

@onready var prompt_panel: PanelContainer = %PromptPanel
@onready var prompt_label: Label = %PromptLabel
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var dialogue_title: Label = %DialogueTitle
@onready var dialogue_text: Label = %DialogueText
@onready var region_label: Label = %Region
@onready var location_label: Label = %Location
@onready var objective_label: Label = %Objective


func _ready() -> void:
	prompt_panel.visible = false
	dialogue_panel.visible = false


func set_context_prompt(action: String) -> void:
	prompt_panel.visible = not action.is_empty()
	if not action.is_empty():
		prompt_label.text = "E   %s" % action


func set_location(region: String, location: String, objective: String) -> void:
	region_label.text = region.to_upper()
	location_label.text = location
	objective_label.text = objective


func show_dialogue(title: String, text: String) -> void:
	dialogue_title.text = title
	dialogue_text.text = text
	dialogue_panel.visible = true
	prompt_panel.visible = false


func hide_dialogue() -> void:
	dialogue_panel.visible = false


func is_dialogue_open() -> bool:
	return dialogue_panel.visible

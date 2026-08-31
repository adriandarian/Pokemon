class_name AdventureHUD
extends Control

const LocationBannerType = preload("res://features/location_banner/location_banner.gd")
const LOCATION_BANNER_WIDTH: float = 365.0
const LOCATION_BANNER_SIDE_MARGIN: float = 48.0

@onready var location_banner: LocationBannerType = %LocationCard
@onready var prompt_panel: PanelContainer = %PromptPanel
@onready var prompt_label: Label = %PromptLabel
@onready var dialogue_panel: PanelContainer = %DialoguePanel
@onready var dialogue_title: Label = %DialogueTitle
@onready var dialogue_text: Label = %DialogueText


func _ready() -> void:
	prompt_panel.visible = false
	dialogue_panel.visible = false
	resized.connect(_fit_location_banner)
	_fit_location_banner()


func set_context_prompt(action: String) -> void:
	prompt_panel.visible = not action.is_empty()
	if not action.is_empty():
		prompt_label.text = "E   %s" % action


func set_location(region: String, location: String, objective: String) -> void:
	location_banner.present(region, location, objective)


func show_dialogue(title: String, text: String) -> void:
	dialogue_title.text = title
	dialogue_text.text = text
	dialogue_panel.visible = true
	prompt_panel.visible = false


func hide_dialogue() -> void:
	dialogue_panel.visible = false


func is_dialogue_open() -> bool:
	return dialogue_panel.visible


func _fit_location_banner() -> void:
	var available_width: float = maxf(0.0, size.x - LOCATION_BANNER_SIDE_MARGIN)
	location_banner.custom_minimum_size.x = minf(LOCATION_BANNER_WIDTH, available_width)

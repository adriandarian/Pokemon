class_name BootstrapView
extends Control

signal sample_creature_requested
signal first_badge_requested
signal reset_requested

const DESIGN_SIZE := Vector2i(1280, 720)
const NARROW_BREAKPOINT: int = 700

@onready var _catalog_summary: Label = %CatalogSummary
@onready var _profile_summary: Label = %ProfileSummary
@onready var _status_label: Label = %StatusLabel
@onready var _creature_button: Button = %CreatureButton
@onready var _badge_button: Button = %BadgeButton
@onready var _reset_button: Button = %ResetButton
@onready var _page_margins: MarginContainer = %PageMargins
@onready var _title: Label = %Title
@onready var _catalog_card: PanelContainer = %CatalogCard
@onready var _profile_card: PanelContainer = %ProfileCard


func _ready() -> void:
	_creature_button.pressed.connect(_on_creature_button_pressed)
	_badge_button.pressed.connect(_on_badge_button_pressed)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	get_window().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_creature_button.grab_focus()
	refresh()


func _exit_tree() -> void:
	if get_window().size_changed.is_connected(_apply_responsive_layout):
		get_window().size_changed.disconnect(_apply_responsive_layout)


func refresh() -> void:
	var content: Dictionary = ContentRegistry.get_summary()
	var session: Dictionary = GameSession.get_summary()

	_catalog_summary.text = (
		"%d elements\n%d moves\n%d creature species\n%d badge definitions\n%d world locations"
		% [
			content.get("elements", 0),
			content.get("moves", 0),
			content.get("species", 0),
			content.get("badges", 0),
			content.get("locations", 0),
		]
	)
	_profile_summary.text = (
		"Trailkeeper: %s\nParty: %d / %d\nReserve: %d\nBadges: %d\nDiscovered: %d"
		% [
			session.get("trainer_name", "Unknown"),
			session.get("party", 0),
			GameSession.PARTY_LIMIT,
			session.get("reserve", 0),
			session.get("badges", 0),
			session.get("discovered", 0),
		]
	)
	_badge_button.disabled = ContentRegistry.get_first_badge() == null


func set_status(message: String, is_success: bool = true) -> void:
	_status_label.text = message
	_status_label.add_theme_color_override(
		"font_color",
		Color("8ee6a9") if is_success else Color("f29b7d")
	)


func _apply_responsive_layout() -> void:
	var window_size: Vector2i = get_window().size
	var is_narrow: bool = window_size.x < NARROW_BREAKPOINT
	get_window().content_scale_size = window_size if is_narrow else DESIGN_SIZE

	var horizontal_margin: int = 24 if is_narrow else 56
	_page_margins.add_theme_constant_override("margin_left", horizontal_margin)
	_page_margins.add_theme_constant_override("margin_right", horizontal_margin)
	_page_margins.add_theme_constant_override("margin_top", 28 if is_narrow else 46)
	_title.add_theme_font_size_override("font_size", 31 if is_narrow else 42)

	var card_width: float = float(window_size.x - horizontal_margin * 2) if is_narrow else 500.0
	_catalog_card.custom_minimum_size = Vector2(card_width, 250.0)
	_profile_card.custom_minimum_size = Vector2(card_width, 250.0)


func _on_creature_button_pressed() -> void:
	sample_creature_requested.emit()


func _on_badge_button_pressed() -> void:
	first_badge_requested.emit()


func _on_reset_button_pressed() -> void:
	reset_requested.emit()

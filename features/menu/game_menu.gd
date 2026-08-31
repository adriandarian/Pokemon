class_name GameMenu
extends Control

const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")

signal closed

const PAGE_BAG := &"bag"
const PAGE_PROFILE := &"profile"
const PAGE_DEX := &"dex"
const PAGE_SETTINGS := &"settings"

@onready var title_label: Label = %TitleLabel
@onready var nav_row: HBoxContainer = %NavRow
@onready var content: VBoxContainer = %Content
@onready var close_button: Button = %CloseButton

var _page: StringName = PAGE_BAG
var _nav_buttons: Dictionary[StringName, Button] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close)
	_create_navigation()
	EventHub.inventory_changed.connect(_on_inventory_changed)
	EventHub.creature_collected.connect(_on_creature_collected)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func open(page: StringName = PAGE_BAG) -> void:
	_page = page
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh()
	var focus_button: Button = _nav_buttons.get(_page)
	if focus_button != null:
		focus_button.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed(&"open_menu") or event.is_action_pressed(&"ui_cancel")):
		close()
		get_viewport().set_input_as_handled()


func _create_navigation() -> void:
	var pages: Array[Dictionary] = [
		{"id": PAGE_BAG, "label": "BAG"},
		{"id": PAGE_PROFILE, "label": "PROFILE"},
		{"id": PAGE_DEX, "label": "CREATURE DEX"},
		{"id": PAGE_SETTINGS, "label": "SETTINGS"},
	]
	for page_data: Dictionary in pages:
		var page_id: StringName = page_data["id"] as StringName
		var button := Button.new()
		button.text = page_data["label"] as String
		button.custom_minimum_size = Vector2(150.0, 48.0)
		button.focus_mode = Control.FOCUS_ALL
		button.pressed.connect(_show_page.bind(page_id))
		nav_row.add_child(button)
		_nav_buttons[page_id] = button


func _show_page(page: StringName) -> void:
	_page = page
	_refresh()


func _refresh() -> void:
	_clear_content()
	for page_id: StringName in _nav_buttons:
		_nav_buttons[page_id].disabled = page_id == _page
	match _page:
		PAGE_PROFILE:
			_build_profile()
		PAGE_DEX:
			_build_dex()
		PAGE_SETTINGS:
			_build_settings()
		_:
			_build_bag()


func _clear_content() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()


func _build_bag() -> void:
	title_label.text = "Field Bag"
	_add_lead("Supplies for the trail. Capture tools are consumed when thrown.")
	for item: ItemDefinition in ContentRegistry.get_all_items():
		var card := _make_card()
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 16)
		card.add_child(row)
		row.add_child(_make_voxel_icon(VoxelAssets.get_item_texture(item.id), Vector2(70.0, 70.0)))
		var text_box := VBoxContainer.new()
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.add_theme_constant_override(&"separation", 3)
		row.add_child(text_box)
		text_box.add_child(_make_label(item.display_name, 21, Color("fff0b1")))
		var description := _make_label(item.description, 16, Color("c7d2c3"))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_box.add_child(description)
		var count := _make_label("× %d" % GameSession.get_item_count(item.id), 24, item.accent_color)
		count.custom_minimum_size = Vector2(80.0, 0.0)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(count)
		content.add_child(card)


func _build_profile() -> void:
	title_label.text = "Trailkeeper Profile"
	_add_lead("%s  •  %d badge%s  •  %d companion%s" % [
		GameSession.profile.trainer_name,
		GameSession.profile.badge_ids.size(),
		"" if GameSession.profile.badge_ids.size() == 1 else "s",
		GameSession.profile.party.size(),
		"" if GameSession.profile.party.size() == 1 else "s",
	])
	content.add_child(_section_heading("ACTIVE PARTY"))
	for creature: CreatureInstance in GameSession.profile.party:
		var species: CreatureSpecies = ContentRegistry.get_species(creature.species_id)
		if species == null:
			continue
		var card := _make_card()
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 18)
		card.add_child(row)
		row.add_child(_make_voxel_icon(VoxelAssets.get_species_texture(species.id), Vector2(64.0, 64.0)))
		var name_label := _make_label("%s  Lv.%d" % [creature.nickname, creature.level], 21, Color("fff0b1"))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(_make_label("HP %d / %d" % [creature.current_hp, species.base_stats.max_hp], 18, Color("9bd27c")))
		content.add_child(card)
	content.add_child(_section_heading("BADGES"))
	if GameSession.profile.badge_ids.is_empty():
		content.add_child(_make_label("No badges yet. The first gym lies beyond Mossglass Cave.", 17, Color("b7c4b5")))
	else:
		for badge_id: StringName in GameSession.profile.badge_ids:
			var badge: BadgeDefinition = ContentRegistry.get_badge(badge_id)
			if badge != null:
				var badge_row := HBoxContainer.new()
				badge_row.add_theme_constant_override(&"separation", 12)
				badge_row.add_child(_make_voxel_icon(VoxelAssets.get_badge_texture(badge.id), Vector2(56.0, 56.0)))
				badge_row.add_child(_make_label(badge.display_name, 19, Color("e9bd55")))
				content.add_child(badge_row)


func _build_dex() -> void:
	title_label.text = "Creature Dex"
	_add_lead("Observed %d of %d local species." % [GameSession.profile.discovered_species_ids.size(), ContentRegistry.get_all_species().size()])
	for species: CreatureSpecies in ContentRegistry.get_all_species():
		var discovered: bool = GameSession.profile.discovered_species_ids.has(species.id)
		var card := _make_card()
		var row := HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 15)
		card.add_child(row)
		var species_icon := _make_voxel_icon(VoxelAssets.get_species_texture(species.id), Vector2(78.0, 78.0))
		if not discovered:
			species_icon.modulate = Color(0.11, 0.16, 0.13, 0.58)
		row.add_child(species_icon)
		var box := VBoxContainer.new()
		box.add_theme_constant_override(&"separation", 5)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(box)
		box.add_child(_make_label(species.display_name if discovered else "Unrecorded Species", 21, Color("fff0b1") if discovered else Color("7c8a7d")))
		var lore := _make_label(species.lore if discovered else "Find this creature in the wild to add its field notes.", 16, Color("c7d2c3"))
		lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(lore)
		if discovered:
			var element_row := HBoxContainer.new()
			element_row.add_theme_constant_override(&"separation", 8)
			for element: ElementDefinition in species.elements:
				element_row.add_child(_make_voxel_icon(VoxelAssets.get_element_texture(element.id), Vector2(28.0, 28.0)))
				element_row.add_child(_make_label(element.display_name.to_upper(), 13, element.color))
			box.add_child(element_row)
		content.add_child(card)


func _build_settings() -> void:
	title_label.text = "Settings"
	_add_lead("Comfort and presentation options apply immediately.")
	var volume_card := _make_card()
	var volume_box := VBoxContainer.new()
	volume_box.add_theme_constant_override(&"separation", 9)
	volume_card.add_child(volume_box)
	var volume_value := _make_label("MASTER VOLUME   %d%%" % roundi(SettingsService.master_volume * 100.0), 18, Color("fff0b1"))
	volume_box.add_child(volume_value)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = SettingsService.master_volume
	slider.custom_minimum_size = Vector2(0.0, 44.0)
	slider.value_changed.connect(func(value: float) -> void:
		SettingsService.apply_master_volume(value)
		volume_value.text = "MASTER VOLUME   %d%%" % roundi(value * 100.0)
	)
	volume_box.add_child(slider)
	content.add_child(volume_card)
	var motion_card := _make_card()
	var motion_toggle := CheckBox.new()
	motion_toggle.text = "Reduced motion (disables idle bob and roaming drift)"
	motion_toggle.button_pressed = SettingsService.reduced_motion
	motion_toggle.custom_minimum_size = Vector2(0.0, 48.0)
	motion_toggle.toggled.connect(SettingsService.set_reduced_motion)
	motion_card.add_child(motion_toggle)
	content.add_child(motion_card)


func _add_lead(text: String) -> void:
	var label := _make_label(text, 18, Color("c6d2c3"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(label)


func _make_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card


func _section_heading(text: String) -> Label:
	var label := _make_label(text, 15, Color("e9bd55"))
	label.custom_minimum_size = Vector2(0.0, 38.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	return label


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_voxel_icon(texture: Texture2D, display_size: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = display_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.material = VoxelAssets.create_chroma_material()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _on_inventory_changed(_item_id: StringName, _quantity: int) -> void:
	if visible and _page == PAGE_BAG:
		_refresh()


func _on_creature_collected(_creature: CreatureInstance) -> void:
	if visible and (_page == PAGE_PROFILE or _page == PAGE_DEX):
		_refresh()

class_name BattleOverlay
extends Control

signal battle_finished(outcome: int)

enum State {
	PLAYER_CHOICE,
	RESOLVING,
	ENDED,
}

enum Result {
	CAPTURED,
	RAN,
	WILD_DEFEATED,
	PLAYER_DEFEATED,
}

@onready var backdrop: BattleBackdrop = %Backdrop
@onready var wild_visual: CreatureVisual = %WildVisual
@onready var player_visual: CreatureVisual = %PlayerVisual
@onready var wild_name: Label = %WildName
@onready var wild_hp: ProgressBar = %WildHP
@onready var wild_hp_text: Label = %WildHPText
@onready var player_name: Label = %PlayerName
@onready var player_hp: ProgressBar = %PlayerHP
@onready var player_hp_text: Label = %PlayerHPText
@onready var battle_log: Label = %BattleLog
@onready var fight_button: Button = %FightButton
@onready var capture_button: Button = %CaptureButton
@onready var run_button: Button = %RunButton

var _state: State = State.ENDED
var _encounter: BattleEncounter
var _rng := RandomNumberGenerator.new()
var _active_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fight_button.pressed.connect(_on_fight_pressed)
	capture_button.pressed.connect(_on_capture_pressed)
	run_button.pressed.connect(_on_run_pressed)
	resized.connect(_position_creatures)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func start_battle(species_id: StringName, level: int) -> bool:
	var species: CreatureSpecies = ContentRegistry.get_species(species_id)
	if species == null or GameSession.profile.party.is_empty():
		return false
	var player_creature: CreatureInstance = GameSession.profile.party[0]
	if ContentRegistry.get_species(player_creature.species_id) == null:
		push_error("Cannot start battle with unknown party species: %s" % player_creature.species_id)
		return false
	_encounter = BattleEncounter.new(player_creature, species, level)
	_encounter.health_changed.connect(_refresh_health)
	_state = State.PLAYER_CHOICE
	wild_visual.set_species(species.id)
	player_visual.set_species(_encounter.player_species.id)
	wild_visual.facing_left = true
	player_visual.facing_left = false
	wild_name.text = "WILD %s   Lv.%d" % [species.display_name.to_upper(), level]
	player_name.text = "%s   Lv.%d" % [_encounter.player_creature.nickname.to_upper(), _encounter.player_creature.level]
	battle_log.text = "A wild %s steps from the grass!" % species.display_name
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_health()
	_refresh_capture_label()
	_set_actions_enabled(true)
	_position_creatures()
	_play_entrance()
	fight_button.grab_focus()
	return true


func _position_creatures() -> void:
	if not is_node_ready():
		return
	wild_visual.position = Vector2(size.x * 0.73, size.y * 0.49)
	player_visual.position = Vector2(size.x * 0.46, size.y * 0.55)


func _play_entrance() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	wild_visual.modulate.a = 0.0
	wild_visual.scale = Vector2(0.75, 0.75)
	_active_tween = create_tween().bind_node(self)
	_active_tween.set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_active_tween.tween_property(wild_visual, "modulate:a", 1.0, 0.32)
	_active_tween.tween_property(wild_visual, "scale", Vector2.ONE, 0.42)


func _on_fight_pressed() -> void:
	if _state != State.PLAYER_CHOICE:
		return
	_resolve_fight()


func _resolve_fight() -> void:
	_state = State.RESOLVING
	_set_actions_enabled(false)
	var player_move: MoveDefinition = _first_move(_encounter.player_species)
	if player_move == null:
		battle_log.text = "%s has no usable move." % _encounter.player_creature.nickname
		_state = State.PLAYER_CHOICE
		_set_actions_enabled(true)
		return
	var damage: int = BattleRules.calculate_damage(_encounter.player_species, _encounter.player_creature.level, player_move, _encounter.wild_species)
	_encounter.damage_wild(damage)
	battle_log.text = "%s used %s — %d damage!" % [_encounter.player_creature.nickname, player_move.display_name, damage]
	_punch_visual(wild_visual, Vector2(12.0, 0.0))
	await get_tree().create_timer(0.62).timeout
	if _encounter.wild_hp <= 0:
		battle_log.text = "The wild %s yields and retreats into the preserve." % _encounter.wild_species.display_name
		await _finish(Result.WILD_DEFEATED)
		return
	await _wild_turn()


func _on_capture_pressed() -> void:
	if _state != State.PLAYER_CHOICE:
		return
	if not GameSession.consume_item(&"trail_prism"):
		battle_log.text = "No Trail Prisms remain. Weaken it or run."
		return
	_state = State.RESOLVING
	_set_actions_enabled(false)
	_refresh_capture_label()
	var chance: float = _encounter.get_capture_chance()
	battle_log.text = "You cast a Trail Prism…"
	_punch_visual(wild_visual, Vector2(0.0, -18.0))
	await get_tree().create_timer(0.75).timeout
	if _rng.randf() <= chance:
		var creature: CreatureInstance = GameSession.collect_creature(_encounter.wild_species.id, _encounter.wild_level)
		battle_log.text = "%s joined your trail team!" % creature.nickname
		await _finish(Result.CAPTURED)
		return
	battle_log.text = "The prism fractures — %s breaks free!" % _encounter.wild_species.display_name
	await get_tree().create_timer(0.55).timeout
	await _wild_turn()


func _on_run_pressed() -> void:
	if _state != State.PLAYER_CHOICE:
		return
	_state = State.RESOLVING
	_set_actions_enabled(false)
	battle_log.text = "You retreat to the village path."
	await _finish(Result.RAN)


func _wild_turn() -> void:
	var wild_move: MoveDefinition = _first_move(_encounter.wild_species)
	if wild_move == null:
		battle_log.text = "%s hesitates. Choose your next action." % _encounter.wild_species.display_name
		_state = State.PLAYER_CHOICE
		_set_actions_enabled(true)
		fight_button.grab_focus()
		return
	var damage: int = BattleRules.calculate_damage(_encounter.wild_species, _encounter.wild_level, wild_move, _encounter.player_species)
	_encounter.damage_player(damage)
	battle_log.text = "%s answers with %s — %d damage!" % [_encounter.wild_species.display_name, wild_move.display_name, damage]
	_punch_visual(player_visual, Vector2(-12.0, 0.0))
	await get_tree().create_timer(0.68).timeout
	if _encounter.player_hp <= 0:
		battle_log.text = "%s is exhausted. A ranger guides you back to safety." % _encounter.player_creature.nickname
		await _finish(Result.PLAYER_DEFEATED)
		return
	_state = State.PLAYER_CHOICE
	_set_actions_enabled(true)
	fight_button.grab_focus()


func _first_move(species: CreatureSpecies) -> MoveDefinition:
	if not species.learnset.is_empty():
		return species.learnset[0]
	return ContentRegistry.get_move(&"kindle_dash")


func _refresh_health() -> void:
	if _encounter == null:
		return
	wild_hp.max_value = _encounter.wild_max_hp
	wild_hp.value = _encounter.wild_hp
	wild_hp_text.text = "%d / %d" % [_encounter.wild_hp, _encounter.wild_max_hp]
	player_hp.max_value = _encounter.player_max_hp
	player_hp.value = _encounter.player_hp
	player_hp_text.text = "%d / %d" % [_encounter.player_hp, _encounter.player_max_hp]


func _refresh_capture_label() -> void:
	capture_button.text = "THROW PRISM  ×%d" % GameSession.get_item_count(&"trail_prism")


func _set_actions_enabled(enabled: bool) -> void:
	fight_button.disabled = not enabled
	capture_button.disabled = not enabled or GameSession.get_item_count(&"trail_prism") <= 0
	run_button.disabled = not enabled


func _punch_visual(target: Node2D, delta: Vector2) -> void:
	var tween := create_tween().bind_node(target)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", target.position + delta, 0.09)
	tween.tween_property(target, "position", target.position, 0.16)


func _finish(result: Result) -> void:
	_state = State.ENDED
	_set_actions_enabled(false)
	_encounter.commit_player_health()
	await get_tree().create_timer(0.9).timeout
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_finished.emit(result)

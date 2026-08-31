class_name LocationBanner
extends PanelContainer

signal dismissed

@export_range(0.0, 10.0, 0.1, "or_greater") var fade_duration: float = 0.3
@export_range(0.0, 10.0, 0.1, "or_greater") var hold_duration: float = 3.0

@onready var region_label: Label = %Region
@onready var location_label: Label = %Location
@onready var objective_label: Label = %Objective

var _presentation_tween: Tween


func _ready() -> void:
	visible = false
	modulate.a = 0.0


func present(region: String, location: String, objective: String) -> void:
	region_label.text = region.to_upper()
	location_label.text = location
	objective_label.text = objective
	_stop_presentation()
	visible = true

	_presentation_tween = create_tween().bind_node(self)
	_presentation_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_presentation_tween.set_ignore_time_scale()
	if SettingsService.reduced_motion or is_zero_approx(fade_duration):
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		_presentation_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_presentation_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	_presentation_tween.tween_interval(hold_duration)
	if not SettingsService.reduced_motion and not is_zero_approx(fade_duration):
		_presentation_tween.set_ease(Tween.EASE_IN)
		_presentation_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	_presentation_tween.tween_callback(_finish_presentation)


func is_presenting() -> bool:
	return visible


func _stop_presentation() -> void:
	if _presentation_tween != null and _presentation_tween.is_valid():
		_presentation_tween.kill()
	_presentation_tween = null


func _finish_presentation() -> void:
	visible = false
	modulate.a = 0.0
	_presentation_tween = null
	dismissed.emit()

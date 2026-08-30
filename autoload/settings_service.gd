extends Node

signal settings_changed

var master_volume: float = 0.8
var reduced_motion: bool = false


func _ready() -> void:
	apply_master_volume(master_volume)


func apply_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var bus_index: int = AudioServer.get_bus_index(&"Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(master_volume, 0.0001)))
	settings_changed.emit()


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	settings_changed.emit()

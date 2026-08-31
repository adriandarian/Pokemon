class_name WildCreatureActor
extends Node2D

@export var species_id: StringName = &"rillip"
@export_range(1, 100, 1) var level: int = 5
@export var roam_radius: float = 55.0

var _home: Vector2
var _time: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	_home = position
	_phase = randf_range(0.0, TAU)
	add_to_group(&"wild_creature")
	var visual := CreatureVisual.new()
	visual.species_id = species_id
	visual.visual_scale = 0.72
	visual.position = Vector2.ZERO
	add_child(visual)
	queue_redraw()


func _process(delta: float) -> void:
	if SettingsService.reduced_motion:
		position = _home
		return
	_time += delta
	position = _home + Vector2(cos(_time * 0.42 + _phase), sin(_time * 0.58 + _phase) * 0.55) * roam_radius


func get_prompt() -> String:
	var species: CreatureSpecies = ContentRegistry.get_species(species_id)
	return "Challenge %s" % (species.display_name if species != null else "wild creature")


func _draw() -> void:
	var center := Vector2(0.0, -101.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -17.0), center + Vector2(14.0, 0.0),
		center + Vector2(0.0, 17.0), center + Vector2(-14.0, 0.0),
	]), Color(1.0, 0.71, 0.19, 0.9))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -8.0), center + Vector2(7.0, 0.0),
		center + Vector2(0.0, 8.0), center + Vector2(-7.0, 0.0),
	]), Color("fff1aa"))

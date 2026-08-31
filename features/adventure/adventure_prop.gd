class_name AdventureProp
extends StaticBody2D

const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")
const GroundShadow = preload("res://features/voxel_art/grounding_shadow.gd")
const LanternFlameScene = preload("res://features/world_animation/lantern_flame.gd")

enum Kind {
	TREE,
	HOUSE,
	SIGN,
	NPC,
	ROCK,
	LANTERN,
}

@export var kind: Kind = Kind.TREE
@export var interaction_title: String = ""
@export_multiline var interaction_text: String = ""

var _lantern_flame: LanternFlame
var _wind_source: AmbientWind


func configure(prop_kind: Kind, title: String = "", text: String = "") -> void:
	kind = prop_kind
	interaction_title = title
	interaction_text = text


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	material = VoxelAssets.create_chroma_material()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if not interaction_text.is_empty():
		add_to_group(&"interactable")
	_add_collision()
	if kind == Kind.LANTERN:
		_lantern_flame = LanternFlameScene.new()
		_lantern_flame.name = "LanternFlame"
		_lantern_flame.position = Vector2(-19.0, -111.0)
		add_child(_lantern_flame)
		if _wind_source != null:
			_lantern_flame.set_wind_source(_wind_source)
	queue_redraw()


func set_wind_source(source: AmbientWind) -> void:
	_wind_source = source
	if _lantern_flame != null:
		_lantern_flame.set_wind_source(source)


func get_interaction() -> Dictionary:
	return {"title": interaction_title, "text": interaction_text}


func get_prompt() -> String:
	if kind == Kind.NPC:
		return "Talk"
	if kind == Kind.SIGN:
		return "Read"
	return "Inspect"


func _add_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape: Shape2D
	match kind:
		Kind.HOUSE:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Vector2(330.0, 105.0)
			shape = rectangle
			collision.position = Vector2(0.0, -38.0)
		Kind.TREE:
			var circle := CircleShape2D.new()
			circle.radius = 25.0
			shape = circle
			collision.position = Vector2(0.0, -8.0)
		Kind.ROCK:
			var circle := CircleShape2D.new()
			circle.radius = 24.0
			shape = circle
			collision.position = Vector2(0.0, -5.0)
		_:
			var circle := CircleShape2D.new()
			circle.radius = 14.0
			shape = circle
			collision.position = Vector2(0.0, -5.0)
	collision.shape = shape
	add_child(collision)


func _draw() -> void:
	_draw_contact_shadow()
	var texture: Texture2D = VoxelAssets.get_prop_texture(kind)
	var display_size: Vector2 = _get_display_size()
	var source_rect: Rect2 = VoxelAssets.get_prop_source_rect(texture, kind)
	var destination_rect: Rect2 = VoxelAssets.fit_bottom_centered(source_rect, display_size, 1.0)
	draw_texture_rect_region(texture, destination_rect, source_rect)


func _get_display_size() -> Vector2:
	match kind:
		Kind.HOUSE:
			return Vector2(440.0, 372.0)
		Kind.SIGN:
			return Vector2(132.0, 144.0)
		Kind.NPC:
			return Vector2(104.0, 136.0)
		Kind.ROCK:
			return Vector2(144.0, 106.0)
		Kind.LANTERN:
			return Vector2(104.0, 178.0)
		_:
			return Vector2(216.0, 246.0)


func _draw_contact_shadow() -> void:
	var contact_radii: Vector2
	var strength: float = 1.0
	match kind:
		Kind.HOUSE:
			contact_radii = Vector2(158.0, 9.0)
			strength = 0.92
		Kind.TREE:
			contact_radii = Vector2(34.0, 6.5)
		Kind.ROCK:
			contact_radii = Vector2(39.0, 6.0)
			strength = 0.9
		Kind.NPC:
			contact_radii = Vector2(19.0, 4.5)
		Kind.SIGN:
			contact_radii = Vector2(15.0, 3.5)
			strength = 0.95
		Kind.LANTERN:
			contact_radii = Vector2(16.0, 3.5)
			strength = 0.95
		_:
			contact_radii = Vector2(17.0, 4.5)
	GroundShadow.draw(self, contact_radii, Vector2(0.0, -1.0), strength)

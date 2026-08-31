class_name AdventureProp
extends StaticBody2D

const VoxelAssets = preload("res://features/voxel_art/voxel_asset_library.gd")
const GroundShadow = preload("res://features/voxel_art/grounding_shadow.gd")
const LanternFlameScene = preload("res://features/world_animation/lantern_flame.gd")
const Scale = preload("res://features/adventure/adventure_scale.gd")
const LODGE_CONTACT_SHADOW: Texture2D = preload("res://assets/voxel/lodge_contact_shadow_v3.png")
const LODGE_CONTACT_SHADOW_SHADER: Shader = preload("res://features/adventure/lodge_contact_shadow.gdshader")

const LODGE_SHADOW_SOURCE := Rect2(160.0, 570.0, 930.0, 260.0)
const LODGE_SHADOW_DISPLAY_SIZE := Vector2(490.0, 40.0)
const LODGE_SHADOW_GROUND_POSITION := Vector2(0.0, 4.0)

enum Kind {
	TREE,
	HOUSE,
	SIGN,
	NPC,
	ROCK,
	LANTERN,
	COTTAGE,
	MARKET_STALL,
	CIVIC_HALL,
	HOMESTEAD_COMPOUND,
	WHEAT_FIELD,
	MEADOW_SHRUB,
	RIVER_CROSSING,
	RIVER_STAIR,
}

@export var kind: Kind = Kind.TREE
@export var interaction_title: String = ""
@export_multiline var interaction_text: String = ""

var _lantern_flame: LanternFlame
var _lodge_contact_shadow: Sprite2D
var _wind_source: AmbientWind
var _ground_elevation_pixels: float = 0.0


func configure(prop_kind: Kind, title: String = "", text: String = "") -> void:
	kind = prop_kind
	interaction_title = title
	interaction_text = text


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	material = (
		VoxelAssets.create_strict_chroma_material()
		if kind in [Kind.RIVER_CROSSING, Kind.RIVER_STAIR]
		else VoxelAssets.create_chroma_material()
	)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if kind == Kind.HOUSE:
		_add_lodge_contact_shadow()
	if not interaction_text.is_empty():
		add_to_group(&"interactable")
	_add_collision()
	if kind == Kind.LANTERN:
		_lantern_flame = LanternFlameScene.new()
		_lantern_flame.name = "LanternFlame"
		_lantern_flame.position = Scale.LANTERN_FLAME_POSITION
		_lantern_flame.scale = Scale.LANTERN_FLAME_SCALE
		add_child(_lantern_flame)
		if _wind_source != null:
			_lantern_flame.set_wind_source(_wind_source)
	queue_redraw()


func set_wind_source(source: AmbientWind) -> void:
	_wind_source = source
	if _lantern_flame != null:
		_lantern_flame.set_wind_source(source)


func set_ground_elevation_pixels(value: float) -> void:
	if is_equal_approx(_ground_elevation_pixels, value):
		return
	_ground_elevation_pixels = value
	_sync_lodge_contact_shadow()
	queue_redraw()


func get_ground_elevation_pixels() -> float:
	return _ground_elevation_pixels


func get_interaction() -> Dictionary:
	return {"title": interaction_title, "text": interaction_text}


func get_prompt() -> String:
	if kind == Kind.NPC:
		return "Talk"
	if kind == Kind.SIGN:
		return "Read"
	return "Inspect"


func _add_collision() -> void:
	if kind in [Kind.RIVER_CROSSING, Kind.RIVER_STAIR]:
		return
	var collision := CollisionShape2D.new()
	var shape: Shape2D
	match kind:
		Kind.HOUSE:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Scale.HOUSE_FOOTPRINT
			shape = rectangle
			collision.position = Scale.HOUSE_COLLISION_OFFSET
		Kind.COTTAGE:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Scale.COTTAGE_FOOTPRINT
			shape = rectangle
			collision.position = Scale.COTTAGE_COLLISION_OFFSET
		Kind.MARKET_STALL:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Scale.MARKET_FOOTPRINT
			shape = rectangle
			collision.position = Scale.MARKET_COLLISION_OFFSET
		Kind.CIVIC_HALL:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Scale.CIVIC_HALL_FOOTPRINT
			shape = rectangle
			collision.position = Scale.CIVIC_HALL_COLLISION_OFFSET
		Kind.HOMESTEAD_COMPOUND:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Scale.HOMESTEAD_FOOTPRINT
			shape = rectangle
			collision.position = Scale.HOMESTEAD_COLLISION_OFFSET
		Kind.WHEAT_FIELD:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Scale.WHEAT_FOOTPRINT
			shape = rectangle
			collision.position = Scale.WHEAT_COLLISION_OFFSET
		Kind.MEADOW_SHRUB:
			var circle := CircleShape2D.new()
			circle.radius = Scale.SHRUB_COLLISION_RADIUS
			shape = circle
			collision.position = Vector2(0.0, -4.0)
		Kind.TREE:
			var circle := CircleShape2D.new()
			circle.radius = Scale.TREE_COLLISION_RADIUS
			shape = circle
			collision.position = Vector2(0.0, -8.0)
		Kind.ROCK:
			var circle := CircleShape2D.new()
			circle.radius = Scale.ROCK_COLLISION_RADIUS
			shape = circle
			collision.position = Vector2(0.0, -5.0)
		Kind.SIGN:
			var circle := CircleShape2D.new()
			circle.radius = Scale.SIGN_COLLISION_RADIUS
			shape = circle
			collision.position = Vector2(0.0, -5.0)
		Kind.LANTERN:
			var circle := CircleShape2D.new()
			circle.radius = Scale.LANTERN_COLLISION_RADIUS
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
	var bottom_offset: float = 7.0 if kind in [Kind.HOUSE, Kind.COTTAGE, Kind.MARKET_STALL, Kind.CIVIC_HALL, Kind.HOMESTEAD_COMPOUND, Kind.WHEAT_FIELD] else 1.0
	var destination_rect: Rect2 = VoxelAssets.fit_bottom_centered(source_rect, display_size, bottom_offset)
	destination_rect.position.y -= _ground_elevation_pixels
	draw_texture_rect_region(texture, destination_rect, source_rect)


func _get_display_size() -> Vector2:
	match kind:
		Kind.HOUSE:
			return Scale.HOUSE_DISPLAY_BOX
		Kind.COTTAGE:
			return Scale.COTTAGE_DISPLAY_BOX
		Kind.MARKET_STALL:
			return Scale.MARKET_DISPLAY_BOX
		Kind.CIVIC_HALL:
			return Scale.CIVIC_HALL_DISPLAY_BOX
		Kind.HOMESTEAD_COMPOUND:
			return Scale.HOMESTEAD_DISPLAY_BOX
		Kind.WHEAT_FIELD:
			return Scale.WHEAT_DISPLAY_BOX
		Kind.MEADOW_SHRUB:
			return Scale.SHRUB_DISPLAY_BOX
		Kind.RIVER_CROSSING:
			return Scale.RIVER_CROSSING_DISPLAY_BOX
		Kind.RIVER_STAIR:
			return Scale.RIVER_STAIR_DISPLAY_BOX
		Kind.SIGN:
			return Scale.SIGN_DISPLAY_BOX
		Kind.NPC:
			return Scale.NPC_DISPLAY_BOX
		Kind.ROCK:
			return Scale.ROCK_DISPLAY_BOX
		Kind.LANTERN:
			return Scale.LANTERN_DISPLAY_BOX
		_:
			return Scale.TREE_DISPLAY_BOX


func _draw_contact_shadow() -> void:
	if kind in [Kind.HOUSE, Kind.RIVER_CROSSING, Kind.RIVER_STAIR]:
		return
	var contact_radii: Vector2
	var strength: float = 1.0
	match kind:
		Kind.TREE:
			contact_radii = Vector2(41.0, 7.5)
		Kind.ROCK:
			contact_radii = Vector2(39.0, 6.0)
			strength = 0.9
		Kind.NPC:
			contact_radii = Vector2(19.0, 4.5)
		Kind.SIGN:
			contact_radii = Vector2(12.0, 3.0)
			strength = 0.95
		Kind.LANTERN:
			contact_radii = Vector2(22.0, 4.5)
			strength = 0.95
		Kind.COTTAGE:
			contact_radii = Vector2(145.0, 14.0)
			strength = 1.15
		Kind.MARKET_STALL:
			contact_radii = Vector2(132.0, 12.0)
			strength = 1.08
		Kind.CIVIC_HALL:
			contact_radii = Vector2(274.0, 19.0)
			strength = 1.18
		Kind.HOMESTEAD_COMPOUND:
			contact_radii = Vector2(380.0, 23.0)
			strength = 1.18
		Kind.WHEAT_FIELD:
			contact_radii = Vector2(390.0, 15.0)
			strength = 0.84
		Kind.MEADOW_SHRUB:
			contact_radii = Vector2(55.0, 6.0)
			strength = 0.82
		_:
			contact_radii = Vector2(17.0, 4.5)
	GroundShadow.draw(
		self,
		contact_radii,
		Vector2(0.0, -1.0 - _ground_elevation_pixels),
		strength
	)


func _add_lodge_contact_shadow() -> void:
	_lodge_contact_shadow = Sprite2D.new()
	_lodge_contact_shadow.name = "LodgeContactShadow"
	_lodge_contact_shadow.texture = LODGE_CONTACT_SHADOW
	_lodge_contact_shadow.region_enabled = true
	_lodge_contact_shadow.region_rect = LODGE_SHADOW_SOURCE
	_lodge_contact_shadow.scale = Vector2(
		LODGE_SHADOW_DISPLAY_SIZE.x / LODGE_SHADOW_SOURCE.size.x,
		LODGE_SHADOW_DISPLAY_SIZE.y / LODGE_SHADOW_SOURCE.size.y
	)
	_lodge_contact_shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shadow_material := ShaderMaterial.new()
	shadow_material.shader = LODGE_CONTACT_SHADOW_SHADER
	_lodge_contact_shadow.material = shadow_material
	_lodge_contact_shadow.show_behind_parent = true
	add_child(_lodge_contact_shadow)
	_sync_lodge_contact_shadow()


func _sync_lodge_contact_shadow() -> void:
	if _lodge_contact_shadow == null:
		return
	_lodge_contact_shadow.position = LODGE_SHADOW_GROUND_POSITION + Vector2.UP * _ground_elevation_pixels

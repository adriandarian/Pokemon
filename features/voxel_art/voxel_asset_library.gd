class_name VoxelAssetLibrary
extends RefCounted

const CHROMA_KEY_SHADER: Shader = preload("res://features/voxel_art/voxel_chroma_key.gdshader")

const PLAYER_FRONT: Texture2D = preload("res://assets/voxel/player_front.png")
const PLAYER_BACK: Texture2D = preload("res://assets/voxel/player_back.png")

const KINDLEHORN: Texture2D = preload("res://assets/voxel/kindlehorn.png")
const RILLIP: Texture2D = preload("res://assets/voxel/rillip.png")
const BRAMBIT: Texture2D = preload("res://assets/voxel/brambit.png")

const TREE: Texture2D = preload("res://assets/voxel/tree.png")
const LODGE: Texture2D = preload("res://assets/voxel/lodge.png")
const SIGN: Texture2D = preload("res://assets/voxel/sign.png")
const RANGER_SELA: Texture2D = preload("res://assets/voxel/ranger_sela.png")
const ROCK: Texture2D = preload("res://assets/voxel/rock.png")
const LANTERN: Texture2D = preload("res://assets/voxel/lantern.png")

const TRAIL_PRISM: Texture2D = preload("res://assets/voxel/trail_prism.png")
const MOSS_TONIC: Texture2D = preload("res://assets/voxel/moss_tonic.png")
const EMBER_CREST: Texture2D = preload("res://assets/voxel/ember_crest.png")
const DEEP_DELVER_MARK: Texture2D = preload("res://assets/voxel/deep_delver_mark.png")
const EMBER: Texture2D = preload("res://assets/voxel/ember.png")
const TIDE: Texture2D = preload("res://assets/voxel/tide.png")
const GROVE: Texture2D = preload("res://assets/voxel/grove.png")
const STORM: Texture2D = preload("res://assets/voxel/storm.png")

const PLAYER_FRONT_REGION := Rect2(0.2233, 0.0191, 0.6220, 0.9569)
const PLAYER_BACK_REGION := Rect2(0.2791, 0.0319, 0.4386, 0.9187)

const KINDLEHORN_REGION := Rect2(0.2153, 0.0383, 0.6778, 0.9123)
const RILLIP_REGION := Rect2(0.0957, 0.1396, 0.8214, 0.7153)
const BRAMBIT_REGION := Rect2(0.1834, 0.0439, 0.6380, 0.8812)

const TREE_REGION := Rect2(0.0558, 0.0239, 0.8692, 0.9075)
const LODGE_REGION := Rect2(0.0877, 0.0877, 0.8214, 0.7927)
const SIGN_REGION := Rect2(0.2472, 0.0478, 0.5981, 0.8836)
const RANGER_SELA_REGION := Rect2(0.2621, 0.0320, 0.4240, 0.9307)
const ROCK_REGION := Rect2(0.0745, 0.1153, 0.8487, 0.7268)
const LANTERN_REGION := Rect2(0.2065, 0.0360, 0.5684, 0.9150)


static func create_chroma_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = CHROMA_KEY_SHADER
	return material


static func get_player_texture(facing_away: bool) -> Texture2D:
	return PLAYER_BACK if facing_away else PLAYER_FRONT


static func get_player_source_rect(texture: Texture2D, facing_away: bool) -> Rect2:
	return _source_rect(texture, PLAYER_BACK_REGION if facing_away else PLAYER_FRONT_REGION)


static func get_species_texture(species_id: StringName) -> Texture2D:
	match species_id:
		&"rillip":
			return RILLIP
		&"brambit":
			return BRAMBIT
		&"kindlehorn":
			return KINDLEHORN
		_:
			push_error("Missing voxel creature texture for species: %s" % species_id)
			return KINDLEHORN


static func get_species_source_rect(texture: Texture2D, species_id: StringName) -> Rect2:
	var normalized_region: Rect2
	match species_id:
		&"rillip":
			normalized_region = RILLIP_REGION
		&"brambit":
			normalized_region = BRAMBIT_REGION
		_:
			normalized_region = KINDLEHORN_REGION
	return _source_rect(texture, normalized_region)


static func get_prop_texture(kind: int) -> Texture2D:
	match kind:
		0:
			return TREE
		1:
			return LODGE
		2:
			return SIGN
		3:
			return RANGER_SELA
		4:
			return ROCK
		5:
			return LANTERN
		_:
			push_error("Missing voxel prop texture for kind: %d" % kind)
			return ROCK


static func get_prop_source_rect(texture: Texture2D, kind: int) -> Rect2:
	var normalized_region: Rect2
	match kind:
		0:
			normalized_region = TREE_REGION
		1:
			normalized_region = LODGE_REGION
		2:
			normalized_region = SIGN_REGION
		3:
			normalized_region = RANGER_SELA_REGION
		4:
			normalized_region = ROCK_REGION
		5:
			normalized_region = LANTERN_REGION
		_:
			normalized_region = ROCK_REGION
	return _source_rect(texture, normalized_region)


static func fit_bottom_centered(source_rect: Rect2, maximum_size: Vector2, bottom_offset: float = 0.0) -> Rect2:
	var scale_factor: float = minf(maximum_size.x / source_rect.size.x, maximum_size.y / source_rect.size.y)
	var fitted_size: Vector2 = source_rect.size * scale_factor
	return Rect2(Vector2(-fitted_size.x * 0.5, -fitted_size.y + bottom_offset), fitted_size)


static func _source_rect(texture: Texture2D, normalized_region: Rect2) -> Rect2:
	var texture_size: Vector2 = texture.get_size()
	return Rect2(normalized_region.position * texture_size, normalized_region.size * texture_size)


static func get_item_texture(item_id: StringName) -> Texture2D:
	match item_id:
		&"trail_prism":
			return TRAIL_PRISM
		&"moss_tonic":
			return MOSS_TONIC
		_:
			push_error("Missing voxel item texture for item: %s" % item_id)
			return TRAIL_PRISM


static func get_badge_texture(badge_id: StringName) -> Texture2D:
	match badge_id:
		&"ember_crest":
			return EMBER_CREST
		&"deep_delver_mark":
			return DEEP_DELVER_MARK
		_:
			push_error("Missing voxel badge texture for badge: %s" % badge_id)
			return DEEP_DELVER_MARK


static func get_element_texture(element_id: StringName) -> Texture2D:
	match element_id:
		&"ember":
			return EMBER
		&"tide":
			return TIDE
		&"grove":
			return GROVE
		&"storm":
			return STORM
		_:
			push_error("Missing voxel element texture for element: %s" % element_id)
			return GROVE

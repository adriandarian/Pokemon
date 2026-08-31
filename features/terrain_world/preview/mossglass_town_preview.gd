class_name MossglassTownPreview
extends Node

const TOWN: SettlementDefinition = preload(
	"res://features/settlement/content/mossglass_town.tres"
)
const SCATTER: TerrainScatterProfile = preload(
	"res://features/terrain_world/content/mossglass_town_scatter_profile.tres"
)

@onready var _terrain_world: TerrainWorld = %TerrainWorld
@onready var _settlement_runtime: SettlementRuntime = %SettlementRuntime
@onready var _scatter_runtime: TerrainScatterRuntime = %TerrainScatterRuntime
@onready var _props: Node2D = %Props
@onready var _player: PlayerCharacter = %Player
@onready var _camera: Camera2D = %OverviewCamera


func _ready() -> void:
	var player_camera := _player.get_node_or_null("Camera2D") as Camera2D
	if player_camera != null:
		player_camera.enabled = false
	_player.set_movement_enabled(false)
	_player.position = _terrain_world.get_query().cell_to_world_center(Vector2i(60, 56))
	_terrain_world.attach_follower(_player, true)
	_settlement_runtime.configure(TOWN, _terrain_world, _props, null)
	_scatter_runtime.configure(SCATTER, _terrain_world, _props, null)
	_terrain_world.enable_streaming(_player, 2)
	_configure_camera_for_viewport()


func _configure_camera_for_viewport() -> void:
	var viewport_size := Vector2(DisplayServer.window_get_size())
	if viewport_size.x < viewport_size.y:
		_camera.position = Vector2(3000.0, 1850.0)
		_camera.zoom = Vector2(0.34, 0.34)
	else:
		_camera.position = Vector2(3000.0, 1500.0)
		_camera.zoom = Vector2(0.24, 0.24)

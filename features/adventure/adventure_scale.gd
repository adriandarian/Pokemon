class_name AdventureScale
extends RefCounted

# One exploration human is the stable unit for world presentation. Props derive
# from this value so a camera change cannot silently turn architecture into toys.
const HUMAN_HEIGHT: float = 142.0

const PLAYER_DISPLAY_BOX := Vector2(116.0, HUMAN_HEIGHT)
const NPC_DISPLAY_BOX := Vector2(104.0, HUMAN_HEIGHT * 0.96)

const SIGN_HEIGHT_IN_HUMANS: float = 0.72
const LANTERN_HEIGHT_IN_HUMANS: float = 1.72
const TREE_HEIGHT_IN_HUMANS: float = 2.10
const HOUSE_HEIGHT_IN_HUMANS: float = 3.65

const SIGN_DISPLAY_BOX := Vector2(96.0, HUMAN_HEIGHT * SIGN_HEIGHT_IN_HUMANS)
const LANTERN_DISPLAY_BOX := Vector2(152.0, HUMAN_HEIGHT * LANTERN_HEIGHT_IN_HUMANS)
const TREE_DISPLAY_BOX := Vector2(290.0, HUMAN_HEIGHT * TREE_HEIGHT_IN_HUMANS)
const HOUSE_DISPLAY_BOX := Vector2(HUMAN_HEIGHT * 3.90, HUMAN_HEIGHT * HOUSE_HEIGHT_IN_HUMANS)
const ROCK_DISPLAY_BOX := Vector2(144.0, 106.0)

const HOUSE_FOOTPRINT := Vector2(HUMAN_HEIGHT * 3.25, HUMAN_HEIGHT * 0.92)
const HOUSE_COLLISION_OFFSET := Vector2(0.0, -HUMAN_HEIGHT * 0.34)
const TREE_COLLISION_RADIUS: float = HUMAN_HEIGHT * 0.21
const ROCK_COLLISION_RADIUS: float = 24.0
const SIGN_COLLISION_RADIUS: float = 11.0
const LANTERN_COLLISION_RADIUS: float = 17.0

const HOUSE_SOURCE_DISPLAY_HEIGHT: float = 372.0
const HOUSE_ART_SCALE: float = HOUSE_DISPLAY_BOX.y / HOUSE_SOURCE_DISPLAY_HEIGHT
const LANTERN_SOURCE_DISPLAY_HEIGHT: float = 178.0
const LANTERN_ART_SCALE: float = LANTERN_DISPLAY_BOX.y / LANTERN_SOURCE_DISPLAY_HEIGHT
const LANTERN_FLAME_POSITION := Vector2(-19.0, -111.0) * LANTERN_ART_SCALE
const LANTERN_FLAME_SCALE := Vector2.ONE * LANTERN_ART_SCALE

# Zooming out exposes more authored world while the upward focus offset keeps
# the player in the lower third and the now-correct lodge roof inside frame.
const EXPLORATION_CAMERA_ZOOM := Vector2(0.82, 0.82)
const EXPLORATION_CAMERA_OFFSET := Vector2(0.0, -330.0)

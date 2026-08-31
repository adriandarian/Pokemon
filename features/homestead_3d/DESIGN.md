# Homestead 3D baseline

## Player-visible outcome

The starting homestead is a real three-dimensional exploration space presented
through a fixed orthographic camera. The player walks with 3D collision across
a four-metre homestead plateau, an eight-metre wheat terrace, a fitted stone
stair/ramp, a continuous dirt trail, and a timber bridge over water. The camera
preserves the illustrated faux-2D composition while every traversable surface
and blocking landmark participates in 3D physics.

The baseline is authored around protected landmark anchors while repeated grass,
cliff blocks, trees, shrubs, and shoreline modules remain reusable. Future biome
variation can change those module palettes, densities, and seeded placement
rules without moving the route, stair, bridge, or settlement anchors.

## Ownership

- `HomesteadAdventure3D` owns presentation state shared by the world, player,
  HUD, menu, and battle overlay.
- `HomesteadPlayer3D` is the sole owner of player velocity, facing, locomotion,
  and the last safe respawn position.
- `HomesteadWorld3D` owns the authored world geometry and immutable route
  endpoints. It creates no persistent game state.
- Existing `content/*.tres` resources remain read-only during play.

## Scene tree

```text
HomesteadAdventure3D (Node3D)
├── World (Node3D / HomesteadWorld3D)
│   ├── Terrain (StaticBody3D and MeshInstance3D)
│   ├── Route (TrailRibbon3D, stair ramp, bridge deck)
│   └── Props (StaticBody3D landmarks and decorative MeshInstance3D)
├── Player (CharacterBody3D / HomesteadPlayer3D)
│   ├── CollisionShape3D
│   ├── Shadow
│   └── AnimatedSprite3D
├── CameraRig (Faux2DCameraRig)
│   └── Camera3D (orthographic)
├── DirectionalLight3D
├── WorldEnvironment
└── Interface (CanvasLayer)
    ├── AdventureHUD
    ├── GameMenu
    └── BattleOverlay
```

## Public contract

- `HomesteadWorld3D.get_spawn_position() -> Vector3`
- `HomesteadWorld3D.get_route_endpoint(id) -> Vector3`
- `HomesteadWorld3D.get_physics_summary() -> Dictionary`
- `HomesteadPlayer3D.set_movement_enabled(enabled)`
- `HomesteadPlayer3D.teleport_to(position)`
- `Faux2DCameraRig.set_overview_enabled(enabled)`

The route contract is exact: north trail end equals stair top, stair bottom
equals lower trail start, lower trail end equals bridge north, and bridge south
equals southern trail start. Visual connector pieces never overlap as separate
flat images.

## Failure modes

- Missing 3D collision is detected by the isolated smoke test body-type and
  shape counts.
- Route seams are detected by exact endpoint assertions.
- Stair traversal uses one smooth, invisible `BoxShape3D` ramp; visible treads
  cannot snag the character capsule.
- Water has no walkable floor except at the bridge and owns a hazard `Area3D`
  that returns the player to its last safe position.
- If the generated animation atlas is unavailable, the player reports an error
  rather than silently swapping to a non-animated placeholder.

## Isolated validation

Run `tests/homestead_3d_smoke_test.tscn` headlessly. It verifies the orthographic
camera, `CharacterBody3D`, 3D collision owners, exact route joins, ramp slope,
bridge collision, elevated surfaces, and `AnimatedSprite3D` clips. Visual QA is
captured in desktop, portrait overview, and narrow viewports.

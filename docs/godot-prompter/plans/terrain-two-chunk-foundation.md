# Isolated two-chunk terrain foundation plan

Approval: the persistent authored overworld with compiled procedural-hybrid
terrain is an approved project direction as of 2026-08-30.

Status: reference implementation plan. The current branch has already advanced
beyond this minimum slice to a live `2 x 2` Windfall village and a `4 x 3`
Mossglass town. This document preserves the smallest reproducible foundation for
future ports, regressions, or a clean-room rebuild without weakening the larger
implementation.

## Player outcome

An isolated exploration preview contains two adjacent terrain chunks that read
as one persistent authored place. The player can walk from a low riverward
chunk into a raised meadow chunk, cross the chunk seam without a visual or
collision discontinuity, climb a broad ramp and civic stair, and remain grounded
at the same elevation as buildings and natural props.

The slice proves the terrain contract. It does not attempt to make a village,
town, city, save format, quest, or complete campaign route.

## Locked decisions

- Keep the project in Godot 4.5 typed GDScript and faux-2.5D exploration.
- Keep canonical movement and collision in 2D ground coordinates.
- Project visuals and the camera upward by sampled elevation; do not replace the
  player with a 3D controller.
- Use deterministic noise only to propose broad natural variation.
- Apply ordered authored stamps after procedural proposal so roads, parcels,
  water, bridges, ramps, stairs, and required entrances always win.
- Treat region, biome, stamp, and compiled chunk Resources as read-only during
  play.
- Make one compiled chunk dataset authoritative for drawing, collision,
  traversal, biome sampling, and actor projection.
- Keep communication local. This slice adds no global `EventHub` signal.

## Exact slice

The preview region is `2 x 1` chunks. Each chunk is `32 x 32` cells at 48 world
units per cell, producing a 3072 by 1536 world.

| Chunk | Responsibility | Elevation and biome |
|---|---|---|
| `(0, 0)` | Riverward lowland, bridge approach, wet meadow, start position | Mostly level 0; wetland and meadow |
| `(1, 0)` | Raised settlement terrace, protected parcel, civic stair, wild edge | Level 1 terrace with one level 2 highland parcel |

Required authored topology:

- One five-cell-wide arterial road crosses the `x = 31/32` chunk seam.
- One bridge crosses a narrow water stamp in the lowland chunk.
- One broad ramp transitions level 0 to level 1 near the chunk seam.
- One stair connects the level 1 road to the level 2 highland parcel.
- One protected building parcel remains flat and scatter-free.
- Required route points cover the start, bridge, both sides of the seam, ramp,
  settlement road, stair foot, and highland destination.
- Every unstamped water or cliff edge is blocked.

## Ownership and scene composition

```text
TerrainFoundationPreview (Node2D)       owns preview composition only
|-- TerrainWorld (Node2D)               owns query index and active chunks
|   |-- RoadRenderer (Node2D)           draws authored routes for active chunks
|   `-- Chunks (Node2D)
|       |-- TerrainChunk_0_0 (Node2D)
|       |   |-- TopRenderer (Node2D)
|       |   |-- FaceRenderer (Node2D)
|       |   `-- Collision (StaticBody2D)
|       `-- TerrainChunk_1_0 (Node2D)
|           |-- TopRenderer (Node2D)
|           |-- FaceRenderer (Node2D)
|           `-- Collision (StaticBody2D)
|-- Actors (Node2D, Y-sorted)
|   |-- Props (Node2D, Y-sorted)
|   `-- Player (CharacterBody2D)
`-- Camera2D
```

| Owner | Mutable state | Read-only inputs |
|---|---|---|
| `TerrainWorld` | Active chunk-node set and streaming queue | Region and compiled chunks |
| `TerrainQuery` | Runtime lookup index built at configuration | Compiled cell arrays |
| `PlayerCharacter` | Position, velocity, facing, movement state | Terrain samples through its follower |
| `TerrainFollower2D` | Last sampled cell/elevation | `TerrainQuery` |
| Compiler tool | Temporary generation buffers and validation report | Region, biome, and stamp definitions |

Compiled Resources are never rewritten by runtime exploration. Recompilation is
an explicit editor/headless build step.

## Local signal map

| Signal | Source | Consumer | Payload and purpose |
|---|---|---|---|
| `terrain_ready` | `TerrainWorld` | Preview composition | Query and initial chunks are usable |
| `chunk_activated` | `TerrainWorld` | Road/prop lifecycle | `Vector2i` chunk coordinate became live |
| `chunk_deactivated` | `TerrainWorld` | Road/prop lifecycle | `Vector2i` chunk coordinate left the live set |
| `streaming_settled` | `TerrainWorld` | Tests and transitions | Staged activation queue is empty |
| `terrain_sample_changed` | `TerrainFollower2D` | Explicit target integration | New `TerrainSample` for visual projection |

Calls travel downward from the preview composition into `TerrainWorld`, the
player, and followers. Signals report completed local lifecycle changes upward.

## Data flow

```text
TerrainRegionDefinition
  + TerrainBiomeDefinition[]
  + ordered TerrainStampDefinition[]
  + deterministic FastNoiseLite proposal
                    |
                    v
             TerrainCompiler
       proposal -> authored overrides
       -> seam/topology validation
                    |
                    v
        two immutable TerrainChunkData files
          |             |              |
          v             v              v
       renderers     collision      TerrainQuery
                                         |
                                         v
                         player/prop/camera projection
```

## Ordered implementation tasks

- [ ] **Task 1: Freeze the two-chunk data contract** — Define typed Resources
  for region settings, biome presentation, ordered stamps, compiled cell arrays,
  and terrain samples. Document stable IDs, compiler version, array dimensions,
  and invalid-sample behavior.
  Skills: `godot-prompter:resource-pattern`,
  `godot-prompter:scene-organization`

- [ ] **Task 2: Implement deterministic compilation** — Build the broad
  elevation/moisture proposal with dedicated deterministic noise, then apply
  elevation, biome, water, road, parcel, ramp, stair, and bridge stamps in
  authored order. The compiler must run headlessly and save Resources only
  outside gameplay.
  Skills: `godot-prompter:procedural-generation`,
  `godot-prompter:resource-pattern`, `godot-prompter:gdscript-advanced`

- [ ] **Task 3: Author the exact two-chunk region** — Create the riverward and
  raised-meadow chunks, protected parcel, seam-crossing road, bridge, ramp,
  stair, biome transition, and required route points. Use stable stamp IDs and
  keep every connector comfortably wider than the player collision footprint.
  Skills: `godot-prompter:procedural-generation`,
  `godot-prompter:math-essentials`

- [ ] **Task 4: Validate topology before saving** — Reject missing biomes,
  mismatched cell-array lengths, out-of-bounds stamps, incompatible compiler
  versions, seam disagreement, unreachable required route points, and walkable
  boundaries leading into missing chunks. Validation failure must produce no
  apparently successful output.
  Skills: `godot-prompter:godot-testing`,
  `godot-prompter:gdscript-patterns`

- [ ] **Task 5: Build query, presentation, and collision from one source** —
  Implement world/cell conversion, cell and edge traversal queries, top and
  cliff-face renderers, road rendering, and blocked-edge collision. Do not keep
  a separate hand-maintained collision map.
  Skills: `godot-prompter:math-essentials`,
  `godot-prompter:physics-system`, `godot-prompter:shader-basics`

- [ ] **Task 6: Add explicit terrain followers** — Attach reusable followers to
  the preview player and representative static prop. Keep physics positions in
  canonical coordinates while shifting only visuals and camera framing by the
  sampled elevation.
  Skills: `godot-prompter:player-controller`,
  `godot-prompter:camera-system`, `godot-prompter:component-system`

- [ ] **Task 7: Build the isolated preview scene** — Compose only the two
  compiled chunks, player, one building proxy, one natural prop, and camera.
  The preview must run directly without depending on `AdventureController`, UI,
  battle, or global scene searches.
  Skills: `godot-prompter:scene-organization`,
  `godot-prompter:camera-system`

- [ ] **Task 8: Prove behavior and performance** — Add headless checks for
  deterministic recompilation, representative samples, bridge/ramp/stair
  traversal, blocked water/cliffs, seam continuity, collision creation,
  follower projection, and clean preview instantiation. Record compile time and
  activation time; stage activation if the observed main-thread cost would
  create a visible hitch.
  Skills: `godot-prompter:godot-testing`,
  `godot-prompter:godot-optimization`

- [ ] **Task 9: Capture the visual acceptance gate** — Capture desktop and
  narrow views from the start, seam/ramp, and stair/highland positions. Inspect
  road continuity, grounded feet, parcel flatness, cliff readability, camera
  framing, and the absence of exposed void or one-frame chunk gaps.
  Skills: `game-development-studio:game-visual-debugging`,
  `godot-prompter:camera-system`

- [ ] **Task 10: Gate live integration** — Only after the isolated behavior,
  startup, performance, and visual gates pass, connect the same `TerrainWorld`
  contract to Adventure. Preserve movement, interactions, visible wild
  creatures, HUD, and flat battle presentation. Do not duplicate terrain logic
  in `AdventureController`.
  Skills: `godot-prompter:scene-organization`,
  `godot-prompter:godot-testing`, `godot-prompter:godot-code-review`

## Acceptance gates

- Compiling the same inputs twice produces byte-equivalent cell fields.
- Both chunk Resources contain exactly `32 x 32` cells and the expected compiler
  version and region ID.
- The arterial road and traversal flags agree across the chunk seam.
- A route search reaches every required point, including the level 2 parcel.
- Water and unstamped elevation changes block movement; bridge, ramp, and stair
  edges remain traversable.
- Rendered tops, cliff faces, collision, and queries all derive from the same
  compiled arrays.
- Player, prop, and camera projection agree on sampled elevation.
- The preview scene runs directly and the complete project starts headlessly.
- Desktop and narrow captures show grounded actors and no seam, void, floating
  parcel, clipped HUD, or camera discontinuity.
- The final report separates parse/startup, automated tests, measured
  performance, visual inspection, and intentionally deferred work.

## Deliberately deferred

- Town/city density, district travel, interiors, shops, quests, and save deltas.
- Runtime terrain deformation or erosion simulation.
- Navigation meshes and autonomous long-distance NPC routing.
- A general-purpose terrain editor UI.
- Choosing campaign travel semantics or replacing the locked battle view.

These are separate vertical slices. None is required to prove the persistent
authored overworld terrain contract.

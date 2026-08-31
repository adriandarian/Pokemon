# Compiled terrain world

## Player-visible outcome

Exploration uses land with real traversable elevation. Broad terraces, stairs,
ramps, bridges, cliff walls, paths, water, and biome changes form one continuous
faux-2.5D world. The player cannot walk through an unstamped cliff or water edge;
the same terrain sample grounds characters, props, creatures, camera framing,
and future encounter/footstep rules.

## Mutable-state owner

`TerrainWorld` owns the streamed chunk-node set and read-only complete query index. Compiled
`TerrainChunkData` and all authored terrain definitions are immutable during
play. Actor movement remains owned by each actor; future save data may contain
gameplay deltas but never rewrites the terrain definitions.

## Scene tree

```text
TerrainWorld
`-- Chunks
    `-- TerrainChunk_x_y
        |-- TopRenderer             projected tops, paths, stairs, biome tint
        |-- FaceRenderer            foreground cliff/retaining faces
        `-- StaticBody2D            blocked edges from the same chunk data
```

The live `Adventure` remains the composition root. It explicitly configures
terrain followers for actors it owns; terrain never searches parent chains for
the player, HUD, or world controller.

## Public contract

| Type | Responsibility |
|---|---|
| `TerrainRegionDefinition` | Read-only seed, chunk/cell scale, biome set, ordered stamps, required route points |
| `TerrainBiomeDefinition` | Stable biome ID and presentation colors |
| `TerrainStampDefinition` | Authored elevation, biome, road, water, parcel, stair, ramp, or bridge override |
| `TerrainCompiler` | Deterministically produce and validate immutable chunks outside normal gameplay |
| `TerrainChunkData` | Packed cell elevation, surface, biome, and traversal flags for one chunk |
| `TerrainQuery` | Sample world positions and answer edge-traversal questions without SceneTree access |
| `TerrainWorld` | Index compiled data and materialize the focus chunk plus a configurable, frame-budgeted neighbor ring |
| `TerrainFollower2D` | Project one explicitly supplied actor using the shared query |
| `TerrainScatterProfile` | Read-only biome, spacing, seed, density, and authored exclusion rules |
| `TerrainScatterRuntime` | Deterministically materialize natural props only for active chunks |

## Signal map

Terrain adds no global event. `TerrainWorld.terrain_ready`, `chunk_activated`,
`chunk_deactivated`, and `streaming_settled` are local to the composition. The
full query index stays resident while only nearby render/collision nodes
materialize. Chunk activations are distance-sorted and capped per physics frame;
settlement and scatter runtimes subscribe locally to the same lifecycle.

## Data flow

```text
region .tres + ordered stamps + deterministic noise proposal
                         |
                         v
                 TerrainCompiler
                         |
                         v
        immutable TerrainChunkData .tres files
             |              |              |
             v              v              v
          drawing        collision      TerrainQuery
                                             |
                                             v
                                actor/camera presentation
```

Calls travel downward from `AdventureController` into `TerrainWorld` and actor
followers. The local `terrain_ready` signal travels upward. `EventHub` is not used
for cell samples, elevation changes, or chunk-internal work.

## Failure modes

- Missing or incompatible chunk data blocks startup with an explicit error.
- A missing adjacent chunk is a blocked boundary, never walkable void.
- Compiler validation rejects array-size errors, out-of-bounds stamps,
  unreachable required route points, and mismatched chunk seams.
- Runtime sampling outside compiled bounds returns an invalid, non-walkable
  sample.
- An unloaded chunk removes its terrain presentation, road segments, and
  collision as one unit; the neighbor ring prevents the player from seeing the
  swap during ordinary travel.
- Procedural proposal never overwrites later authored roads, parcels, stairs,
  ramps, bridges, or required entrances.

## Isolated validation

`features/terrain_world/preview/terrain_world_preview.tscn` instantiates the same
compiled region used by the live adventure.
`features/terrain_world/preview/mossglass_town_preview.tscn` composes the larger
town terrain, buildings, scatter, player scale reference, and streaming focus.
`tests/terrain_world_smoke_test.tscn` checks deterministic compilation,
representative terrain samples, traversable connectors, blocked cliffs/water,
chunk instantiation, and collision creation. The town smoke test additionally
records the peak staged activation time against a 100 ms budget.

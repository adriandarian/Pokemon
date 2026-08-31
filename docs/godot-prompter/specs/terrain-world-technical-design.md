# World terrain technical design

> Status: detailed draft for designer review. This document assumes the
> recommended compiled-hybrid approach in `terrain-world-redesign.md`; it does
> not authorize implementation or reconnect the rejected elevation prototype.

## Player-visible outcome

Exploration remains a 2D, fixed-camera, faux-2.5D world, but land is no longer a
flat texture. The player can read and traverse low ground, terraces, hills,
stairs, ramps, bridges, and cliff boundaries. Biomes change the terrain palette
and environmental population without hiding roads or characters. Settlements
can grow from individual parcels into villages, towns, and streamed city
districts while retaining human-relative scale.

The first complete slice should look like
`terrain-gameplay-elevation-concept.png`: three elevation bands, one stair, one
ramp, a blocked cliff edge, one biome transition, one building, and grounded
actors in a normal exploration frame.

## Architectural decision

Use a **compiled hybrid terrain graph**:

```text
authored Resources + deterministic procedural proposal + authored stamps
                                |
                                v
                       TerrainCompiler (editor)
                                |
                                v
                  immutable TerrainChunkData resources
                    /              |               \
                   v               v                v
             presentation      collision        navigation
                   \               |                /
                    +------ TerrainQuery ---------+
                                |
                                v
                    actor projection and biome use
```

The generated image, drawn polygons, collision shapes, and navigation polygons
are outputs. None of them is the authoritative terrain definition.

## Coordinate and scale contract

- Canonical gameplay positions remain `Vector2` coordinates on the logical
  ground plane. Movement, interactions, chunk lookup, saving, and encounter
  positions use this space.
- The visual projection is `view_position = world_position + Vector2.UP *
  elevation_pixels`.
- Proposed terrain cell size: `48 px`, about `0.34` of the existing `142 px`
  exploration human height.
- Proposed elevation step: `48 px`. A terrace may span several steps, but one
  cell-to-cell transition may only be traversed when an explicit stair or ramp
  stamp permits it.
- Chunk size: `32 x 32` cells, or `1536 x 1536` canonical world pixels. The live
  starter district is `2 x 2` chunks (`3072 x 3072` canonical pixels), large
  enough for Windfall's village core plus southern expansion terraces.
- Minimum main-road width: four cells (`192 px`), leaving at least two actor
  widths for opposing movement and roaming creatures.
- Scale constants remain derived from `AdventureScale`; terrain does not invent
  a second human or building scale.

These numbers are calibration defaults for the isolated slice. Tests should own
the ratios so later tuning cannot silently turn architecture back into props.

## Scene tree

```text
Adventure (Node)
├── TerrainWorld (Node2D)                         region and active-chunk owner
│   ├── TerrainBackplane (Node2D)                 projected top surfaces and water
│   ├── ProjectedWorld (Node2D, y-sorted)         occluders and visual proxies
│   │   ├── TerrainFace_* (Node2D)                batched cliff/retaining segments
│   │   ├── PropVisualProxy_* (Node2D)            projected static prop visuals
│   │   └── ActorVisualProxy_* (Node2D)           projected moving actor visuals
│   ├── ChunkPhysics (Node2D)                     one static body per active chunk
│   ├── ChunkNavigation (Node2D)                  regions and traversal links
│   └── TerrainChunks (Node2D)                    active chunk lifecycle roots
│       └── TerrainChunk_x_y (Node2D, reusable scene)
│           ├── SurfaceRender (Node2D/TileMapLayer)
│           ├── FaceRender (Node2D)
│           ├── StaticBody2D
│           │   └── CollisionShape2D              batched cliff-edge segments
│           ├── NavigationRegions (Node2D)
│           ├── NavigationLinks (Node2D)
│           └── Scatter (MultiMeshInstance2D/Node2D)
├── Actors (Node2D)                               canonical gameplay bodies
│   ├── Props
│   ├── WildCreatures
│   └── Player
├── Props (StaticBody2D)                          non-terrain authored footprints
└── Interface (CanvasLayer)                       unaffected
```

`TerrainChunk` is independently previewable and must pass the F6 isolation test.
`TerrainWorld` composes chunks but does not contain player, encounter, quest, or
HUD logic.

## Node responsibilities

| Owner | Responsibility |
|---|---|
| `TerrainWorld` | Own the loaded region, active chunk set, shared query object, and local chunk lifecycle |
| `TerrainChunk` | Materialize one immutable `TerrainChunkData` into render, collision, navigation, and scatter nodes |
| `TerrainQuery` (`RefCounted`) | Read packed chunk data and fill reusable samples; no SceneTree access or mutable world state |
| `TerrainFollower2D` | Sample the canonical body position and update its visual proxy, surface, biome, and camera target |
| `TerrainCompiler` (`@tool`/headless tool) | Combine proposal fields and authored stamps, validate topology, and save compiled chunk resources |
| `TerrainSurfaceRenderer` | Render projected top surfaces and biome blends from compiled data |
| `TerrainFaceRenderer` | Render only non-traversable exposed height differences and retaining walls |
| `GameSession` / future save service | Own player position and per-chunk gameplay deltas; never own base terrain definitions |

## Resource model

All authored and compiled Resources are read-only during play.

### `TerrainRegionDefinition`

- stable `region_id: StringName`;
- deterministic `seed: int`;
- region dimensions and chunk coordinates;
- ordered biome definitions;
- macro elevation, moisture, and flow generator settings;
- authored stamp layers;
- references to compiled chunk resources;
- compiler schema/version and source hash.

### `BiomeDefinition`

- stable `biome_id: StringName`;
- terrain palette / TileSet terrain references;
- allowed elevation, moisture, and slope ranges;
- render tint and restrained overlay rules;
- deterministic scatter profiles and exclusion radii;
- surface/footstep identifier;
- no creature spawning, quest, or mutable session state.

Location and biome are deliberately different. `LocationDefinition` names a
semantic place such as Windfall Village; a location may contain several biomes.
Future authored spawn tables may consume a biome ID, but the biome never spawns
creatures directly.

### `TerrainStampDefinition`

An ordered, non-destructive authoring instruction:

- stamp kind: elevation, flatten, road, water, biome paint, protected parcel,
  cliff, stair, ramp, bridge, gate, cave link, scatter exclusion;
- shape and canonical transform;
- target/start/end elevation;
- falloff or blend width where applicable;
- priority and stable ID;
- optional validation tags such as `required_route` or `landmark_foundation`.

Roads, plazas, stairs, ramps, building parcels, landmarks, and quest-critical
spaces are late, authoritative stamps. Noise may not overwrite them.

### `TerrainChunkData`

One compact compiled Resource per chunk:

- chunk coordinate and world bounds;
- packed elevation levels;
- packed dominant surface and biome IDs plus optional blend weights;
- blocked-edge bit flags;
- explicit stair/ramp/bridge traversal records;
- projected surface/face batches;
- batched collision segments;
- navigation island polygons and link endpoints;
- deterministic scatter transforms and source IDs;
- compiler version, source hash, and neighboring seam hashes.

The compiler may save large packed chunks as `.res`; editable definitions remain
`.tres`. Runtime code must reject incompatible compiler versions instead of
silently rendering stale data.

### Runtime-only values

`TerrainSample` is a reusable `RefCounted`, not a Resource on disk. Each moving
follower owns one and passes it to `TerrainQuery.sample_into(position, sample)` to
avoid allocating a Dictionary or object every physics tick.

It contains:

- cell and chunk coordinate;
- continuous elevation level and pixel offset;
- surface and biome IDs;
- ramp/stair traversal kind and progress;
- whether the sample is valid and navigation-ready.

## Terrain topology and traversal

For each cardinal edge between cells:

| Relationship | Traversal | Output |
|---|---|---|
| Same elevation | Open | Continuous surface/nav island |
| Different elevation, no traversal stamp | Blocked | Cliff/retaining face + collision segment + separate nav islands |
| Different elevation, stair stamp | Open through stair footprint | Stepped visual elevation + bidirectional navigation link |
| Different elevation, ramp stamp | Open through ramp footprint | Continuous interpolated elevation + bidirectional navigation link |
| Water/void without bridge or allowed movement mode | Blocked | Boundary/collision + separate navigation |
| Bridge/gate/cave link | Explicit | Authored visual and navigation link with stable ID |

This topology is shared by player collision and AI navigation. The renderer is
not allowed to show an open route where the collision compiler emits a cliff.

Stair elevation snaps by tread for presentation. Ramp elevation interpolates
smoothly along its authored axis. A traversal stamp must declare exact start and
end levels; inferred stairs from texture colors are forbidden.

## Rendering and sorting contract

The rejected prototype kept gameplay bodies at logical positions and offset only
their child sprites. That is insufficient at settlement scale because Y-sorting
still uses the unprojected body position.

The scalable contract separates gameplay bodies from projected visuals:

1. Player, NPC, creature, and prop bodies remain under canonical `Actors` roots.
2. Each body exposes or creates a visual proxy under `ProjectedWorld`.
3. `TerrainFollower2D` samples the body's canonical position and moves the proxy
   to the projected view position.
4. `ProjectedWorld` Y-sorts proxies together with direct cliff/retaining-face
   render items using their projected ground-contact Y.
5. Terrain top surfaces render in `TerrainBackplane`; cliff faces that must
   occlude actors participate in `ProjectedWorld` at their front-edge sort anchor.
6. The exploration camera follows the player's projected proxy while gameplay
   and save positions remain canonical.
7. UI stays in its existing `CanvasLayer` and never samples terrain.

Static prop proxies sample once when a chunk activates. Moving actors resample in
`_physics_process`, after movement, using a cached chunk lookup.

## Biome generation and blending

Generation is deterministic and layered:

```text
seeded low-frequency elevation proposal
              |
              v
      moisture / simplified flow
              |
              v
 elevation + moisture + slope biome weights
              |
              v
 authored regional masks and protected areas
              |
              v
 roads / parcels / landmarks / traversal stamps
              |
              v
 topology validation -> chunk compilation
```

- Use one seeded `RandomNumberGenerator` and fixed `FastNoiseLite` seeds per
  region/chunk. Global `randf()`/`randi()` are forbidden.
- Generate data off the live SceneTree. Editor compilation may use worker tasks,
  but Resource saving and node previews return to the main thread.
- Hydraulic erosion is represented by a bounded offline filter or imported flow
  mask. It never runs during ordinary exploration.
- Biome transitions use broad low-frequency weights plus authored masks. Avoid
  one-cell checkerboards and hard square swaps.
- Scatter uses deterministic jittered/Poisson-like candidate spacing and respects
  road, parcel, traversal, shoreline, and sightline exclusion masks.
- Procedural output proposes terrain. Authored late stamps always win.

## Chunk lifecycle and world scale

The first slice loads a `2 x 2` district without streaming. The final runtime
contract supports streaming without changing terrain data:

1. `TerrainWorld` derives the player's canonical chunk coordinate.
2. It requests the desired local neighborhood and keeps a larger hysteresis ring
   to avoid boundary thrashing.
3. Chunk Resources load through `ResourceLoader.load_threaded_request()`.
4. `TerrainChunk` nodes are instantiated and attached on the main thread.
5. The chunk validates compiler version and seam hashes before activation.
6. Terrain presentation, collision, and navigation become ready as one unit.
7. Saved gameplay deltas are applied only after the immutable base chunk exists.
8. Distant chunks remove actors, navigation, physics, render items, and cached
   query data before being freed.

The world should prefer dense points of interest and named districts over an
empty continuous map. A city is several district regions/chunk groups with gates
or streaming boundaries, not one scene containing hundreds of always-active
buildings.

## Signal map

| Signal | Source | Consumer | Payload / purpose |
|---|---|---|---|
| `initial_region_ready(spawn_position)` | `TerrainWorld` | `AdventureController` | Safe point at which actors may be enabled |
| `chunk_activated(chunk_coord)` | `TerrainWorld` | local adventure/world composition | Spawn or restore chunk-scoped actors and deltas |
| `chunk_deactivating(chunk_coord)` | `TerrainWorld` | local adventure/world composition | Capture deltas and release chunk-scoped actors |
| `terrain_sample_changed(sample)` | `TerrainFollower2D` | its actor presentation/audio components | Elevation, surface, or biome changed |
| `terrain_compile_finished(report)` | editor `TerrainCompiler` | editor preview/deterministic test | Compiled outputs and validation findings |
| `terrain_compile_failed(report)` | editor `TerrainCompiler` | editor preview/deterministic test | Invalid seams, topology, or required routes |

These are local feature signals. Terrain does not add per-chunk or per-step events
to `EventHub`; only existing cross-feature location lifecycle events belong there.

## Runtime data flow

```text
PlayerCharacter._physics_process
        |
        +-- move canonical CharacterBody2D against compiled cliff collision
        |
        +-- TerrainFollower2D.sample_into(global_position)
                    |
                    +-- elevation -> projected visual proxy + camera target
                    +-- surface   -> footsteps / movement hooks
                    +-- biome     -> presentation and future spawn-table query
                    +-- invalid   -> keep last valid projection + report once
```

Chunk activation follows the inverse direction: `TerrainWorld` calls down into a
new `TerrainChunk.configure(data)`, the chunk builds its children, then emits ready
upward. Chunks never search parent chains for the player or HUD.

## Persistence contract

Base terrain is immutable and reproduced from compiled data. Saves contain only:

- stable region/chunk IDs and compiler-compatible world version;
- canonical player position and facing;
- region seed only when a location is intentionally runtime-generated;
- per-chunk gameplay deltas such as collected objects, opened gates, or defeated
  one-time actors;
- authored world flags already owned by `GameSession`.

Do not serialize render meshes, tile layers, collision shapes, navigation meshes,
biome textures, or entire generated chunks into every save.

## Failure modes

- **Chunk seam mismatch:** compiler fails and reports both chunk coordinates; no
  runtime gap-filling guess.
- **Required route disconnected:** compilation fails if spawn, exits, stairs,
  ramps, building entrances, or required POIs are unreachable.
- **Traversal level mismatch:** stair/ramp start and end levels must match adjacent
  terrain exactly.
- **Stale compiled data:** runtime rejects a compiler-version/source-hash mismatch
  and shows an explicit development error.
- **Missing chunk:** keep the boundary blocked and report once; never allow walking
  into void.
- **Navigation not ready:** roaming AI remains idle until the local region signals
  readiness.
- **Invalid terrain sample:** follower retains its last valid projection instead
  of snapping to level zero.
- **Scatter collision:** compiler exclusion masks prevent props from occupying
  roads, parcels, stairs, ramps, entrances, or required sightlines.
- **Stream thrashing:** a keep radius larger than the load radius prevents rapid
  load/unload at chunk borders.
- **Proxy lifetime error:** follower releases its visual proxy when the canonical
  body exits the tree; no dangling projected visuals.

## Isolated vertical slice

Before replacing `AdventureWorldCanvas`, build a deterministic terrain-preview
scene with four adjacent chunks:

- three elevation bands;
- one blocked cliff boundary;
- one wide stair and one broad ramp;
- one continuous four-cell-wide road;
- a wet-lowland to village-meadow to dark-wild biome gradient;
- the existing lodge, player, Ranger Sela, one tree group, and one roaming
  creature attached through projected proxies;
- one cross-chunk road and elevation seam;
- no runtime streaming, city generation, quests, or save migration.

The live adventure integrates only after this preview passes behavior, visual,
and performance validation.

## Validation gates

### Deterministic data tests

- same seed and ordered stamps produce byte-identical chunk fields;
- different seed changes only procedural proposal areas, never protected stamps;
- representative samples return correct base, terrace, stair-tread, and ramp
  elevations;
- blocked-edge derivation matches collision and navigation island boundaries;
- every required route and entrance is reachable;
- adjacent chunks agree on elevation, surface, road, water, and traversal seams.

### Headless scene tests

- isolated preview and each `TerrainChunk` scene instantiate without errors;
- player cannot cross a cliff but can cross the stair and ramp in both directions;
- canonical player coordinates stay unchanged by visual projection;
- a moving creature changes elevation only through a valid traversal link;
- missing or stale chunk data fails explicitly;
- the full project starts without parser or resource errors.

### Visual inspection

Capture the preview at the existing desktop viewport and a narrow window. Inspect:

- three height bands read immediately;
- stair width, ramp grade, and road continuity are unambiguous;
- characters, props, and contact shadows stay grounded on every level;
- projected actor and cliff-face sorting has no pop-through;
- terrain top texture is calmer than the generated concept;
- biome transition does not hide routes or interaction targets;
- HUD and battle presentation remain unaffected.

### Performance evidence

Profile the four-chunk district and a one-chunk streamed view before setting
budgets. Record draw calls, script
time, physics time, active nodes, and chunk activation time. Optimization follows
measured bottlenecks; it must not replace the complete topology contract with a
smaller visual-only prototype.

## Migration from the live world

1. Keep `AdventureWorldCanvas` and all current gameplay paths intact.
2. Build the isolated terrain preview and proxy contract beside the live scene.
3. Reuse the rejected prototype only as visual/math evidence; do not import its
   hard-coded region polygons or elevation-neutral traversal contract.
4. Convert the current trail, river, preserve boundary, lodge parcel, and prop
   anchors into ordered authored stamps for the preview region.
5. Replace the live world canvas only after parity captures prove interaction,
   battle entry, river/fence blocking, camera framing, and current smoke tests.
6. Remove or archive the rejected prototype only in a separately approved cleanup.

## Decisions still requiring designer approval

- Confirm authored persistent overworld with editor-time generation, versus a
  different world on each save.
- Confirm the compiled hybrid approach over pure TileMap or continuous heightfield.
- Confirm the proposed `48 px` cell/elevation step and `32 x 32` chunk calibration
  as the starting slice, not a permanent art constraint.
- Confirm whether ramps are required everywhere stairs appear for accessibility,
  or only on critical routes.
- Confirm whether cities are seamless streamed district groups or explicit gated
  location transitions.

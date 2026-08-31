# World animation design

## Player-visible outcome

Windfall Village reads as a living voxel diorama. The explorer and Ranger Sela
use authored idle, walk, and run frames; front-facing idle cycles include blinks
and expression changes. Holding Shift makes the explorer run. Long grass bends
in shared gusts, light debris reveals the wind direction, lantern flames lean and
flutter with the same gusts, and layered river crests travel into the bank before
breaking into bright blocky foam.

The feature strengthens the locked faux-2.5D exploration presentation. It does
not change battle composition, encounter rules, authored content Resources, or
the original voxel-art direction.

## Ownership and data flow

```text
Player input -> PlayerCharacter velocity/run intent -> PlayerVisual clip
                                              |
Ranger patrol -> AdventureNpc velocity/state -> AdventureNpcVisual clip

AmbientWind (visual time and gust sample)
      |-------------> WindGrass + WindMotes
      |-------------> ShorelineWaves
      `-------------> LanternFlame instances
```

- `PlayerCharacter` remains the only owner of player velocity, facing, and run
  intent. `PlayerVisual` only selects and presents a clip.
- `AdventureNpc` owns Ranger Sela's small authored patrol, velocity, idle timer,
  and locomotion state. Its visual only observes those values.
- `AmbientWind` owns presentation-only wind phase and exposes a deterministic
  position sample. It never changes collision or gameplay state.
- `content/*.tres` remains read-only during play.

## Scene tree and integration

```text
Adventure
├── AmbientWind
├── WorldCanvas
│   ├── WaterSurface
│   ├── ShorelineWaves
│   ├── RiverOverlay
│   ├── WindGrass
│   `── WindMotes
`── Actors
    ├── Player
    │   `── PlayerVisual / AnimatedSprite2D
    └── Props
        ├── AdventureNpc / AdventureNpcVisual / AnimatedSprite2D
        `── AdventureProp / LanternFlame (lanterns only)
```

`AdventureController` performs explicit dependency injection after nodes are
ready and while authored actors are spawned. Visual consumers do not scan groups
per frame or walk arbitrary parent chains to find the wind source.

## Generated atlas contract

The three 1254 x 1254 atlases under `assets/voxel/` are immutable generated
sources. Each is a 3 x 3 grid of 418 px cells:

- row 0: idle and facial/shoulder gestures;
- row 1: three walk poses;
- row 2: three run poses.

`VoxelAssetLibrary` owns the semantic atlas lookup and stable frame crops. A
shared `HumanAnimationAtlas` helper builds `SpriteFrames` libraries at runtime;
consumers never infer image padding or crop bounds independently.

## Reduced motion

Reduced-motion mode freezes wind phase, grass bend, motes, shoreline travel, and
flame flutter at calm readable poses. Human clips keep the state silhouette but
freeze on a representative frame so movement feedback is preserved without
continuous animation.

## Failure modes

- Atlas padding or pose variance: fixed-size, per-cell source crops preserve a
  stable baseline and subject scale; the original single portraits remain
  separate source assets.
- Repeated `play()` calls: visuals switch clips only when the requested clip
  changes, so frame timing is not reset every physics frame.
- NPC obstruction: Ranger Sela patrols a compact authored loop in the lodge yard,
  away from the painted walkway, and returns to idle when a target is reached.
- Desynchronized effects: all wind consumers sample one `AmbientWind` owner.
- Excess redraw cost: grass and wind motes are isolated from the static world
  canvas; only the animated overlay nodes redraw each frame.
- Shoreline overdraw: wave fronts use a small fixed point count and three crests.

## Isolated validation

1. Instantiate the atlas helper and assert all idle/walk/run clips and frame
   counts are present.
2. Instantiate `AdventureNpc`, advance its deterministic preview state, and
   verify its visual transitions between idle, walk, and run.
3. Assert the adventure scene contains one wind owner and each animated overlay.
4. Run both existing headless smoke-test scenes and start the full project
   headlessly to catch parser, resource, or import errors.
5. Capture exploration at separated frame delays plus a narrow viewport. Compare
   static terrain crops and animated shoreline/grass/flame regions, then inspect
   the complete frames for crop popping, grounding, halos, clipping, and motion
   readability.

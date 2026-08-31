# Terrain elevation and view projection

> Prototype status: rejected and disconnected from the live adventure scene.
> This folder is retained only as experimental reference and is not the current
> terrain contract.

## Player-visible outcome

Windfall Village and Mossglass Wilds read as places built on land rather than
sprites arranged over a flat picture. The lodge stands on an authored stone
footprint, the village and preserve occupy distinct raised terraces, trails
climb through deliberate ramps, and terrain edges expose voxel earth and stone.

The game remains a 2D Godot project. Gameplay coordinates describe the ground
plane from above; elevation is separate data. The fixed faux-2.5D camera affects
how that data is presented, never the positions at which the world is authored.

## Scene tree

```text
Adventure
├── WorldCanvas                      world-specific trail and decoration
│   └── ElevatedTerrainRenderer      top surfaces and camera-facing cliff faces
├── WorldCollision                   canonical ground-plane collision
├── Actors (Y-sorted)                canonical ground-plane positions
│   ├── Props                        static visuals sample elevation once
│   ├── WildCreatures                moving visuals resample elevation
│   └── Player                       movement/collision remains elevation-neutral
└── Interface (CanvasLayer)          unaffected by world projection
```

## Responsibilities

| Owner | Responsibility |
|---|---|
| `TerrainElevationMap` | Read-only terrace footprints, ramp rules, elevation sampling, and world-to-view height offset |
| `ElevatedTerrainRenderer` | Render generated top/face materials against the elevation definitions |
| `AdventureWorldCanvas` | Draw the projected trail, preserve markings, flowers, and fence |
| `AdventureController` | Apply sampled presentation elevation to the actors it already owns |
| Actor visual classes | Offset art and contact shadow without moving gameplay collision |

## Data flow

```text
authored ground position
        |
        +--> collision / interaction / roaming (unchanged)
        |
        +--> TerrainElevationMap.elevation_pixels_at(position)
                  |
                  +--> terrain top and cliff projection
                  +--> sprite and contact-shadow presentation offset
```

No mutable gameplay state is added. Terrain definitions are read-only and do
not mutate `content/*.tres` resources.

## Public contract

- `TerrainElevationMap.elevation_level_at(world_position)` returns the authored
  height in terrain levels, including ramp interpolation.
- `TerrainElevationMap.elevation_pixels_at(world_position)` returns the view
  offset magnitude for a world-space anchor.
- `TerrainElevationMap.to_view(world_position)` projects a ground point into the
  fixed camera presentation without changing the authored position.
- World visual classes accept `set_ground_elevation_pixels(value)`; collision,
  interaction origins, and navigation coordinates remain unchanged.

## Failure modes

- A position outside all authored footprints resolves to the base elevation.
- Missing generated materials fail visibly at preload time rather than silently
  changing collision or gameplay.
- A visual that does not implement the elevation method remains at base level;
  the controller only calls explicit typed presentation contracts.
- Terrace fronts are authored separately from footprints so ramps can leave a
  deliberate opening instead of drawing an impassable cliff across the trail.

## Isolated validation

1. Assert representative base, terrace, and ramp samples in the gameplay smoke
   test.
2. Start the full project headlessly and fail on parser or resource errors.
3. Capture the exploration view at 1280 x 720 and inspect the lodge foundation,
   terrace fronts, ramp continuity, actor contact, and UI separation.
4. Move the player across an elevation boundary in the smoke test and verify its
   logical position does not change while the visual offset does.

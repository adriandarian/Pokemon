# Homestead baseline

## Player-visible outcome

The live exploration scene opens on one intimate medieval homestead instead of
the former village showcase. A winding northern trail reaches a fenced cottage
yard, a high wheat terrace rises behind it, a stone stair descends toward the
river, and a timber bridge carries the route into the southern meadow.

The reference image is the composition contract. Its beige scale inset is not
game UI and is intentionally omitted. The terrain, stairs, bridge, water,
landmarks, collisions, and player remain separate runtime elements so this is a
playable baseline rather than a flattened backdrop.

## Runtime ownership

`Adventure` remains the composition root. `TerrainWorld` owns active terrain
chunks and immutable terrain queries. `SettlementRuntime` materializes the two
homestead landmarks from a read-only definition. `AdventureController` owns the
authored tree and rock placement and all interaction registration.

The previous Windfall village resources and voxel assets remain in the
repository. The live scene simply stops referencing their terrain, settlement,
scatter, and legacy backdrop renderers.

## Scene composition

```text
Adventure
|-- AmbientWind
|-- SettlementRuntime
|-- WorldCanvas
|   `-- TerrainWorld (homestead region)
|-- Actors
|   |-- Props (homestead landmarks + authored vegetation)
|   |-- WildCreatures (empty baseline hook)
|   `-- Player
`-- Interface
```

## Validation path

`tests/homestead_baseline_smoke_test.tscn` proves the active terrain identity,
homestead landmark count, preserved river bridge and stair connectors, blocked
water/cliffs, player spawn, and absence of the old village buildings and wild
creatures. Visual QA compares a portrait overview capture with the supplied
reference while desktop gameplay is captured separately.

# Settlement Feature

Settlements are authored read-only layout data layered over compiled terrain.
`SettlementDefinition` owns a stable ID, a density tier, world bounds, and prop
placements. `SettlementRuntime` indexes those immutable placements by terrain
chunk and materializes only the buildings owned by active chunks.

The tier is a content and streaming contract rather than a promise to generate
buildings blindly:

- `OUTPOST` — one landmark and a few utility props.
- `VILLAGE` — several residences, one civic/commercial landmark, and a route
  connection. Windfall is the first implementation.
- `TOWN` — multiple named neighborhoods sharing a road graph and streamed
  chunks. Mossglass is the first implementation: twelve chunks, thirty-eight
  authored buildings, a civic highland, market square, residences, service
  land, and wild boundaries.
- `CITY` — several town-sized district groups with gates, plazas, services, and
  stricter visibility/performance budgets. `CityDistrictRuntime` loads district
  scenes through `ResourceLoader` and replaces the live group atomically.

Terrain remains authoritative for elevation, surfaces, traversal, and biome.
Settlement props own only their identity, interaction copy, placement, visual,
and footprint collision. A settlement definition is never modified during
play; runtime state belongs to the owning gameplay system. Building and biome
scatter activation subscribe locally to `TerrainWorld` chunk signals. A city
definition contains only a connected graph of immutable district references;
it never constructs one enormous always-live city scene.

```text
CityDefinition
`-- CityDistrictDefinition[]
    `-- one threaded CityDistrictGroup scene active at a time
        |-- TerrainWorld: focus chunk + staged neighbor ring
        |-- SettlementRuntime: buildings in active chunks
        `-- TerrainScatterRuntime: deterministic biome props in active chunks
```

## Validation

`tests/gameplay_smoke_test.tscn` verifies Windfall's tier and required building
mix, then confirms those definitions materialize in the live adventure.
`tests/town_streaming_smoke_test.tscn` verifies Mossglass topology, density,
determinism, staged activation budget, building/scatter ownership, and unload.
`tests/city_district_streaming_smoke_test.tscn` cycles three connected districts
and proves the scene tree never retains more than one group. Pixel changes are
captured through `mossglass_town_preview.tscn` at desktop and narrow ratios.

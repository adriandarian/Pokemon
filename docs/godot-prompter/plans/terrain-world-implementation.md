# Terrain world implementation plan

Status: core scaling concept implemented and validated; world-travel content can
now extend it district by district.

Approval record: the persistent authored overworld with compiled
procedural-hybrid terrain is approved. The minimal isolated implementation is
documented in `terrain-two-chunk-foundation.md`; the live project intentionally
extends that foundation to larger four- and twelve-chunk regions.

This plan turns the approved terrain concepts into the shipped exploration
world without replacing Creature Trail's locked 2D controller or flat battle
presentation. The full concept remains the destination; each stage leaves a
complete, testable game rather than an art-only branch.

## Stage 1 — compiled terrain foundation and live vertical slice

Player outcome: Windfall's live exploration map has real low, middle, and high
ground. The player can climb a wide stair and a broad ramp, cannot cross an
unstamped cliff, and sees the existing characters, creatures, props, camera, and
river grounded on the new terrain.

1. Add focused terrain Resource types for region definitions, biomes, stamps,
   and immutable compiled chunks.
2. Add a deterministic editor/headless compiler using `FastNoiseLite` only for
   broad proposal fields. Apply ordered authored stamps after the proposal.
3. Compile a four-chunk (`2 x 2`) Windfall district with three elevation bands,
   meadow/wetland/wild/highland biome zones, protected parcels, water, roads,
   stairs, ramp, bridge, and required-route validation.
4. Add a read-only `TerrainQuery` and reusable terrain sample contract.
5. Add chunk top, cliff-face, and collision renderers sourced from the same
   compiled arrays. Cliff edges and water boundaries create physics barriers;
   stairs and ramps remain traversable.
6. Add explicitly configured terrain followers for player, NPC, prop, and wild
   visuals. Camera framing follows the player's projected foot position while
   physics and interactions remain in canonical ground coordinates.
7. Integrate the reusable terrain scene into `adventure.tscn`, expand the world
   and camera limits to the full district, preserve battle/HUD behavior, and add a
   terrain preview spawn.
8. Add a dedicated terrain smoke test, extend gameplay assertions, start the
   whole project headlessly, and capture desktop plus narrow views.

Stage 1 is implemented in the live Windfall adventure. Save migration and quests
remain separate feature work.

## Stage 2 — authored Windfall village

Player outcome: the current lodge stop becomes a readable village spread over
roughly `2 x 2` neighborhood chunks.

1. Produce an original modular building/streetscape kit at the locked human
   scale. The first delivered set contains the lodge, compact cottage, and
   market stall; shop fronts, civic landmarks, walls, gardens, and parcel props
   remain expansion work.
2. Convert the lodge, commons, water source, preserve gate, road hierarchy, and
   encounter spaces into protected authored stamps and stable prop anchors.
3. **Implemented:** read-only settlement definitions and chunk-local building
   activation ownership.
4. Replace remaining flat `AdventureWorldCanvas` land decoration with
   terrain-aware layers.
5. Add route, entrance, collision, interaction, and screenshot validation for
   every village chunk.

## Stage 3 — streaming and regional biomes

Player outcome: travel continues beyond Windfall without one enormous always-
loaded scene.

1. **Implemented:** activate the current chunk plus a configurable neighbor
   ring, with terrain, collision, and roads sharing one active set.
2. **Implemented at district scale:** town-sized district scenes load through
   Godot's threaded `ResourceLoader`; terrain nodes instantiate on the main
   thread in staged batches.
3. **Implemented for static content:** chunk-scoped settlement and scatter
   lifecycle without mutating base Resources. Persistent gameplay save deltas
   remain future work.
4. **Implemented:** biome scatter definitions, deterministic candidates,
   authored exclusion masks, and topology-aware placement.
5. **Implemented baseline:** missing-chunk barriers and a captured 100 ms
   per-frame activation budget. Hysteresis and content-addressed seam hashes are
   later hardening for regions larger than the current reference town.

## Stage 4 — town and city districts

Player outcome: settlements grow through extent, street hierarchy, and named
districts while humans, doors, roads, and houses keep the same scale.

1. **Implemented:** Mossglass Town uses `4 x 3` chunks with market, civic,
   residential, service, lowland, and wild-edge responsibilities.
2. **Implemented composition contract:** Mossglass City contains three connected
   town-sized district references.
3. **Implemented:** only the selected district group is resident, and its terrain
   keeps only the focus neighbor ring materialized.
4. **Implemented baseline:** districts validate independently and the city graph
   rejects missing, duplicate, or disconnected references. Unique art and route
   content for additional city districts remains normal content production.

## Completion evidence for the full concept

- The live game, not only a preview, uses compiled elevation/biome terrain.
- Collision, rendering, navigation/traversal queries, and actor projection agree
  on one chunk data source.
- Windfall is a multi-chunk village with more than one building type.
- At least one town-scale district group streams without visible seams.
- A city composition proves district loading rather than one always-live scene.
- All deterministic, headless, startup, desktop, narrow, and performance gates
  in the technical design pass with recorded evidence.

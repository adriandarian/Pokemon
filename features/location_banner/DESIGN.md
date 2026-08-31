# Location banner design

## Player-visible outcome

Entering Windfall Village or Mossglass Wilds briefly reveals the existing
Mossglass Frontier location card. The card fades in, remains readable for a few
seconds, then fades away so exploration is unobstructed. Crossing the area
boundary replays the sequence with the new location and objective.

## Ownership and data flow

```text
AdventureController (current area)
        |
        `-- AdventureHUD.set_location(...)
                    |
                    `-- LocationBanner (copy and presentation timing)
```

- `AdventureController` remains the authoritative owner of the player's current
  area and decides when the displayed location changes.
- `LocationBanner` owns only its labels, visibility, and one active presentation
  tween. Replaying the banner replaces the previous tween instead of stacking
  animations.
- The feature does not add gameplay state or mutate any `content/*.tres`
  definition.

## Scene tree and public contract

```text
LocationCard (PanelContainer / LocationBanner)
`-- LocationVBox
    |-- Region
    |-- Location
    `-- Objective
```

`present(region, location, objective)` updates all copy and starts the
fade-in/hold/fade-out sequence. `is_presenting()` exposes the player-visible
state for behavior validation. The `dismissed` signal reports completion.

The scene is instanced by `AdventureHUD` inside its existing top-left container.
Its width caps at the reference card width and contracts with the HUD at narrow
resolutions; the objective wraps rather than overflowing.

## Reduced motion and failure modes

- Reduced-motion mode keeps the readable hold but removes both fades.
- A new area presentation kills the current tween before starting another, so
  an old callback cannot hide newer location copy.
- Empty copy is allowed and displayed literally; choosing valid authored copy
  remains the controller's responsibility.
- Freeing the banner also frees its bound tween.

## Isolated validation

1. Instantiate `location_banner.tscn` through the dedicated headless smoke test.
2. Verify copy is updated immediately, the banner becomes visible, and it hides
   after the configured hold.
3. Replay it before the first sequence finishes and verify only the newest copy
   remains authoritative.
4. Verify reduced motion skips fading while preserving timed dismissal.
5. Start the complete project headlessly, then capture and inspect the live
   banner at 1280 x 720 and a narrow 640 x 360 viewport.

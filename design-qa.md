# 3D homestead baseline design QA

## Evidence

- Approved source: `C:\Users\hello\AppData\Local\Temp\codex-clipboard-85d050ef-87c5-4a59-b574-8f6dd0a4b9f8.png`
- Rejected live state: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\01-current-live.png`
- Final portrait live capture: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\30-final-portrait-live.png`
- Final source/live comparison: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\32-final-source-vs-live.png`
- Final desktop gameplay: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\29-desktop-live-fixed.png`
- Final narrow gameplay: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\31-final-narrow-live.png`
- Capture state: fresh game at Highfield Terrace; overview hides interface, gameplay captures retain the live HUD.

## Contract

The active exploration world uses real 3D terrain, colliders, hazards, and
`CharacterBody3D` movement while an orthographic camera preserves faux-2.5D
readability. Its authored landmark sequence matches the approved concept:
northern trail, raised wheat terrace, fenced cottage compound, player route,
deep retaining edge with a fitted stair, lower riverbank, timber bridge, and a
continuing southern trail.

The previous 2D Adventure world and its assets remain in the repository but do
not render in the active main scene. The concept legend is intentionally absent
from live gameplay. Battles remain a flat 2D presentation above the 3D world.

## Visual audit

1. **Approved source — healthy visual target.** The source establishes the
   olive/gold/teal palette, portrait composition, deep stepped elevation,
   irregular banks, dense vegetation, and landmark hierarchy.
2. **Rejected live state — failed.** The prior capture was a flat sparse field
   with unrelated primitive proportions, straight clipped route pieces, shallow
   elevation, neon foliage, and no source/live comparison evidence.
3. **Final portrait — playable baseline passed.** The live game now reproduces
   the source's landmark order, scale hierarchy, deep elevation, diagonal bridge,
   continuous route, source-matched hero compound, wheat, foliage, and muted
   atmosphere.
4. **Desktop gameplay — passed.** The 1280 x 720 frame has no exposed world
   background, preserves the live location HUD, and keeps the stair/bridge route
   readable around the player.
5. **Narrow gameplay — passed for traversal.** The 720 x 1280 frame follows the
   player through the real 3D route and keeps the HUD legible. The tighter crop is
   expected from the gameplay camera and does not replace the portrait overview.

## Functional validation

- Ten focused smoke-test scenes pass, including 3D route seams, elevation,
  bridge collision, water hazards, runtime navigation baking, click-to-move, and
  interaction auto-approach.
- Headless project startup completes without parser or resource errors.
- `git diff --check` reports no whitespace errors.

## Honest evidence limit

The corrected live scene is a source-faithful **3D gameplay baseline**, not a
pixel-identical reproduction of the pre-rendered concept. The largest remaining
P2 production-art gap is the source's denser hand-authored micro-geometry and
organic shoreline silhouette. Closing that final gap requires a reusable set of
authored 3D voxel cliff, shoreline, trail-edge, and foliage modules rather than
claiming that the current modular terrain is already identical.

Final result: passed for the playable 3D baseline; exact source-image parity remains a production-art follow-up.

# 3D homestead baseline design QA

## Evidence

- Approved target crop: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\72-target-left-crop.png`
- Rejected live state: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\01-current-live.png`
- Current aspect-matched portrait: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\253-soft-grade-overview.png`
- Current target/live comparison: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\254-target-vs-live-soft-density.png`
- Stair-route and garden diagnostic: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\245-paver-stair-close.png`
- Current desktop gameplay: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\255-current-desktop-gameplay.png`
- Current narrow gameplay and route join: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\256-current-narrow-traversal.png`
- Rotated 3D proof: `C:\Users\hello\Projects\Pokemon\output\homestead_visual_audit\257-current-orbit-proof.png`
- Capture state: fresh game at Trailkeeper Homestead; overview hides interface, gameplay captures retain the live HUD.

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
3. **Current portrait — playable baseline passed.** The aspect-matched live game
   reproduces the source's landmark order, scale hierarchy, deep elevation,
   upper-left route entry, cottage-to-fence proportion, exposed fitted stair,
   diagonal bridge crossing, lower-right route continuation, hero compound,
   wheat, foliage, and muted atmosphere. The path uses a corrected ImageGen
   paving material and physical grass-edge intrusions rather than clipped route
   cards. The lower approach now owns a collision-backed terrain apron instead
   of relying on floating surface overlays to hide a world-floor gap. New
   ImageGen grass, cliff, foliage, compact moss-cap, calm river, and stair-paver
   albedos remove the rejected yellow/neon cast, white water streaks, flat stair
   stripes, and tiny-brick wallpaper while preserving volumetric meshes. The
   widened physical river and bridge now create the reference's broad water
   break; the garden uses real open posts and thin rails instead of solid wood
   slabs, and the expanded blocked wheat field matches the target occupancy.
4. **Desktop gameplay — passed.** The 1280 x 720 frame has no exposed world
   background, preserves the live location HUD, and keeps the stair/bridge route
   readable around the player.
5. **Narrow gameplay — passed for traversal.** The 640 x 1000 frame follows the
   player through the real 3D route, keeps the HUD legible, and confirms that the
   trail fork and stair landing remain continuous without dropped or depth-fought
   ribbon triangles. The tighter crop is expected from the gameplay camera.
6. **Rotated orbit — passed for volumetric integrity.** The cottage, shed,
   trees, crops, cliffs, shrubs, riverbank, stairs, and bridge keep visible
   sides, backs, depth, and shadows when the camera leaves its authored angle.
   The world/terrain roots contain zero `Sprite3D` prop cards. The landmark
   boulder, stone waymarker, stair caps, cottage, shed, garden, and bridge all
   remain volumetric from the alternate view.

## Functional validation

- Ten focused smoke-test scenes pass, including 3D route seams, elevation,
  bridge collision, water hazards, runtime navigation baking, click-to-move, and
  interaction auto-approach.
- Current 3D density metric: `world_sprites=0`, `mesh_instances=5687`,
  `multimesh_instances=22`, `static_bodies=128`, `collision_shapes=130`.
- Headless project startup completes without parser or resource errors.
- `git diff --check` reports no whitespace errors.

## Honest evidence limit

The corrected live scene is a source-faithful **3D gameplay baseline**, not a
pixel-identical reproduction of the pre-rendered concept. The previous
billboard layer is gone; native meshes now cover the cottage, roof, shed,
garden, trees, wheat, shrubs, rocks, reeds, cliffs, shore, stairs, and bridge.
The v9 grass, v7 trail, v7 cliff, v6 foliage, v1 compact moss-cap, v9 water,
and v1 stair-paver ImageGen suite plus 0.74 bilinear 3D resolution scaling
materially close the source's painterly finish. Landmark anchors,
collision-backed continuous route, elevation bands, widened river and physical
bridge, six-step stair cut, open garden rails, expanded wheat field, dense
ground cover, and compound scale now align in the current target/live
comparison. Remaining difference is concentrated in hand-authored cliff depth,
shoreline contour variance, and pixel-level variance between an interactive 3D
render and a pre-rendered concept.

Current result: passed for the playable volumetric 3D baseline; exact
source-image parity remains active work.

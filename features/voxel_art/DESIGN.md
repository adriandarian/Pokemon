# Voxel art direction

## Player-visible outcome

Creature Trail presents one cohesive voxel diorama: the explorer, all three
creatures, every authored prop, terrain, the battle stage, content icons, HUD,
Field Guide, and foundation preview share the same cubic construction, lighting,
palette, and squared interface language.

The game remains a 2D Godot project. Exploration keeps its locked faux-2.5D
camera, collision, Y sorting, and visible wild creatures; battle keeps its
intentionally flat 2D composition.

## Art bible

- Camera: orthographic three-quarter view, about 25 degrees above the horizon.
- Form: chunky cubic voxels with a readable silhouette and restrained detail.
- Light: warm key from upper left, cool teal bounce from lower right, soft ambient
  occlusion between blocks.
- Palette: moss and sage greens, river teal, warm ochre, ember coral, cream, and
  charcoal. Content accents retain their existing element colors.
- Edges: crisp and hard, without ink outlines, antialiased pixel-art fuzz, or
  photorealistic materials.
- Terrain: generated grass is a single continuous material beneath broad,
  antialiased land contours. Trails and preserve boundaries are authored curves
  rather than a visible square grid, with small cubic facets restoring the voxel
  language at their edges.
- Water: generated river voxels are mapped onto an irregular authored shoreline.
  A shared `canvas_item` shader scrolls two quantized flow samples and a shimmer
  band through time; reduced-motion mode freezes the shader at a stable frame.
- Grounding: sprites contain no ground plane or cast shadow. The built-in image
  generator returned RGB images even after a transparent-alpha extraction pass,
  so final sources use a controlled magenta chroma backdrop. A shared shader
  removes it at render time, and runtime code supplies a consistent block-shaped
  contact shadow.
- Originality: no Pokemon species, symbols, logos, locations, or proprietary
  character designs.

## Asset ownership and data flow

```text
assets/voxel/*.png (immutable generated source)
            |
            v
VoxelAssetLibrary (stable semantic lookup)
      |             |               |
      v             v               v
CreatureVisual  AdventureProp   GameMenu icons
```

`VoxelAssetLibrary` is the single mapping from semantic game IDs to textures.
It owns no mutable state. Existing content resources remain read-only during
play, and gameplay systems continue to own all movement, collision, encounters,
inventory, and progression state.

Generated surface materials remain immutable inputs while their geometry stays
code-owned so it can adapt to the authored world and viewport. `AdventureWorldCanvas`
owns the continuous ground and trail, `VoxelWaterSurface` owns only visual water
motion, and `RiverOverlay` owns the bank and bridge. None of them owns collision
or gameplay state. `BattleBackdrop`, the wild interaction beacon, and both themes
share the same surface language.

## Asset manifest and target display budgets

| Group | Assets | Maximum runtime display |
|---|---|---|
| Explorer | front, back | 116 x 142 each |
| Creatures | Kindlehorn, Rillip, Brambit | 138 x 138 each before encounter scaling |
| Props | tree, lodge, sign, Ranger Sela, rock, lantern | role-specific, at most 448 x 368 |
| Items | Trail Prism, Moss Tonic | 70 x 70 each |
| Badges | Ember Crest, Deep Delver Mark | 56 x 56 each |
| Elements | Ember, Tide, Grove, Storm | 28 x 28 each |
| Terrain | Grass surface, river surface | 1024 px import cap; world-scaled |

Generated source stays lossless and is displayed inside the listed runtime
budget. A shared chroma-key material removes the controlled background without
destructively rewriting the generated subject pixels.

## Public contracts

- `VoxelAssetLibrary.get_species_texture(species_id)` returns a creature texture.
- `VoxelAssetLibrary.get_prop_texture(kind)` returns a prop texture.
- `VoxelAssetLibrary.get_item_texture(item_id)`, `get_badge_texture(badge_id)`,
  and `get_element_texture(element_id)` provide UI icons.
- Existing `CreatureVisual`, `AdventureProp`, and `PlayerVisual` classes keep
  their public methods and exported properties.

## Failure modes

- Missing texture: return a visible generated fallback and emit a single error,
  rather than changing gameplay state.
- Excess source padding: every consumer draws into an explicit bottom-centered
  display rectangle using a normalized visible-content crop, so source canvas
  dimensions and hidden chroma padding never change collision or grounding.
- Chroma fringe: the shared shader uses a narrow smooth distance threshold around
  the sampled magenta key color; subject palettes deliberately exclude magenta.
- Import quality and memory: textures use lossless import, no mipmaps, a 512 px
  import-size cap, and linear filtering for clean high-resolution downscaling.
- Broken grounding: every world sprite is bottom-centered on its existing node
  origin, with its contact shadow drawn at that origin, so collision positions do
  not move and the visible subject cannot float above its footprint.
- Water animation drift: shader motion uses `TIME` only for presentation and
  exposes `motion_amount`; `SettingsService.reduced_motion` sets it to zero.
- Narrow UI overflow: generated icons have fixed compact minimum sizes and text
  keeps expansion priority.

## Isolated validation

1. Run both headless smoke-test scenes.
2. Start the full project headlessly and fail on parser or resource errors.
3. Capture deterministic exploration, `--preview-battle`, and `--preview-wild`
   frames at 1280 x 720.
4. Capture the settled river twice with different `--capture-delay-frames`
   values and verify that a water-only crop changes while a static ground crop
   does not.
5. Inspect all captures for grid artifacts, surface continuity, transparency
   halos, scale, grounding, occlusion, clipping, UI overflow, and consistency
   with this art bible.

# Creature Trail voxel assets

These project-bound raster assets were generated with the built-in OpenAI image
generation tool for the voxel redesign. No external provider, paid game-asset
service, or proprietary source art was used.

## Shared generation specification

The first generation pass asked for genuine transparent alpha. The built-in
generator returned RGB checkerboards, and a targeted background-extraction pass
also returned RGB checkerboards. The final pass therefore used the following
exact chroma-key specification in addition to each individual request. The game
removes that controlled background with one shared shader.

```text
Use case: stylized-concept
Asset type: production-ready 2D game sprite rendered from voxel art
Style/medium: polished orthographic 3D voxel miniature made from chunky cubic voxels; crisp hard edges; strong readable silhouette; restrained detail; no ink outlines; no pixel-art fuzz; consistent block scale
Composition/framing: one isolated subject, centered, fully visible, generous even padding, orthographic three-quarter view about 25 degrees above the horizon
Lighting/mood: warm soft key light from upper left, cool teal bounce from lower right, subtle ambient occlusion between blocks
Color palette: moss and sage greens, river teal, warm ochre, ember coral, cream, and charcoal, with the asset-specific colors below
Background: one perfectly flat, uniform vivid chroma-magenta background, RGB 255, 0, 255 (#FF00FF), edge to edge; no gradient; no texture; no vignette
Constraints: original design only; preserve the described silhouette; no magenta anywhere on the subject; no floor; no ground plane; no cast shadow; no text; no letters; no logos; no trademarks; no watermark; no frame; no extra objects
Avoid: Pokemon designs; Minecraft branding or recognizable block textures; photorealism; smooth clay surfaces; gradients painted over the silhouette; cropped subject
```

## Individual prompts

| File | Primary request and subject |
|---|---|
| `player_front.png` | Original young trail explorer viewed from front three-quarter: short dark hair, warm tan skin, ember-coral field jacket with one ochre chest band, deep green square backpack barely visible, charcoal trousers, sturdy brown boots, long golden scarf tail; friendly determined expression; compact heroic proportions. |
| `player_back.png` | Same original young trail explorer viewed from back three-quarter: short dark hair, ember-coral field jacket, prominent deep green square backpack, charcoal trousers, sturdy brown boots, long golden scarf tail; exactly the same outfit, palette, proportions, and block scale as the front sprite. |
| `kindlehorn.png` | Original compact ember creature named Kindlehorn: rust-orange rounded voxel body, two large triangular ears, cream muzzle and belly, tiny charcoal eyes, short sturdy legs, one faceted golden crystal horn with a gentle ember glow; cute but resolute, no resemblance to an existing franchise creature. |
| `rillip.png` | Original cheerful tide creature named Rillip: round river-blue voxel body, two small fin-like side pods with darker teal tips, pale aqua smiling mouth, rosy coral cheek blocks, tiny flipper feet; buoyant and friendly, no resemblance to an existing franchise creature. |
| `brambit.png` | Original shy grove creature named Brambit: compact warm-brown voxel body, lighter tan face and belly, tiny charcoal eyes and nose, three asymmetrical leafy voxel shoots forming a green crown, short stump-like legs; earthy and curious, no resemblance to an existing franchise creature. |
| `tree.png` | Mossglass frontier tree: thick warm-brown block trunk with subtle bark color steps, broad asymmetrical canopy built from clustered moss, sage, and fern-green cubes; sturdy authored-world prop with a clean bottom-center trunk contact point. |
| `lodge.png` | Cozy Trailkeeper Lodge: compact cream-plaster voxel cottage, deep terracotta stepped roof, dark timber trim, central warm-brown door with tiny golden latch, two teal glass windows, short stone foundation; front three-quarter view and a clean bottom-center contact edge. |
| `lodge_contact_shadow_v3.png` | House-specific chroma-keyed contact-occlusion decal: shallow green-charcoal footprint with an irregular stepped upper edge fitted to the lodge foundation and stairs. |
| `sign.png` | East Trail wayfinding sign: warm weathered voxel wood post and broad arrow-shaped plank pointing right, darker cut block along the face but no letters or symbols, compact readable silhouette and clean bottom-center contact point. |
| `ranger_sela.png` | Original adult ranger Sela: warm tan skin, short silver-gray voxel hair, deep teal field coat, cream scarf, charcoal trousers, brown trail boots, small ochre utility satchel; calm welcoming stance, front three-quarter view, original character design. |
| `rock.png` | Mossglass boulder: low angular cluster of slate-gray cubic rock forms with a few muted sage moss blocks, asymmetric silhouette, clean flat bottom contact edge. |
| `lantern.png` | Frontier lantern post: narrow dark timber voxel post, compact charcoal metal cap and frame, luminous amber cube lantern with cream-yellow core, simple sturdy base, no separate ground or cast shadow. |
| `trail_prism.png` | Game UI item icon: a faceted translucent golden voxel prism held by a small dark-brass geometric ring, bright cream core, compact diamond silhouette, front three-quarter view. |
| `moss_tonic.png` | Game UI item icon: squat teal-green voxel glass bottle, cork stopper, cream label represented only by an unmarked block, one small sage leaf tied at the neck, readable compact silhouette. |
| `ember_crest.png` | Game UI badge icon: original shield-like crest assembled from ember-coral and golden voxels, central abstract rising flame made only of geometric blocks, dark-brass rim, compact frontal view. |
| `deep_delver_mark.png` | Game UI badge icon: original hexagonal cave mark assembled from deep teal, slate, and pale crystal voxels, central abstract descending tunnel motif made only of geometric blocks, dark-brass rim, compact frontal view. |
| `ember.png` | Game UI element icon: an abstract rising flame assembled from coral, orange, gold, and cream cubic voxels, compact frontal silhouette. |
| `tide.png` | Game UI element icon: an abstract curling water droplet assembled from river-blue, teal, and pale-aqua cubic voxels, compact frontal silhouette. |
| `grove.png` | Game UI element icon: an abstract two-leaf sprout assembled from deep green, moss, sage, and pale-lime cubic voxels, compact frontal silhouette. |
| `storm.png` | Game UI element icon: an abstract lightning crystal assembled from ochre, bright yellow, cream, and a few slate cubic voxels, compact frontal silhouette. |

## Terrain material prompts

The built-in image generation tool produced two additional opaque, square
material inputs. Runtime code shapes these materials into world geometry; they
are not pasted scene backgrounds.

### `terrain_grass.png`

```text
Use case: stylized-concept
Asset type: seamless 2D game terrain material texture for a faux-2.5D voxel world
Primary request: create a single square, seamlessly repeating moss-and-sage grass surface texture viewed straight down, built from very small cubic voxel clusters and broad continuous color fields
Scene/backdrop: the texture fills the entire canvas edge to edge; no horizon, no sky, no transparent area
Subject: soft mossy grass with subtle scattered clover-like voxel flecks and occasional tiny warm ochre soil peeks; no large objects
Style/medium: polished orthographic voxel-game material, chunky cubic color facets, crisp but not pixel-art, smooth visual rhythm without a visible square grid
Composition/framing: top-down material swatch; edge-to-edge and genuinely tileable on all four sides; low contrast so characters and props remain readable
Lighting/mood: warm upper-left daylight, soft teal ambient bounce, restrained ambient occlusion
Color palette: moss green, sage green, muted fern green, a very small amount of warm ochre
Materials/textures: grass assembled from small block facets; broad continuous patches rather than checkerboard cells
Constraints: seamless repeat; no grid lines; no border; no frame; no water; no path; no tree; no rock; no flowers larger than a few voxels; no text; no logo; no watermark; original game material
Avoid: Minecraft branding or recognizable Minecraft textures; photorealism; square tile outline; checkerboard; isolated floating cubes; perspective scene; horizon
```

### `terrain_water.png`

```text
Use case: stylized-concept
Asset type: seamless 2D animated-water material input for a faux-2.5D voxel world
Primary request: create a single square, seamlessly repeating river-water surface texture viewed straight down, assembled from small translucent cubic voxel facets and gentle diagonal current bands
Scene/backdrop: water fills the entire canvas edge to edge; no shore, no horizon, no sky, no transparent area
Subject: clear river-teal water with layered deep teal blocks, pale aqua glints, and restrained foam-like cuboid highlights that imply current
Style/medium: polished voxel-game material, crisp cubic facets, smooth directional flow, readable at small scale, not pixel art
Composition/framing: top-down material swatch; edge-to-edge and genuinely tileable on all four sides; current travels diagonally from upper left toward lower right
Lighting/mood: warm daylight reflections from upper left, cool teal depth, soft ambient translucency
Color palette: deep river teal, turquoise, muted cyan, pale aqua, a few cream-blue highlights
Materials/textures: many small connected water voxels and elongated block bands; no isolated cubes; moderate low contrast
Constraints: seamless repeat; no visible square grid; no border; no frame; no bank; no plants; no fish; no rocks; no text; no logo; no watermark; original game material
Avoid: photorealistic water; ocean waves; checkerboard; static horizontal dash pattern; floating cubes; perspective scene; horizon; Minecraft branding or recognizable Minecraft textures
```

### `terrain_grass_top_v3.png`

This later built-in image-generation pass replaces the fine grass mosaic with
large, readable voxel plates that match the construction scale of the lodge.

```text
Create a NEW seamless square terrain-top texture for a voxel-themed Godot exploration game.

Reference roles:
- Image 1 is the current grass palette/content reference. Preserve its mossy sage, fern green, olive, and restrained yellow-green family, but replace its tiny busy pixel mosaic.
- Image 2 is the scale and construction-language reference. Match the lodge's clearly modeled chunky blocks, crisp stepped edges, and softly lit voxel faces. Do not include the lodge or any object.

Deliverable:
A perfectly top-down, orthographic, edge-to-edge grassy ground MATERIAL ONLY, designed to tile seamlessly on all four edges. It must read immediately as chunky voxel terrain at gameplay scale.

Critical scale requirement:
Use large, clearly visible block cells and connected stepped patches, approximately 24-48 source pixels per primary square/rectangular voxel block in a 1024-1254px texture. Avoid micro-pixels, fine checkerboard noise, painterly brushwork, photographic grass, tiny flowers, scattered confetti, or continuous soft mottling. Build the surface from broad interlocking square and rectangular voxel plates, with occasional 1-block height-step facets and sparse darker moss seams. Keep contrast restrained enough for characters and paths to remain readable.

Lighting and composition:
Soft warm light from upper-left, subtle darker lower/right faces on a few block steps, mostly flat walkable surface, no horizon, no perspective, no slope, no cliff wall, no border, no isolated props, no text, no letters, no logo, no watermark, no frame. The result must be a reusable seamless material, not a scene.
```

### `terrain_cliff_face_v2.png`

The cliff material belongs to the rejected elevation prototype retained under
`features/terrain_elevation/`; it is not composited beneath the live lodge.

### `lodge_contact_shadow_v3.png`

The built-in image-generation tool produced this house-specific grounding
decal from `lodge.png` as a footprint reference. Runtime code samples only the
shadow region and converts its darkness into neutral green-charcoal opacity
with a dedicated shadow-mask shader, so no magenta reaches the live scene.

```text
Use case: stylized-concept
Asset type: chroma-keyed game contact-shadow decal for a Godot faux-2.5D voxel building
Input images: Image 1 is a footprint and camera-angle reference only. Do NOT render or include the lodge.

Primary request:
Create exactly one standalone ambient-occlusion contact shadow shaped to fit beneath the referenced lodge's irregular stone foundation and front steps.

Scene/backdrop:
A perfectly flat, uniform, solid chroma-key magenta background using RGB 240, 14, 237 (#F00EED). No checkerboard, no transparency preview, no variation, no gradient, no texture.

Subject:
A shallow, horizontally oriented dark green-charcoal shadow. Its upper/contact edge is irregular and slightly stepped to echo the building's lowest stone blocks and central stairs. The center beneath the stairs and inner foundation is darkest; the opacity/edge softness falls off only a short distance toward the outer edge.

Composition/framing:
Shadow centered horizontally and vertically in the canvas, about 74% of canvas width and no more than 9% of canvas height. Generous pure-magenta space around it. It must remain narrower than the referenced building footprint.

Style/medium:
Soft game-sprite ambient occlusion with a restrained voxel-stepped silhouette, not a hard geometric platform.

Constraints:
Exactly one shadow on the solid magenta chroma background. No house, no platform, no slab, no pedestal, no terrace, no ground plane, no grass, no stone, no cliff, no plants, no objects, no directional cast shadow, no checkerboard, no text, no logo, no watermark, no frame.
```

The final `.png` files are the selected lossless project artifacts. The 19 files
total roughly 25 MB; each was checked for decodable PNG bytes, source dimensions,
and a magenta corner sample before integration.

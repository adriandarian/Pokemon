# Gameplay elevation concept prompt

Built-in image-generation mode was used with three reference images.

- Image 1: live game capture; primary camera, palette, actor scale, and gameplay-readability reference.
- Image 2: macro terrain concept; land-mass, traversal, and water/road relationship reference only.
- Image 3: `assets/voxel/lodge.png`; construction and foundation reference.

```text
Use case: stylized-concept
Asset type: close gameplay-environment concept for the Creature Trail terrain redesign

Primary request:
Generate one believable in-game exploration screen showing how the current flat Creature Trail map should look after adding functional elevation. This is a close gameplay slice, not a world overview. Preserve the live game's clean faux-2.5D readability while showing exactly how a player moves among low ground, a village terrace, and a higher wild ridge.

Input images:
- Image 1 is the primary live-game reference. Match its fixed orthographic gameplay camera, screen-space scale, crisp chunky voxel assets, saturated moss/teal/ochre/coral palette, broad readable paths, tree scale, character scale, and relatively flat 2D composition. Remove its HUD and redesign only the terrain structure.
- Image 2 is a macro terrain-and-settlement concept reference only. Borrow its clear stepped land masses, retaining faces, stairs, ramps, and water/road relationships, but greatly simplify the density, detail, depth, and cinematic atmosphere to match Image 1. Do not copy its city.
- Image 3 is the lodge construction and foundation reference. Include one related village building seated firmly on the middle terrace at the same human-relative scale; keep its cream plaster, dark timber, terracotta roof, teal windows, and chunky foundation language.

Scene/backdrop:
One screen-sized Mossglass village edge. The low foreground contains a short riverbank or wet meadow and the beginning of a wide ochre trail. The middle of the screen is a broad village terrace with one building, an NPC, a small yard, and enough open space to walk around. The upper/back portion is a darker mossy wild ridge with trees and one small original roaming creature.

Terrain and traversal requirements:
- Exactly three clearly readable elevation bands: low ground, middle terrace, upper ridge.
- Broad calm terrain tops made from chunky moss-and-sage plates; no noisy micro-detail.
- Exposed cliff/retaining faces only where elevation is not walkable.
- One short, wide voxel staircase connecting low ground to the middle terrace.
- One broad earthen or stone-edged ramp connecting the middle terrace to the upper ridge, with an obvious gentle grade.
- A cliff edge beside the ramp that visually communicates "blocked here; use the ramp" without signs or text.
- The ochre trail must remain continuous across the stair landing and ramp.
- A small biome shift from wetter teal-green lowland to village grass to darker fern/moss highland.
- Buildings, trees, player, NPC, and creature must have convincing contact shadows and sit on the correct terrain level without floating.
- Include the original-style trail explorer on or near the stair landing so their size proves the stairs and roads are usable.
- Keep streets at least two character widths and leave clear circulation space.

Style/medium:
Polished orthographic voxel-game screenshot concept with 2D/faux-2.5D composition. Crisp stepped block edges, restrained detail, strong silhouettes, warm upper-left light, cool teal bounce, subtle ambient occlusion. Match the live screenshot's practical game readability more closely than the cinematic macro concept.

Composition/framing:
16:9 gameplay frame similar to 1280x720, fixed camera about 25 degrees above the horizon but with no visible horizon or distant landscape. The world fills the frame edge to edge. One coherent playable scene, not a collage, cutaway, diagram, editor view, or split comparison. No UI and no text.

Color/materials:
Moss and sage terrain tops, deeper fern-green wild ridge, teal wetland/water, ochre packed-earth trail, mossy slate and warm brown cliff faces, cream plaster, dark timber, terracotta roof, teal glass. Terrain contrast must stay lower than characters, stairs, paths, and building entrances.

Constraints:
Keep the project visually 2D/faux-2.5D; no free-camera 3D open-world look. No enormous mountains, skyline, castle, cathedral, market district, waterfall spectacle, or dense city. No more than one main building. No thin unsafe stairs, impossible slopes, floating props, disconnected paths, or terrain walls across the intended route. Original designs only. No proprietary or recognizable franchise characters, creatures, architecture, logos, or motifs. No UI, HUD, labels, text, letters, logos, watermark, frame, grid overlay, terrain editor, heightmap, photorealism, painterly haze, smooth clay, Minecraft branding, or isolated floating cubes.
```

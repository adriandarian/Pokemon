# Homestead 3D ImageGen references

Generated with the built-in ImageGen tool on 2026-08-31. These images are
modeling and palette references only. They are deliberately not rendered as
camera-facing cards in the game.

## Cottage turnaround

Saved as `homestead-3d-turnaround.png`.

> Create a production-ready multi-view turnaround reference sheet for the
> medieval voxel homestead cottage in the left half of the supplied approved
> scene. Preserve its exact visual identity: compact cream plaster cottage,
> dark chunky timber frame, deep stepped terracotta roof tiles, pale stone
> chimney, dark wooden front door and steps, small teal-accented side shed,
> fenced vegetable garden, warm lantern, and mossy stone foundation. Show the
> same physical cottage consistently from an approved three-quarter isometric
> hero view, front elevation, right-side elevation, and rear three-quarter
> view. Make every part genuinely volumetric and buildable from stacked
> voxel/cuboid forms. Use a clean neutral background with no environment,
> character, UI, labels, text, or logos.

## Terrain and foliage module kit

Saved as `terrain-3d-module-kit.png`.

> Create a production-ready modular 3D voxel environment kit reference sheet
> derived from the left half of the supplied approved scene. Show separate
> volumetric modules for straight, inside-corner, and outside-corner mossy
> cliffs; broad integrated stairs; an interlocking dirt-trail edge; a shallow
> teal riverbank with stones and reeds; a timber bridge; a mature tree from
> four angles; dense wheat; and low shrub, flower, and rock clusters. Make all
> pieces share one voxel scale, visible thickness, backs, and sides. Match the
> warm muted olive, ochre, mossy stone, terracotta, dark wood, and teal palette.
> Use orthographic presentation on a neutral background with no scene,
> character, UI, labels, text, logos, or sprite cards.

The approved source image was supplied as a visual reference. The comparison's
failed implementation half was explicitly excluded from the target role.

## Seamless grass-top material

Saved in the project as `assets/voxel/terrain_grass_top_v4.png`.

> Use only the approved left-hand concept panel as the visual source. Create
> one square, seamless, tileable base-color/albedo texture for the TOP SURFACE
> of the mossy olive voxel terrain. Preserve the muted medieval-game palette,
> tiny block-scale grass variation, occasional darker moss, and very sparse
> pale flower flecks. Orthographic top-down material sample only: no horizon,
> perspective, lighting direction, shadows, terrain edge, cliff face, path,
> water, props, characters, UI, text, or logos. The left, right, top, and bottom
> edges must tile without a visible seam.

## Seamless cliff-face material

Saved in the project as `assets/voxel/terrain_cliff_face_v4.png`.

> Use only the approved left-hand concept panel as the visual source. Create
> one square, seamless, tileable base-color/albedo texture for the VERTICAL
> FRONT FACE of its mossy stacked-stone voxel cliffs. Match the chunky uneven
> stone blocks, recessed dark joints, olive moss along selected ledges, and
> warm muted brown-gray palette. Straight-on material sample only: no top
> grass plane, ground, stairs, water, props, characters, perspective, cast
> shadow, UI, text, or logos. The four edges must repeat without a visible
> seam.

## Seamless foliage material

Saved in the project as `assets/voxel/terrain_foliage_v4.png`.

> Use only the approved left-hand concept panel as the visual source. Create
> one square, seamless, tileable base-color/albedo texture for chunky voxel
> tree foliage and dense shrubs. Match the layered dark forest green, mossy
> olive, restrained yellow-green highlights, and rare deep teal leaf accents.
> Treat it as a material swatch with no identifiable whole tree, trunk,
> branches, sky, ground, perspective, lighting direction, cast shadow, UI,
> text, or logos. The four edges must tile cleanly.

## Initial seamless river-top material

Saved in the project as `assets/voxel/terrain_water_v4.png`.

> Use only the approved left-hand concept panel as the visual source. Create
> one square, seamless, tileable base-color/albedo texture for the TOP SURFACE
> of its shallow turquoise voxel river. Match the dark teal base, irregular
> submerged square variation, restrained cyan ripples, and occasional small
> pale glints. Orthographic top-down material sample only: no bank, reeds,
> bridge, rocks, horizon, perspective, directional reflections, characters,
> UI, text, or logos. The four edges must tile without a visible seam.

## Cottage plaster material

Saved in the project as `assets/voxel/cottage_plaster_v5.png`.

> Use case: stylized-concept. Asset type: seamless game-ready base-color
> texture for modular 3D medieval cottage plaster. Input image: the supplied
> image is a visual style, palette, and material reference only; derive the
> cottage's cream plaster wall surface from it. Do not recreate the house or
> scene. Primary request: create one square seamless tileable albedo texture
> for aged warm cream medieval plaster between dark timber framing. Use a
> softly mottled parchment-cream base, subtle sandy grain, faint warm tan wear,
> tiny restrained olive moss staining near occasional pores, and minimal
> hairline surface variation. It should add painterly richness at orthographic
> game scale without reading as noisy stone or brick. Style/medium: detailed
> painterly voxel-game material matching the approved target; not
> photorealistic. Composition: straight-on flat material swatch filling the
> entire square. Lighting: evenly lit neutral albedo, no directional highlights
> or cast shadows. Constraints: perfectly seamless on all four edges; uniform
> fine detail; no transparency; no perspective; no embedded timber beams.
> Avoid: bricks, large cracks, whole wall panels, doors, windows, timber, roof,
> house silhouette, grass, characters, UI, text, labels, logos, watermark,
> horizon, vignette, obvious border.

## Cottage roof-tile material

Saved in the project as `assets/voxel/cottage_roof_tile_v5.png`.

> Use case: stylized-concept. Asset type: seamless game-ready base-color
> texture for modular 3D cottage roof tiles. Input image: the supplied image is
> a visual style, palette, and material reference only; derive the cottage's
> chunky terracotta roof surface from it. Do not recreate the scene or cottage.
> Primary request: create one square seamless tileable albedo texture showing
> tightly packed small medieval terracotta roof tiles in the approved target's
> painterly voxel style. Use irregular warm brick-red, burnt orange, muted
> coral, and deep brown-red tiles with subtle worn edges, slight moss/dirt
> variation, and clearly readable tile boundaries. Keep the texture suitable
> for triplanar or UV application across many small cuboid roof modules in an
> orthographic faux-2.5D game. Style/medium: detailed painterly voxel material,
> matching the approved target; not photorealistic. Composition: straight
> orthographic material swatch filling the square; a dense repeating field of
> roof tiles, no roof silhouette. Lighting: evenly lit neutral albedo, no
> directional highlights, no cast shadows. Constraints: perfectly seamless on
> all four edges; uniform tile scale; no large focal tile; no transparency; no
> perspective. Avoid: whole roof, ridge silhouette, chimney, house walls,
> timber, sky, grass, characters, UI, text, labels, logos, watermark, horizon,
> vignette, obvious border.

## Trail surface material

The first selected pass is retained as
`assets/voxel/terrain_trail_top_v5.png`. The in-game material is the corrected
`assets/voxel/terrain_trail_top_v6.png`.

Initial prompt:

> Use case: stylized-concept. Asset type: seamless game-ready base-color
> texture for a Godot 3D terrain path. Input image: the supplied image is a
> visual style and palette reference only; derive the path surface from the
> pale winding medieval trail visible in it. Do not recreate the scene.
> Primary request: create one square seamless tileable albedo texture for the
> TOP SURFACE of the reference's warm pale ochre dirt-and-worn-stone trail. The
> surface should read as compacted earth mixed with many small irregular flat
> voxel/cobble shapes, softened edges, subtle mossy olive intrusion, muted
> value variation, and occasional tiny darker joints. It must stay readable
> when repeated along a narrow curved trail in an orthographic faux-2.5D game.
> Style/medium: detailed painterly voxel material, matching the approved
> target's warm medieval game art; not photorealistic. Composition: straight
> orthographic top-down material swatch filling the entire square. Lighting:
> evenly lit neutral albedo with no directional highlights or cast shadows.
> Color palette: warm sand, ochre, parchment beige, muted tan, restrained mossy
> olive. Constraints: perfectly seamless on all four edges; no large central
> landmark; uniform texel density; no transparency; no perspective. Avoid:
> terrain edge, grass field, cliff face, bridge, stairs, house, props,
> characters, UI, text, labels, logos, watermark, horizon, vignette, obvious
> repeated border.

Final edit prompt:

> Edit this seamless trail material while preserving its exact square,
> top-down, tileable material-swatch use. Correct the palette and scale to match
> a warm medieval painterly voxel game path: substantially reduce the saturated
> golden yellow, shifting it to muted parchment beige, sandy tan, weathered
> ochre, and restrained mossy olive-gray joints. Make the individual irregular
> flat paving stones and compacted-earth gaps about 1.7 times larger and more
> readable at distant orthographic game scale, with clearer but soft-edged
> boundaries and moderate value variation. Keep it evenly lit neutral albedo
> with no directional light or cast shadows. Preserve seamless tiling on all
> four edges, uniform texel density, no transparency, no border, no perspective,
> and no scene objects, grass field, bridge, stairs, house, characters, UI,
> text, logo, or watermark.

## Corrected river-top material

The final selected water is saved as `assets/voxel/terrain_water_v6.png`. The
intermediate muted pass is retained as `assets/voxel/terrain_water_v5.png`.

Style-reference edit prompt:

> Edit the FIRST supplied image, which is the existing square seamless water
> albedo tile. Use the SECOND supplied image only as the approved visual-style
> and palette reference for the river. Preserve a square, top-down, fully
> tileable game material. Shift the water away from saturated cyan to the
> reference's muted deep blue-green, weathered teal, subdued turquoise, and
> occasional moss-reflected olive tones. Reduce contrast and pixel-noise
> frequency, replacing the tiny busy speckles with broader painterly voxel
> ripples and a restrained number of short pale aqua glints. Keep enough
> low-frequency depth variation to read as moving shallow water in a distant
> orthographic faux-2.5D scene. Even neutral albedo lighting only, with no cast
> shadows or directional highlights. Perfectly seamless on all four edges,
> uniform texel density, no transparency, no shoreline, land, plants, bridge,
> rocks, characters, UI, text, logo, border, perspective, or watermark.

Final edit prompt:

> Edit this square seamless top-down water albedo tile. Preserve the exact broad
> painterly voxel ripple pattern, sparse short glints, material-only
> composition, and seamless edges. Brighten the overall midtones by about 25
> percent and shift the current dark olive-green cast toward the approved river
> palette: muted but clearly blue-green teal, subdued turquoise, and cool
> moss-reflected green. Keep shadows deep enough for water depth, but do not let
> the result become black, muddy olive, saturated cyan, or neon. Slightly
> brighten the small glints to pale aqua. Even neutral albedo lighting; no
> directional highlights or cast shadows. Keep perfect tiling on all edges, no
> transparency, shoreline, land, bridge, rocks, plants, characters, UI, text,
> logo, border, perspective, or watermark.

## Enlarged cliff-face material

The selected cliff-face correction is saved as
`assets/voxel/terrain_cliff_face_v5.png`.

> Use case: stylized-concept. Edit the FIRST supplied image, the current
> seamless vertical cliff-face albedo tile. Use the SECOND supplied image only
> as the approved visual-style, scale, and palette reference. Preserve a
> square straight-on tileable material swatch, but rebuild the face so its
> stacked blocks read about 1.8 times larger at distant orthographic game
> scale. Use irregular chunky weathered stone courses with softened voxel
> edges, warm muted gray-brown and olive-brown faces, deep recessed
> charcoal-olive joints, varied block widths/heights, and restrained moss caps
> on selected ledges. Remove the current bright yellow cast and obvious
> tiny-brick repetition. The result should match the reference's substantial
> terraced cliff blocks and painterly occlusion without becoming
> photorealistic. Even neutral albedo lighting only; no directional highlights
> or cast shadows. Perfectly seamless on all four edges, uniform texel density,
> no transparency, no grass top plane, stairs, ground, water, props,
> characters, UI, text, logo, border, perspective, horizon, or watermark.

## Dark woodland foliage material

The selected foliage correction is saved as
`assets/voxel/terrain_foliage_v5.png`.

> Use case: stylized-concept game material. Edit the FIRST supplied image, the
> current square seamless foliage albedo tile. Use the SECOND supplied image
> only as the approved visual-style, palette, and distant orthographic
> readability reference. Preserve a square straight-on tileable foliage
> material swatch, but remove the current neon yellow-green cast and noisy
> one-pixel repetition. Rebuild it as broad layered clusters of deep forest
> green, mossy olive, and muted sage with restrained warm yellow-green
> highlights and only rare deep teal accents. Make leaf masses read as chunky
> softened voxel-painterly forms with clear dark shadow pockets, varied cluster
> sizes, and calmer larger shapes suitable for true 3D tree crowns and shrubs
> viewed from a faux-2.5D orthographic camera. Match the reference's dark lush
> woodland palette and ambient occlusion while remaining stylized, not
> photorealistic. Even neutral albedo lighting only; no directional highlights
> or cast shadows. Perfectly seamless on all four edges, uniform texel density,
> no transparency, no tree silhouette, trunk, ground, rocks, flowers, props,
> characters, UI, text, logo, border, perspective, horizon, or watermark.

## Muted meadow grass material

The selected grass correction is saved as
`assets/voxel/terrain_grass_top_v5.png`.

> Use case: stylized-concept game material. Edit the FIRST supplied image, the
> current square seamless grass-top albedo tile. Use the SECOND supplied image
> only as the approved visual-style, palette, and distant orthographic
> readability reference. Preserve a square straight-on perfectly tileable
> terrain-top material swatch, but remove the current bright yellow and
> chartreuse cast. Rebuild the surface in muted woodland meadow greens: medium
> moss green, deep olive forest green, subdued sage, and small restrained warm
> sunlit accents. Use broad softly pixelated painterly voxel patches with
> varied patch sizes, gentle value grouping, subtle worn-earth undertones, and
> occasional tiny dark blades, so the terrain reads lush and dimensional from
> a faux-2.5D orthographic camera without becoming a noisy checkerboard. Match
> the reference's richer darker green ground and ambient-occluded mood. Even
> neutral albedo lighting only; no directional highlights or cast shadows.
> Perfectly seamless on all four edges, uniform texel density, no transparency,
> no cliffs, walls, paths, water, flowers, rocks, props, characters, UI, text,
> logo, border, perspective, horizon, or watermark.

## Non-directional meadow grass correction

The selected repeat correction is saved as
`assets/voxel/terrain_grass_top_v6.png`. It replaces v5 in the live material;
v5 remains retained as the previous selected source.

> Use case: stylized-concept game material. Edit the FIRST supplied image, the
> current seamless grass-top albedo. Use the SECOND supplied image only as the
> approved style, scale, palette, and distant orthographic readability
> reference. Preserve a square straight-on perfectly seamless terrain-top
> material swatch. Make one targeted correction: remove all directional waves,
> diagonal banding, horizontal streaks, periodic rows, large cloudy rings, and
> recognizable repeated motifs that become obvious across the running 3D
> meadow. Replace them with calm non-directional low-frequency patches of
> irregular square and softly stepped voxel grass cells, varied in size and
> spacing, with no visual flow direction. Match the reference ground: rich
> medium moss green and olive forest green, muted sage, subtle worn-earth
> undertones, restrained warm highlights, small dark tuft pockets, and
> painterly ambient depth. Keep local contrast moderate and the overall midtone
> slightly brighter than the current source so runtime tint does not crush it.
> It must remain readable under nearest-filtered triplanar mapping from a
> distant faux-2.5D orthographic camera. Even neutral base-color lighting only;
> no directional highlights, cast shadows, baked sun direction, perspective,
> horizon, transparency, cliffs, paths, water, rocks, flowers, props,
> characters, UI, text, logo, border, or watermark. Perfect seamless
> continuity on all four edges and no obvious 2x2 or 3x3 repetition.

## Horizontal-course cliff correction

The selected masonry correction is saved as
`assets/voxel/terrain_cliff_face_v6.png`. It replaces v5 in the live material;
v5 remains retained as the previous selected source.

> Use case: stylized-concept game material. Edit the FIRST supplied image, the
> current seamless vertical cliff-face albedo. Use the SECOND supplied image
> only as the approved visual-style, masonry scale, palette, and orthographic
> readability reference. Preserve a square straight-on perfectly seamless
> vertical material swatch. Make one structural correction: replace the
> current tall vertical rock pillars and columnar formations with broad
> staggered horizontal courses of chunky weathered cuboid stone blocks like
> the reference terraces. Most blocks should be roughly 1.3 to 1.8 times wider
> than they are tall, with irregular widths and heights, softened
> voxel-painterly corners, offset joints between rows, and only occasional
> squarer blocks. Use substantial readable blocks, not tiny brick wallpaper.
> Give the faces muted warm gray-brown, olive-brown, moss-stained stone, deep
> charcoal-olive recessed joints, restrained green moss along selected upper
> edges, and broad painterly ambient-occlusion pockets. Remove vertical
> striation, cylindrical/pillar shapes, bright yellow cast, repeated towers,
> and any directional cast lighting. Even neutral base-color lighting only.
> The material must work with nearest-filtered world triplanar mapping on true
> 3D terrace meshes in a distant faux-2.5D orthographic camera. Perfect
> seamless continuity on all four edges, uniform texel density, no
> transparency, no grass top plane, no freestanding columns, stairs, ground,
> water, rocks as separate props, characters, UI, text, logo, border,
> perspective, horizon, or watermark.

## Cool moss grass color grade

The selected color-only correction is saved as
`assets/voxel/terrain_grass_top_v7.png` and replaces v6 in the live material.
The non-directional v6 source remains retained.

> Use case: stylized-concept game material. Edit the FIRST supplied square
> seamless grass albedo and preserve its exact non-directional patch layout,
> irregular stepped voxel-cell structure, scale, detail density, edge
> continuity, and absence of directional waves. Use the SECOND supplied image
> only as the approved palette reference. Make a color-grade correction only:
> reduce the bright yellow, lime, and chartreuse cast substantially; lower
> overall midtone brightness by about 15 percent; shift the base to rich medium
> moss green, olive forest green, muted fern green, and cool sage-green shadow
> pockets. Add enough cool blue-green content to stop the runtime material
> reading yellow, while retaining only sparse restrained warm sunlit tips and
> a few subtle worn-earth undertones. Preserve moderate local contrast and
> painterly ambient depth without crushing the texture black. Do not introduce
> stripes, directional flow, cloudy rings, repeated rows, new motifs, or larger
> highlights. Even neutral base-color lighting only; no directional
> highlights, cast shadows, baked sun direction, perspective, horizon,
> transparency, cliffs, paths, water, rocks, flowers, props, characters, UI,
> text, logo, border, or watermark. Maintain perfect seamless tiling on all
> four edges.

## Warm olive grass midpoint

The selected source/runtime midpoint is saved as
`assets/voxel/terrain_grass_top_v8.png` and replaces v7 in the live material.
The cooler v7 source remains retained for comparison.

> Use case: stylized-concept game material. Edit the FIRST supplied square
> seamless grass albedo and preserve its exact non-directional patch layout,
> voxel-cell structure, scale, detail density, calm distribution, and perfect
> edge continuity. Use the SECOND supplied image only as the approved palette
> and value reference. Make a color-grade correction only: raise the current
> dark midtones by about 20 percent; move the cool blue-forest-green cast toward
> the reference's warmer medium olive-moss green, leafy fern green, muted
> yellow-olive, and soft sage. Restore warm green and a little earthy gold, but
> do not return to bright lime, neon chartreuse, or yellow wash. Keep deep
> shadow pockets green rather than blue-black, soften the highest local
> contrast slightly, and preserve only sparse restrained warm tuft highlights.
> The finished swatch should sit visually halfway between the too-bright
> yellow-green previous pass and this too-dark cool-green pass, matching the
> reference meadow at distant orthographic game scale. Do not alter shapes or
> introduce stripes, directional waves, cloudy rings, repeated rows, new
> motifs, large highlights, lighting direction, or shadows. Even neutral
> base-color lighting only; no perspective, horizon, transparency, cliffs,
> paths, water, rocks, flowers, props, characters, UI, text, logo, border, or
> watermark. Maintain perfect seamless tiling on all four edges.

## Stepped-turf grass rebuild

The selected structural correction is saved as
`assets/voxel/terrain_grass_top_v9.png`. The generated original remains at
`C:/Users/hello/.codex/generated_images/01a055ad-8b67-7542-a133-1c1337589a7a/exec-14c19ab0-b18b-4aec-b08a-657a5b7ebf7b.png`.

> Use case: production game material for a true 3D faux-isometric medieval
> homestead. Edit the FIRST supplied square grass albedo. Use the SECOND
> supplied image only as the exact approved visual target for ground palette,
> cell scale, softness, and distant orthographic readability. Rebuild the
> texture rather than preserving the current tuft motifs. Create a straight-on,
> perfectly seamless square grass-top material whose structure is an irregular
> mosaic of broad, softly pixelated square and stepped rectangular turf cells,
> like the target's terrace tops. Use muted medium moss green, warm olive forest
> green, restrained sage, small deep green occlusion pockets, and rare subtle
> earth-brown wear. Absolutely remove the current repeated starburst tufts,
> radial flowers, diagonal fibers, grass-blade strokes, yellow streaks, cloudy
> rings, directional flow, rows, and recognizable motifs. The texture should
> look calm and architectural at game distance: 70 percent broad low-contrast
> turf cells, 20 percent darker irregular cell groups, 10 percent restrained
> warm highlights. Lower yellow/chartreuse saturation and local contrast; no
> bright lime wash. Painterly voxel softness, not photorealism and not tiny
> noisy pixels. Even neutral base-color only with no baked directional lighting
> or shadows. Perfect seamless continuity on every edge with no obvious 2x2
> repetition. No path, stones, cliffs, water, flowers, isolated props,
> characters, buildings, UI, text, logo, border, horizon, perspective,
> transparency, or watermark.

## Rectangular trail-paving rebuild

The selected route correction is saved as
`assets/voxel/terrain_trail_top_v7.png`. The generated original remains at
`C:/Users/hello/.codex/generated_images/01a055ad-8b67-7542-a133-1c1337589a7a/exec-a4cf4516-0bb9-40f0-a6f4-4d9286ee9a9d.png`.

> Use case: production game material for a true 3D faux-isometric medieval
> homestead trail. Edit the FIRST supplied square trail albedo. Use the SECOND
> supplied image only as the exact approved visual target for the path palette,
> paving language, softness, and orthographic readability. Rebuild the surface
> as a straight-on perfectly seamless square material made from irregular
> rectangular and softly stepped block-paving cells set into compacted earth,
> matching the target's warm ochre-beige road. Most units should be small
> rounded rectangles or broken square slabs, not large round river cobbles. Use
> muted tan, dusty straw-beige, warm weathered sandstone, subdued olive-brown
> joints, and sparse moss-green staining in recessed seams. Reduce the current
> pale cream brightness and remove the oversized circular cobble pattern,
> bright white highlights, pebbly noise, and beach-sand look. Keep the surface
> low-contrast, painterly voxel-soft, legible at distant orthographic game
> scale, with enough value separation to read as a route against moss grass.
> The texture must tile without visible seams or periodic rows, and it must
> blend plausibly beneath irregular grass edge geometry. Even neutral
> base-color only; no baked directional lighting or cast shadows. No grass
> field outside seam stains, cliffs, water, bridge, props, footprints,
> characters, buildings, UI, text, logo, border, perspective, horizon,
> transparency, or watermark.

## Mossy cuboid cliff rebuild

The selected terrace-face correction is saved as
`assets/voxel/terrain_cliff_face_v7.png`. The generated original remains at
`C:/Users/hello/.codex/generated_images/01a055ad-8b67-7542-a133-1c1337589a7a/exec-a90e7475-8c82-41cc-9161-91903a85496b.png`.

> Use case: production vertical cliff-face albedo for collision-backed 3D
> terrace meshes in a faux-isometric medieval homestead. Edit the FIRST supplied
> square seamless cliff material. Use the SECOND supplied image only as the
> exact approved target for block proportions, muted palette, moss amount,
> painterly softness, and distant orthographic readability. Preserve a
> straight-on perfectly seamless vertical wall swatch, but make the masonry
> feel like the target: irregular staggered courses of chunky weathered cuboid
> stones, mostly 1.2 to 1.7 times wider than tall, with varied widths, softened
> voxel corners, broken joints, and occasional smaller filler stones. Shift the
> current brown wall toward muted olive-gray, mossy warm charcoal, weathered
> gray-brown, and restrained sage staining. Lighten the deepest black joints
> into broad soft ambient-occlusion recesses so the wall is dimensional without
> graphic black stripes. Add irregular moss caps to selected upper stone edges
> and pockets—clearly visible but no continuous bright green horizontal bands.
> Reduce clean brick-wall regularity, repeated row cadence, hard rectangular
> outlines, vertical columns, and bright yellow edging. Match the target
> terrace's softly painted cuboid depth, not photoreal masonry and not tiny
> brick wallpaper. Even neutral base-color only; no baked directional light,
> cast shadow, perspective, horizon, grass top plane, stairs, water, paths,
> props, characters, UI, text, logo, border, transparency, or watermark.
> Perfect seamless continuity on all four edges with no obvious periodic
> repetition.

## Warm broad-cluster foliage rebuild

The selected canopy correction is saved as
`assets/voxel/terrain_foliage_v6.png`. The generated original remains at
`C:/Users/hello/.codex/generated_images/01a055ad-8b67-7542-a133-1c1337589a7a/exec-36ca177a-c958-4203-8848-80ebd35e8eda.png`.

> Use case: production seamless foliage albedo for true 3D cuboid tree crowns
> and shrubs in a faux-isometric medieval homestead. Edit the FIRST supplied
> square foliage material. Use the SECOND supplied image only as the exact
> approved target for canopy palette, softness, cluster scale, and distant
> orthographic readability. Preserve a straight-on perfectly seamless square
> swatch, but rebalance the current high-contrast foliage into broader softly
> pixelated leaf masses. Use rich warm olive green, moss green, muted fern,
> forest green, restrained sage, and sparse golden-green tips. Lift the
> near-black gaps into readable deep olive shadow pockets, reduce neon lime
> peaks and blue-teal spots, and compress local contrast by roughly 25 percent
> while keeping enough depth for volumetric 3D crowns. Replace tiny repeated
> leaf bursts with irregular broad stepped clusters that can wrap cuboid canopy
> meshes without obvious star shapes, rows, directional flow, or periodic
> islands. Match the target's lush painterly voxel canopy: dark and grounded,
> but not black-crushed; warmly highlighted, but not chartreuse. Even neutral
> base-color only with no baked light direction or cast shadows. Perfect
> seamless continuity on every edge and no obvious 2x2 repeat. No tree
> silhouette, trunk, ground, path, cliff, water, flowers, props, characters,
> buildings, UI, text, logo, border, perspective, horizon, transparency, or
> watermark.

## Compact moss-cap material

The selected compact ledge and rock-cap material is saved as
`assets/voxel/terrain_moss_cap_v1.png`. The generated original remains at
`C:/Users/hello/.codex/generated_images/01a055ad-8b67-7542-a133-1c1337589a7a/exec-c02ea27f-3def-43f6-869d-0c89569486db.png`. A 2 x 2 audit at
`output/homestead_visual_audit/200-moss-cap-v1-tile-preview.png` exposed a mild
center seam, so the runtime deliberately restricts this material to compact 3D
caps, ledges, boulders, and shoreline voxels rather than broad repeating ground.

> Use case: stylized-concept. Asset type: production seamless moss-cap albedo
> for true 3D terrace ledges, boulders, shoreline stones, and small ground-cover
> cuboids in a faux-isometric medieval homestead. Input images: FIRST image is
> the approved game-scene style and palette reference; SECOND image is a
> supporting texture-family reference for pixel softness and turf-cell scale.
> Generate a brand-new square, straight-on, perfectly seamless top-surface
> material. Create dense velvety moss arranged as irregular broad stepped
> voxel-painterly patches: deep olive forest green bases, medium moss green,
> muted fern and sage, restrained warm yellow-olive tips, a few tiny brown
> stone/soil recesses, and broad soft ambient-occlusion pockets. It must look
> richer, darker, and more compact than ordinary grass so moss caps visibly
> ground cliff lips and rocks like the approved reference. Use non-directional
> clustered growth with varied patch sizes and broken edges. Avoid repeated
> starbursts, round flowers, grass-blade strokes, diagonal waves, regular
> checker rows, large circular rings, neon lime, black-crushed gaps, blue-teal
> patches, and photoreal fibers. Even neutral base-color only; no baked
> directional lighting or cast shadows. Perfect seamless continuity on all
> four edges with no obvious 2x2 repetition. No cliff wall, rock silhouette,
> grass horizon, path, water, props, characters, buildings, UI, text, logo,
> border, perspective, transparency, or watermark.

## Calm mosaic river material

The selected river correction is saved as
`assets/voxel/terrain_water_v9.png`. The generated original remains at
`C:/Users/hello/.codex/generated_images/01a055ad-8b67-7542-a133-1c1337589a7a/exec-5a736876-07a9-4da8-a79d-9fe73c704872.png`. Its SHA-256 is
`277D7EFBFFA2FE6243BD49385A4AE31ADD964B4DBAD3148534EBAF97717DF6C7`.
The 2 x 2 seam audit is
`output/homestead_visual_audit/233-water-v9-tile-preview.png` and the accepted
live material pass is `output/homestead_visual_audit/234-water-v9-live-pass.png`.
The runtime removed the old procedural glint cuboids so the generated albedo is
the sole visual owner of river variation.

> Use case: stylized-concept. Asset type: final production seamless voxel
> water-surface albedo for a true 3D faux-isometric medieval homestead river.
> Input images: Image 1 is the current v8 water texture and the edit target.
> Image 2 is the approved concept and is the sole authority for the river's
> color/value and pixel-patch language. Image 3 is the current live game
> capture and shows the failure to correct: luminous cyan caustic ribbons and
> outlined loops. Primary request: flatten Image 1 into the quiet blocky river
> surface visible in Image 2. Remove every glowing loop, curved outline,
> caustic ribbon, diagonal stream band, wave line, and bright slash. Build the
> surface entirely from overlapping broad stepped square and rectangular
> mosaic patches with soft pixelated edges and no outlined shapes. Use a medium
> muted blue-teal base, weathered turquoise blocks, darker teal depth blocks,
> small moss-green submerged pockets, and sparse tiny muted pale-teal square
> highlights. Compress brightness and saturation so the texture is clearly
> lighter than v7 but substantially darker and calmer than v8/live Image 3.
> Highlights should be tiny isolated square clusters, not lines. The tile must
> read as hand-painted voxel water at a distant orthographic camera and must
> not suggest a flow direction. Composition: square, straight-on, perfectly
> seamless non-directional tile; irregular large mosaic clusters; invisible
> wrapping across all four edges; no obvious repeated stripe or center seam.
> Lighting/mood: even neutral base-color only; no baked lighting, reflections,
> cast shadows, transparency, emissive color, or specular bloom. Constraints:
> no horizon, banks, shoreline, rocks, reeds, bridge, terrain, characters,
> buildings, UI, text, logo, border, perspective, transparency, or watermark.
> Avoid: caustics, loops, curved outlines, glowing ribbons, ocean waves,
> diagonal flow bands, horizontal streaks, white slashes, foam, concentric
> rings, photoreal water, tiny noisy pixels, black petrol water, neon cyan pool
> water.

## Warm stair-paver material

The selected runtime step-top correction is saved as
`assets/voxel/terrain_stair_paver_v2_candidate.png`. The v1 material remains
retained at `assets/voxel/terrain_stair_paver_v1.png`, but it is no longer the
selected runtime stair material. The selected v2 asset is 1254 x 1254 pixels,
1,292,115 bytes, with SHA-256
`64BC59E07107F4E19FC0834D678C55F443312C6945856A46CAB67861DC78644F`.
Its original built-in ImageGen output remains at
`C:/Users/hello/.codex/generated_images/01a0604e-e681-7f02-b461-917371c2797a/exec-d4996d70-2286-478f-aee8-cd1016d404de.png`.

The corrected 2 x 2 seam audit is
`output/homestead_visual_audit/stair-paver-v2-candidate-2x2.png`. After the
periodic-component seam correction, the vertical boundary-to-local-variation
ratio is `0.360` and the horizontal ratio is `0.399`. The material is wrapped
around six genuine box-mesh treads backed by one smooth 3D collision ramp.

Exact v2 prompt:

> Use case: stylized-concept
> Asset type: seamless square albedo texture for the top surfaces of physical
> 3D medieval stone stair treads in a Godot voxel-diorama game
> Input images: Image 1 is the approved target style and palette reference;
> Image 2 is the latest live 3D capture showing the current stairs too pale and
> stripe-like; Image 3 is terrain_stair_paver_v1 whose tile function should be
> retained while redesigning its value, joints, and pattern
> Primary request: create one production-ready seamless albedo of broad
> warm-gray medieval stone pavers that makes the live physical stairs approach
> Image 1's chunky, grounded, moss-aged stairway
> Subject: irregular broad hand-set stone pavers with slightly chipped blocky
> edges, restrained surface wear, and dark narrow joints softened by sparse
> olive moss
> Style/medium: handcrafted voxel-diorama / painterly pixel-art material
> texture; softly blocky pixels and forms; refined game-ready albedo rather than
> a rendered scene
> Composition/framing: perfectly orthographic flat square texture, seamless on
> all edges and corners; irregular non-directional arrangement with varied paver
> orientations and staggered joints; no dominant horizontal or vertical
> courses, bands, stripes, center focal point, or border
> Lighting/mood: diffuse illumination-neutral albedo; no cast shadows,
> gradients, highlights, ambient occlusion, or baked directional scene lighting
> Color palette: medium warm gray, weathered taupe-gray, muted charcoal-gray
> joints, restrained mossy olive in occasional crevices; noticeably darker and
> less cream-colored than Image 3, but not black
> Materials/textures: pavers large enough to read under the locked faux-2.5D
> orthographic camera; moderate edge definition; low-to-medium surface
> variation; subtle age without noise
> Constraints: opaque full-bleed RGB square; seamless edges and corners;
> material only; no staircase perspective, no risers, no landscape, soil, path,
> plants, water, architecture, characters, text, symbols, logos, or watermark
> Avoid: pale cream slabs, repeated rows, brick-wall courses, horizontal stripe
> pattern, checkerboard, tiny cobblestones, dense speckle, high-frequency noise,
> photographic realism, glossy or wet stone, strong bevel highlights, pillow
> shading

All selected material generations and edits used built-in ImageGen mode. Their
outputs were copied from Codex generated-image storage into the versioned
project paths above while every original was retained. Godot imports these
files as materials on volumetric meshes; none are camera-facing world cards.

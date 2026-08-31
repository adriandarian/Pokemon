# Adventure exploration scale

## Player-visible outcome

Exploration uses a consistent human-relative scale. The Trailkeeper Lodge reads
as a small building rather than a character-sized prop, hanging lanterns clear a
person's head, signs remain readable but shorter than a person, and the camera
shows enough surrounding world for those larger landmarks to breathe.

## Ownership and scene flow

`AdventureScale` is the immutable presentation-scale owner. Player, NPC, prop,
collision, shadow, and camera code consume its constants; no runtime system
mutates them.

```text
AdventureScale
├── PlayerVisual / AdventureNpcVisual     canonical human height
├── AdventureProp                         prop bounds, footprints, shadows, flame
└── PlayerCharacter / Camera2D             exploration zoom and focus offset
```

Gameplay positions remain canonical world coordinates. Camera zoom changes only
presentation. Collision resources are resized directly rather than scaling
`CollisionShape2D` nodes.

## Human-relative targets

| Subject | Target height |
|---|---:|
| Player | 1.00 human |
| Signpost | 0.72 human |
| Hanging lantern | 1.72 humans |
| Tree | 2.10 humans |
| Trailkeeper Lodge | 3.65 humans |

## Failure modes and validation

- Independent hard-coded sizes drift: smoke tests assert the shared ratios.
- Enlarged art keeps old collision/shadows: prop collisions and grounding use
  the same scale owner.
- Lantern flame detaches: its position and effect scale derive from lantern art.
- Zoom clips the lodge or exposes world caps: deterministic village, north-river,
  pier, and preserve captures verify framing.
- Larger props block traversal: runtime captures and gameplay smoke tests verify
  the trail remains open and interaction targets remain reachable.

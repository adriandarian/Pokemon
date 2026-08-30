# Feature roadmap

Build these as player-visible vertical slices, not as one mega-task. Preserve the direction and ownership rules in `docs/architecture.md`.

## Working foundation

- [x] **Content catalog and runtime profile** — Typed definitions, registry, session ownership, sample content, and smoke test.
- [x] **World presentation decision** — A 2D project with faux-2.5D oblique exploration and flatter 2D battle presentation.
- [x] **Player exploration controller** — Movement, collision, camera, facing, input actions, and interaction intent.
- [x] **Authored starter area** — Windfall Village, river crossing, props, people, signs, world bounds, wild preserve, and Y-sorted actors.
- [x] **Visible wild encounters** — Roaming world actors that begin an encounter through explicit proximity and interaction.
- [x] **Battle and capture slice** — One-versus-one turns, elemental damage, retaliation, HP, consumable Trail Prisms, capture probability, defeat, victory, and escape.
- [x] **Field Guide shell** — Bag, Profile, Creature Dex, and Settings pages connected to real session state.
- [x] **Accessibility/settings seed** — Master volume and reduced-motion state.
- [x] **Automated and visual validation** — Framework/gameplay smoke scenes and deterministic menu, battle, and wild-area preview modes.

## Recommended next slices

- [ ] **Save slots and migrations** — Versioned profile, creature, inventory, world-position, world-flag, and settings persistence.
  Skills: `godot-prompter:save-load`, `resource-pattern`, `godot-testing`

- [ ] **Authored spawn tables** — Replace fixed wild spawns with weighted species resources, level bands, rarity, respawn policy, and seeded tests while keeping creatures visible.
  Skills: `godot-prompter:resource-pattern`, `component-system`, `math-essentials`, `godot-testing`

- [ ] **Battle depth** — Move selection, four move slots, effectiveness messaging, XP, leveling, status hooks, and balance tests.
  Skills: `godot-prompter:state-machine`, `ability-system`, `math-essentials`, `animation-system`, `godot-testing`

- [ ] **Party and reserve management** — Six party slots, reordering, details, move view, capture overflow, and storage transfer.
  Skills: `godot-prompter:godot-ui`, `responsive-ui`, `inventory-system`, `input-handling`, `godot-testing`

- [ ] **World transition service** — Enter and exit named `LocationDefinition` scenes through a loading transition while preserving return positions.
  Skills: `godot-prompter:scene-organization`, `event-bus`, `save-load`, `tween-animation`

- [ ] **Mossglass Cave vertical slice** — One cave with a 2D/2.5D presentation shift, navigation, visible encounters, a puzzle, rest point, challenge, and exit reward.
  Skills: `godot-prompter:2d-essentials`, `camera-system`, `ai-navigation`, `audio-system`, `particles-vfx`

- [ ] **Badges and progression gates** — Badge challenges, requirements, rewards, location gates, and a badge case screen.
  Skills: `godot-prompter:resource-pattern`, `event-bus`, `godot-ui`, `save-load`, `godot-testing`

- [ ] **Dialogue and quests** — Branching NPC conversations, quest state, rewards, and localization-ready text.
  Skills: `godot-prompter:dialogue-system`, `localization`, `event-bus`, `save-load`, `godot-ui`

- [ ] **Production presentation** — Sprite pipeline, directional animation, transitions, combat VFX, audio buses, remapping, scalable text, and color-independent element cues.
  Skills: `godot-prompter:assets-pipeline`, `animation-system`, `particles-vfx`, `audio-system`, `input-handling`, `responsive-ui`

# Creature Trail

Creature Trail is an original creature-collecting RPG built in Godot 4.5. It now starts as a real playable game: explore an oblique 2.5D village, walk into a visible wild preserve, approach roaming creatures, switch into a flatter 2D battle, weaken or capture them, and inspect your growing collection.

This is a vertical-slice framework rather than a finished campaign. Its systems are deliberately separated so future AI agents can add creatures, routes, caves, dungeons, badges, moves, quests, and progression without rebuilding the foundation.

## Play now

```powershell
godot --path .
```

- `WASD` or arrow keys — move
- Hold `Shift` — run
- `E` — interact with people, signs, and wild creatures
- `Tab` or `Esc` — open or close the Field Guide
- In battle — choose Fight, throw a Trail Prism, or Run

The current slice includes:

- A camera-followed player with acceleration, collision, facing, and authored interactions.
- A faux-2.5D voxel overworld with depth sorting, continuous generated grass, an oblique trail, grounded village props, an animated river, and a wild preserve.
- Three original creature species and four original elements/moves.
- Visible roaming wild creatures; encounters happen by approaching and interacting, not by an invisible random roll.
- A turn-based 2D battle presentation with health, elemental damage, retaliation, capture probability, victory, defeat, and escape.
- A Field Guide with Bag, Profile, Creature Dex, and Settings pages.
- Consumable capture tools, healing supplies, party/reserve state, discoveries, and badge-ready progression data.
- Reduced-motion and master-volume settings.

No Pokémon names, creatures, art, audio, maps, or proprietary data are included. Keep new content original.

## Verify it

```powershell
godot --headless --path . res://tests/framework_smoke_test.tscn
godot --headless --path . res://tests/gameplay_smoke_test.tscn
godot --headless --path . res://tests/world_animation_smoke_test.tscn
godot --headless --path . res://tests/location_banner_smoke_test.tscn
godot --headless --path . --quit-after 3
```

Deterministic developer previews are also available for visual work:

```powershell
godot --path . -- --preview-menu
godot --path . -- --preview-profile
godot --path . -- --preview-dex
godot --path . -- --preview-battle
godot --path . -- --preview-wild
godot --path . -- --preview-animation=walk
godot --path . -- --preview-animation=run
godot --path . -- --capture-delay-frames=90 --capture-preview=res://preview.png
```

### Quick actions

When opened as a Codex project, select the `Creature Trail` local environment
from the Environment panel. Its action buttons launch the game, deterministic
previews, smoke tests, and project validation. The definitions live in
`.codex/environments/environment.toml`.

The same commands are also available as VS Code tasks from `Terminal > Run Task`:

- `Creature Trail: Run game`
- `Creature Trail: Preview menu`
- `Creature Trail: Preview battle`
- `Creature Trail: Preview wild area`
- `Creature Trail: Smoke test framework`
- `Creature Trail: Smoke test gameplay`
- `Creature Trail: Validate project`

The Godot editor must be open with the `AI Game Builder` plugin enabled for the
Codex editor bridge. It listens on `127.0.0.1:6100` and is configured in
`.mcp.json`.

## Repository map

```text
autoload/                    Cross-scene registry, session, events, settings
common/                      Shared data and UI contracts
content/                     Designer-authored read-only .tres content
features/adventure/          Overworld composition, player, props, wild actors, HUD
features/battle/             Encounter state, battle rules, presentation, controls
features/menu/               Bag, Profile, Creature Dex, and Settings UI
features/creatures/          Species, runtime creature state, original visuals
features/inventory/          Item definitions
features/progression/        Badges and player profile data
features/world/              Location definitions
features/world_animation/    Shared human clips, wind, shoreline, grass, and flame motion
tests/                       Headless framework and gameplay validation
docs/                        Architecture, roadmap, and agent prompting workflow
```

## Building the rest with AI agents

Start with [the architecture guide](docs/architecture.md), then give an agent one bounded vertical slice using [the agent workflow](docs/agent-workflow.md). [The feature roadmap](docs/godot-prompter/plans/feature-roadmap.md) records what exists and what should come next.

The core rule is simple: authored definitions are read-only templates; runtime instances own changing state; UI reflects state but never owns it. Local feature controllers perform game rules, and global services are reserved for genuinely cross-scene concerns.

# Creature RPG foundation specification

> Historical milestone: this foundation specification is complete. The project has since locked its exploration and battle presentation and built a playable vertical slice; use `docs/architecture.md` for current decisions.

## Product statement

Create an original creature-collecting RPG in which a player explores settlements, routes, caves, and dungeons; collects and trains elemental creatures; and earns badges that unlock progression.

## Foundation goals

- Scale from a handful to hundreds of creature species without species-specific scripts.
- Let future agents build one bounded feature without editing unrelated systems.
- Keep authored content, mutable session state, game rules, and presentation separate.
- Make invalid IDs and duplicate catalog entries fail visibly during development.
- Keep the engine perspective and battle model open until explicitly designed.

## Non-goals for this milestone

- Player movement or world rendering.
- Encounters, capture, combat, AI, dialogue, inventory, quests, or saving.
- Final balance curves, battle formulas, art, audio, or story.
- Reproduction of proprietary Pokémon content.

## Data contract

The foundation defines:

- `ElementDefinition`
- `MoveDefinition`
- `CreatureStats`
- `CreatureSpecies`
- `CreatureInstance`
- `BadgeDefinition`
- `LocationDefinition`
- `PlayerProfile`
- `GameContentCatalog`

Definitions are authored Resources and treated as immutable at runtime. Instances and the player profile are mutable state created for a session.

## Service contract

- `ContentRegistry` indexes definitions by stable `StringName` ID and reports validation failures.
- `GameSession` is the sole current writer for party, reserve, discoveries, and badges.
- `EventHub` contains only typed cross-feature lifecycle events.
- The bootstrap controller translates view intent into session commands.

## Acceptance criteria

- The project loads on the installed Godot 4.5.1 runtime.
- Catalog lookup returns all sample content without duplicate or empty IDs.
- Collecting a known species creates runtime state and updates the party.
- Awarding a known badge succeeds once and rejects duplicates.
- The bootstrap scene reflects registry and profile state without owning either.
- A headless smoke test exits zero.

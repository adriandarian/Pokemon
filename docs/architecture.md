# Creature Trail architecture

## Product direction

Creature Trail uses a 2D Godot project with two complementary presentations:

- Exploration is faux 2.5D: 2D sprites and shapes, oblique scenery, Y-based depth sorting, and a camera-followed character.
- Encounters deliberately flatten into a composed 2D battle stage.

That direction is locked. New features should strengthen the transition between those modes rather than replacing the project with a 3D controller or an unrelated menu prototype.

## System layers

```text
Presentation  adventure world, HUD, Field Guide, battle stage, animation and VFX
      │        displays state and emits player intent
      ▼
Logic         adventure controller, battle encounter/rules, session mutations
      │        owns feature rules and temporary encounter state
      ▼
Data          typed Resources and runtime profile/creature instances
      │        authored templates remain read-only
      ▼
Infrastructure content registry, event hub, settings, future save/scene services
```

Signals travel upward, method calls travel downward, and `EventHub` carries only cross-feature lifecycle events.

## Runtime composition

```text
SceneTree
├── EventHub
├── ContentRegistry
├── GameSession
├── SettingsService
└── Adventure
    ├── WorldCanvas                 painted oblique environment
    ├── WorldBounds / River / Fence collision
    ├── Actors (Y-sorted)
    │   ├── Player                  movement, facing, camera, interaction intent
    │   ├── Props                   people, signs, lodge, trees, rocks, lanterns
    │   └── WildCreatures           visible roaming encounter actors
    └── Interface (CanvasLayer)
        ├── AdventureHUD
        ├── GameMenu                Bag, Profile, Creature Dex, Settings
        └── BattleOverlay           temporary battle composition root
```

`AdventureController` orchestrates the current map and transitions. It does not calculate damage, mutate inventory directly, or own menu data. `BattleEncounter` owns temporary hit points; `BattleRules` owns pure formulas; `GameSession` commits persistent results.

## Ownership map

| State | Authoritative owner | Observers |
|---|---|---|
| Elements, moves, species, items, badges, locations | `.tres` definitions through `GameContentCatalog` | Registry and gameplay systems |
| Catalog ID indexes | `ContentRegistry` | Any feature needing a definition |
| Party, reserve, discoveries, inventory, badges | `GameSession.profile` | Menu, battle, future save/quest systems |
| Creature level, HP, known moves | `CreatureInstance` in the profile | Profile menu, battle, future progression |
| Temporary wild/player battle HP and capture chance | `BattleEncounter` | `BattleOverlay` |
| Current menu page, focus, labels, animation | The corresponding UI scene | Player only |
| Master volume and reduced motion | `SettingsService` | Presentation and future audio systems |

Never mutate a species, move, item, badge, or location definition during play. Create or update a runtime instance instead.

## Content flow

```text
content/*.tres
      │
      ▼
GameContentCatalog ──► ContentRegistry ──stable StringName lookup──► feature rule
                                                                      │
                                                                      ▼
GameSession / BattleEncounter ──typed signal or query──► presentation
```

Stable IDs survive display-name changes and will later become save-file references. Adding content means creating the correct typed Resource and adding it to the catalog; species-specific scripts should be exceptional.

## Feature boundary contract

Add independent work under `features/<feature_name>/`. A substantial feature should document:

- The player-visible outcome.
- Its mutable-state owner.
- Scene tree and public signals/methods.
- Catalog or profile fields it adds.
- Failure modes and an isolated validation path.

A feature is ready to integrate when it:

1. Runs in isolation or through a deterministic preview.
2. Has one authoritative owner for every changing value.
3. Does not reach through parent chains or repeatedly scan scene groups per frame.
4. Uses typed GDScript at public and data boundaries.
5. Does not mutate shared authored Resources.
6. Uses direct signals locally and documents any new global event.
7. Adds a headless behavior test and starts with the full project.
8. Has been visually captured and inspected when pixels changed.

## Locked and open decisions

Locked:

- Godot 4.5 and typed GDScript.
- 2D project with faux-2.5D exploration and flat 2D battle presentation.
- Camera-followed character movement with explicit interactions.
- Wild creatures visible in the world before battle.
- Turn-based one-versus-one encounter slice with weakening and consumable capture tools.
- Original names, creatures, visuals, and world content.

Still open for dedicated design tasks:

- Final stat-growth, XP, move-slot, status-effect, and balance models.
- Hand-authored versus hybrid procedural dungeon layouts.
- Save slots, migrations, and cloud synchronization.
- Quest structure, branching dialogue, and badge challenge rules.
- Desktop-only versus eventual controller/mobile targets.
- Production art, animation, audio, and accessibility scope.

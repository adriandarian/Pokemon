# AI agent workflow

Use one prompt for one feature. Ask the agent to inspect this repository, read the matching project-local Godot skills, write or update a design contract, implement the smallest complete vertical slice, and prove it works.

## Prompt template

```text
Build: <one concrete feature>

Player outcome:
<what the player can do or observe when this is finished>

Scope:
- <required behavior>
- <required behavior>
- <explicit integration point>

Out of scope:
- <adjacent feature that must not be invented>
- <art/content work that is not part of this task>

Constraints:
- Godot 4.5.1 and typed GDScript.
- Follow docs/architecture.md and the feature-folder convention.
- Treat content/*.tres as read-only definitions during play.
- Keep UI presentation separate from state mutation.
- Prefer local signals; add EventHub signals only for cross-feature lifecycle events.
- Preserve the locked faux-2.5D exploration, flat 2D battle, visible-wild-creature, and original-content direction in `docs/architecture.md`.
- Do not choose one of the remaining open game-wide design decisions without a dedicated design task.
- Use original names and assets; do not import proprietary Pokémon content.

Before implementation:
1. Read AGENTS.md and the matching godot-prompter skills.
2. Inspect existing integration points and working-tree changes.
3. Create or update features/<feature>/DESIGN.md with ownership, scene tree,
   signal map, data flow, and failure modes.

Definition of done:
- The feature runs in isolation.
- Relevant headless tests pass.
- The full project starts without parser or resource errors.
- New persistent fields and catalog entries are documented.
- Visual work is captured and inspected at desktop and narrow resolutions.
- Report changed files, validation performed, and remaining decisions.
```

## Good task sizes

- “Add sprinting and stamina to the existing player controller. Preserve walking, collision, interaction, and the current camera.”
- “Replace the current fixed wild spawns with authored weighted spawn resources while keeping creatures visible in the preserve.”
- “Build a six-slot party editor that reorders `CreatureInstance` objects through `GameSession`. Do not implement storage search.”
- “Design and implement Mossglass Cave as one authored dungeon room with an entrance, exit, encounter zones, and a locked reward.”

Avoid prompts such as “finish battles” or “make the whole world.” They hide too many design decisions and produce tightly coupled systems.

## Agent handoff checklist

Require the agent to report these separately:

- Local parse/startup result.
- Automated test result.
- Visual inspection result, if pixels changed.
- What was deliberately not implemented.
- Any choice that still needs the game designer.

Do not accept “it should work” as validation.

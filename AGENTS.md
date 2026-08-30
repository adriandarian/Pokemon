# Agents

## Godot AI Game Builder

The project-local Godot AI Game Builder skill is installed under
`.agents/godot-ai-builder/`. Its MCP bridge is configured in `.mcp.json` and
expects the Godot editor plugin to be enabled on port `6100`.

The editor plugin still needs to be installed after this repository contains a
Godot project (`project.godot`).

## Additional Godot Skills

- `gd-agentic-skills` is vendored at `.agents/gd-agentic-skills/`.
- Its focused `godot-master` skill is available through
  `.agents/skills/godot-master/`.
- `GodotPrompter` is vendored at `.agents/GodotPrompter/`.
- Its skills are available through `.agents/skills/godot-prompter/`.

These are project-local junctions, so updating either vendored repository keeps
the discovered skills current.

## Project Framework

Before building a feature, read `docs/architecture.md` and
`docs/agent-workflow.md`. Keep one authoritative owner for mutable state, treat
`content/*.tres` as read-only definitions during play, and add features under a
co-located `features/<feature_name>/` boundary with an isolated validation path.

Preserve the locked faux-2.5D exploration, flat 2D battle, visible-wild-creature,
and original-content direction in the architecture guide. Remaining open design
choices belong to the game designer and require an explicit feature design task.

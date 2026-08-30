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

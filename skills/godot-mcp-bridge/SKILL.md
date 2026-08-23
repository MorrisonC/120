---
name: godot-mcp-bridge
description: Connects an AI agent to a live Godot 4 editor/debug session via MCP (Model Context Protocol), for scene generation, live gameplay testing with real input simulation, and scene-tree state assertions -- this is Tier 2 of the three-tier test harness in TEST_HARNESS_ARCHITECTURE.md. Use this for building/editing scenes and for play-testing gameplay logic through real simulated input BEFORE spending an export cycle on the Tier 3 web-export E2E check. Does NOT test the web export itself -- that's gauntlet-loop-120's Playwright-based capture.
license: CC-BY-4.0
compatible_agents: [jules, claude-code, gemini-cli, cursor, antigravity]
depends_on_project_files: [TEST_HARNESS_ARCHITECTURE.md]
---

# Godot MCP Bridge

Provides Tier 2 of the test pyramid described in
`TEST_HARNESS_ARCHITECTURE.md`: a live connection from an AI agent to a
running Godot editor/debug session, via one of several public MCP
servers for Godot. Read that document first — this skill is one piece
of a three-tier setup, not a replacement for the web-export E2E tier.

## Which server this skill uses

**Default: mkdevkit/godot-mcp**
(https://github.com/mkdevkit/godot-mcp) — chosen for its explicit
Testing/QA toolset (`run_test_scenario`, `assert_node_state`,
`assert_screen_text`, `run_stress_test`, `get_test_report`), which maps
closely to "walk from spawn to checkpoint and assert what happened,"
and its Android build/deploy tools, which match this project's existing
Android export target.

**Alternatives** (see `resources/server-comparison.md` for the full
tradeoff table) if the default doesn't fit:
- `Coding-Solo/godot-mcp` — simplest install (`npx @coding-solo/godot-mcp`),
  most established/referenced, lighter tool surface
- `Erodenn/godot-runtime-mcp` — explicit input-simulation + screenshot
  tools, no permanent addon installation (temporary runtime bridge)

**Stated plainly:** this recommendation comes from public tool-list
descriptions gathered via search, not hands-on use — this space has
many competing implementations and moves fast. Verify the pick actually
works for your setup before depending on it in CI, and check the linked
repo directly since tool names/behavior may have shifted.

## Setup

`scripts/doctor.sh` checks for Node.js, a local Godot 4 installation,
and walks through installing the MCP server plugin into the project.

Per mkdevkit/godot-mcp's own structure, this means copying its editor
plugin into the project:
```
addons/godot_mcp/          # Godot editor plugin -- copy into your project
  plugin.gd
  plugin.cfg
  websocket_client.gd
```
Then configuring your MCP client (Jules, Claude Code, Cursor, etc.) to
point at the server. See `resources/setup-guide.md` for the exact steps
and `assets/mcp-client-config.json` for a template client config.

## What to use this for

- **Content generation**: building/editing scenes, placing nodes,
  wiring signals — directly serves the "maximize generation" goal,
  since an agent can build a room and immediately play-test it in the
  same session without a full export cycle.
- **Gameplay logic testing with real input**: drive the player through
  a scene with actual simulated input and assert on real scene-tree
  state (exact position, node properties) rather than inferring from
  pixels the way the Tier 3 Playwright sanity-check has to.
- **Pre-flighting a walk sequence** before authoring a
  `walk-script.json` for the Tier 3 harness (see
  `gauntlet-loop-120/resources/walk-script-format.md`) — if this tier
  can read the actual seed's room layout, that's a much better source
  for "what sequence of moves reaches the checkpoint" than guessing
  from screenshots.

## What NOT to use this for

Don't treat a Tier 2 pass as proof the web export works. It isn't —
see `TEST_HARNESS_ARCHITECTURE.md`'s explanation of why the gray-screen
bug would have sailed through this tier undetected. Tier 3
(`gauntlet-loop-120`'s Playwright capture) is still required for
anything that could plausibly be web-export-specific.

## Guardrails
- This skill controls a local Godot process — don't point an MCP
  client at a shared/production Godot instance.
- If using a server that installs a permanent editor addon
  (mkdevkit's, Coding-Solo's), that addon becomes part of the committed
  project — decide deliberately whether it ships in version control or
  stays local-only (a `.gitignore` entry), rather than accidentally
  committing it.

# Godot MCP Server Comparison

Surveyed via web search, not hands-on use — verify against the actual
repo before committing to one. This is a fast-moving, crowded space;
treat this table as a starting point from the time this was written,
not a permanent ranking.

| Server | Install | Notable tools | Footprint | Best for |
|---|---|---|---|---|
| **mkdevkit/godot-mcp** (default) | Copy `addons/godot_mcp/` plugin into project | `run_test_scenario`, `assert_node_state`, `assert_screen_text`, `run_stress_test`, `get_test_report`; Android deploy tools; navigation, audio, animation-tree tools | Permanent addon in project | Structured gameplay testing with assertions; matches this project's Android export target |
| **Coding-Solo/godot-mcp** | `npx @coding-solo/godot-mcp` | Launch editor, run projects, capture debug output, scene/node management, UID management | Node.js server, no project changes | Simplest onboarding; most widely referenced/established; general dev-time scene work |
| **Erodenn/godot-runtime-mcp** | Temporary runtime bridge, no addon install | Screenshots, batched input simulation (key/mouse/UI-element clicks), UI discovery, live GDScript execution, headless scene editing | Nothing committed to the project — bridge injected and removed at runtime | Zero-footprint testing; explicit input simulation without a permanent addon |
| **hybridindie/godot-mcp** | Addon + stdio or HTTP service mode | 175 tools across scene edit, input driving, replay recording, profiling, build export, static analysis; toolsets are enabled selectively to avoid overwhelming an agent's context | Addon + optional standalone HTTP service for multiple simultaneous clients | Large teams/multiple agents needing one shared live editor connection |
| **hi-godot/godot-ai** | Godot Asset Library / Asset Store, one-click install | ~43 tools across ~120 ops: scenes, nodes, scripts, signals, materials, animations, particles, cameras | Asset Store install | Convenience if already browsing Godot's own asset store for tooling |
| **GDAI MCP** | Editor plugin | Scene/resource/script generation, scene-tree modification, debugger output/log reading, resource search | Editor plugin | General-purpose editor control with debugger integration |

## Why mkdevkit is the default here

The Testing/QA-specific tools (`run_test_scenario`, `assert_node_state`,
`assert_screen_text`, `get_test_report`) are the closest match to this
project's actual need: not just "can an agent poke the editor" but "can
an agent run something resembling a real test and get a structured
pass/fail back." The Android deploy tools are a secondary but genuinely
relevant match given `Progress.md`'s existing Android export target.

## When to reach for an alternative instead

- Want zero footprint in the committed repo → Erodenn's temporary-bridge
  approach.
- Want the simplest possible setup to just try this tier out first →
  Coding-Solo's `npx`-based install.
- Multiple agents/sessions need to share one live editor connection
  simultaneously → hybridindie's HTTP service mode.

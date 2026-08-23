# Setup Guide — mkdevkit/godot-mcp (default)

1. **Get the plugin.** Clone or download
   https://github.com/mkdevkit/godot-mcp and copy its
   `addons/godot_mcp/` folder into this project's own `addons/`
   directory (alongside the existing `addons/gut/` from Milestone 1).

2. **Enable the plugin in Godot.** Project Settings → Plugins →
   enable "Godot MCP" (or whatever the plugin.cfg names it — check
   `addons/godot_mcp/plugin.cfg` for the exact display name).

3. **Start the Node.js MCP server side.** Per the project's own docs —
   check its README for the exact launch command, since this may have
   changed since this guide was written. The architecture (per its
   README) is: `AI client <-stdio/MCP-> Node.js server
   <-WebSocket:6505-> Godot editor plugin`.

4. **Configure your MCP client.** For Jules specifically, add the
   server per however Jules' own MCP configuration convention works —
   check Jules' current documentation, since this skill doesn't have
   visibility into Jules' exact config format. `assets/mcp-client-config.json`
   in this skill gives a generic template shape (matching the common
   `mcpServers` JSON convention used by Claude Code/Cursor-style
   clients) to adapt.

5. **Verify the connection.** With the Godot editor open and the
   plugin enabled, confirm your MCP client can see the server's tools
   (e.g. `get_project_statistics` or similar introspection tool) before
   relying on it for anything else.

6. **Decide on version control.** `addons/godot_mcp/` becomes part of
   the project once copied in. Either commit it (so every session has
   it available without re-installing) or add it to `.gitignore` if you
   want it local-only — this skill doesn't decide that for you, since
   it depends on whether you want every contributor to have this
   tooling by default.

## First things to try

- Ask the connected agent to report the current scene tree of whatever
  scene is open — confirms the read path works.
- Ask it to run a trivial `run_test_scenario` (per mkdevkit's tool
  list) against the player scene and report `assert_node_state` on the
  player's starting position — confirms the test/assertion path works,
  which is the actual point of using this tier.
- Only after both of those work, move on to using it for real
  gameplay-logic testing or scene generation work.

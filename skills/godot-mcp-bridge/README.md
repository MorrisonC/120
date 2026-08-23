# godot-mcp-bridge

Tier 2 of the three-tier test harness described in
`TEST_HARNESS_ARCHITECTURE.md`: connects an AI agent to a live Godot 4
editor/debug session via MCP, for content generation and gameplay-logic
testing with real input — before paying the cost of a full web-export
cycle (Tier 3, `gauntlet-loop-120`).

**Does not test the web export.** That's a different tier, still
required — see `TEST_HARNESS_ARCHITECTURE.md` for why the gray-screen
bug specifically would never have been caught here.

## Install
```bash
npx skills add <this-repo> --skill godot-mcp-bridge --global
```

## Quick start
```bash
bash scripts/doctor.sh
# then follow resources/setup-guide.md for the one-time plugin install
```

## Which server
Defaults to `mkdevkit/godot-mcp` for its explicit Testing/QA tools.
Two alternatives documented in `resources/server-comparison.md` if that
one doesn't fit your setup.

## Honest caveat
The server recommendation comes from public tool-list descriptions
gathered via web search, not hands-on use. Verify it actually works for
your setup before depending on it — this space has many competing
implementations and moves fast.

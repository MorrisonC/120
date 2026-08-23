# TEST_HARNESS_ARCHITECTURE.md

## What actually went wrong

The gauntlet loop skill's earlier web-capture script
(`playwright_walk_run.js`) took time-spaced screenshots but **never sent
a single keypress**. It loaded the page, waited, and screenshotted on a
timer — so a run report saying "captured" only ever proved the page
rendered something, never that the player character could move, reach a
checkpoint, trigger a puzzle, die on the timer, or respawn. That's the
direct cause of what you saw: nothing was testing movement because
nothing was driving movement. Fixed in this update — see
`scripts/playwright_walk_run.js`'s `sanity` mode, which sends real
`page.keyboard.down/up` events at the focused canvas and confirms via a
frame hash-diff that each keypress actually changed what's on screen.

## Three tiers, each catching a different class of bug

No single layer covers "the game works." Use all three:

### Tier 1 — GUT (unit/integration, headless, no rendering)
`scripts/run_godot_tests.sh`. Fast, no browser, no GPU. Proves logic is
correct in isolation: does the solvability engine compute the right
answer, does the life system remove features in the right order, does
the chime fire on the right event. **Cannot** catch anything about
whether a human's actual keypresses reach the actual player character,
because nothing simulates input here at all.

### Tier 2 — Godot MCP (editor-runtime, live debug session)
NEW — see `skills/godot-mcp-bridge/`. Connects an AI agent to a live
Godot editor/debug-player session (desktop, not the web export) via
WebSocket/UDP. Can simulate real input, read actual scene-tree state
(exact player `Vector2` position, node properties, signal firing — not
guesswork from pixels), take screenshots, and in some implementations
run structured test scenarios with pass/fail assertions. This is the
right tier for validating gameplay logic through real input *before*
paying the cost of an export cycle, and for the "maximize generation"
side of things — an agent can build/edit scenes and immediately play-test
the result in the same loop.

**Still cannot** catch anything specific to the web export itself
(threading/COOP-COEP header issues, canvas focus behavior, browser-side
asset loading) — it's testing the editor's debug player, not the shipped
build.

### Tier 3 — Playwright web-export E2E (real browser, real shipped build)
`scripts/capture_web_e2e.sh` + `scripts/playwright_walk_run.js`. The
**only** tier that tests what an actual player experiences: the real
exported `.wasm`/`.pck`, served over HTTP, driven by real simulated
keyboard events at the real canvas in a real browser engine (Chromium,
via Playwright). This is the tier that would have caught the gray-screen
bug (a Tier 1 or Tier 2 pass tells you nothing about missing COOP/COEP
headers), and it's the tier that's now fixed to actually simulate
movement input instead of passively screenshotting.

## Why you need Tier 2 AND Tier 3, not just one

They catch different things and neither substitutes for the other:
- Tier 2 without Tier 3: you could ship a game that plays perfectly in
  the editor and gray-screens on the web (exactly what happened).
  Godot MCP servers control the *editor's* debug player, not a browser.
- Tier 3 without Tier 2: you could catch a web-export bug but have a
  much slower, coarser iteration loop for everyday gameplay logic
  changes, since Tier 3 requires a full export + serve + browser launch
  cycle for every check, and can only infer state from pixels (the
  hash-diff sanity check, or a screenshot a human/agent reads) rather
  than reading real scene-tree values.

## Choosing a Godot MCP server (Tier 2)

Several exist; this project defaults to
**mkdevkit/godot-mcp** for its explicit Testing/QA toolset
(`run_test_scenario`, `assert_node_state`, `assert_screen_text`,
`run_stress_test`, `get_test_report`) — the closest match to "walk from
spawn to checkpoint and assert what happened" of the options surveyed.
It also has Android deploy tools, which lines up with this project's
existing Android export target.

Two credible alternatives, in case the primary doesn't fit your setup:
- **Coding-Solo/godot-mcp** (`npx @coding-solo/godot-mcp`) — the most
  established/widely-referenced implementation; simpler tool surface
  (launch editor, run projects, capture debug output, scene management),
  weaker on structured test assertions specifically.
- **Erodenn/godot-runtime-mcp** — explicit input-simulation and
  screenshot tools, and notably requires **no permanent addon
  installation** (injects a temporary bridge at runtime, removes it
  after) — worth it if you want zero footprint in the committed project.

**Caveat, stated plainly:** these come from public tool-list
descriptions gathered via web search, not hands-on use. This space is
crowded and moves fast (at least 8 competing implementations turned up
in one search). Verify the primary pick actually works for your setup
before relying on it, and don't be surprised if tool names/behavior have
shifted since this was written — check the linked repo directly.

## Practical guidance going forward

- Any task that touches gameplay logic: verify with Tier 1 (if a unit
  test covers it) and Tier 2 (play it in the debug session) before
  spending an export cycle on Tier 3.
- Any task that could plausibly be web-export-specific (anything
  touching rendering, input focus, asset loading paths, threading):
  Tier 3 is mandatory — Tier 1/2 passing tells you nothing about it.
- The Lane A/Lane B gate in `gauntlet-loop-120/SKILL.md` still applies
  across all three tiers — a Lane B (critic-judged) target still isn't
  allowed to start until its Lane A prerequisites (wherever they sit in
  this pyramid) are green.

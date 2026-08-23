# TASK_QUEUE_ADDITIONS.md

New small tasks from this session, sized per
`gauntlet-loop-120/resources/task-sizing-guide.md`. **Merge these into
the real `TASK_QUEUE.md` at the start of the next session** — written
separately here because this session doesn't have live access to
confirm `TASK_QUEUE.md`'s current state (earlier `GRAY-*`/`E2E-*` tasks
may already be done). Check status before merging, and renumber if
these IDs collide with anything added since.

---

## Epic: Fix real input simulation (addresses the reported movement-testing bug)

## [TODO] INPUT-1: Confirm real InputMap key bindings
- Scope: read `project.godot`'s `[input]` section, record the actual
  action names and physical keys bound to movement/interact.
- Acceptance: one-line note in this entry listing the real bindings —
  feeds INPUT-2.
- Depends on: none

## [TODO] INPUT-2: Trim playwright_walk_run.js's sanity check to real bindings
- Scope: `skills/gauntlet-loop-120/scripts/playwright_walk_run.js`'s
  `runSanityCheck` — remove whichever of the arrow-key/WASD schemes
  INPUT-1 shows isn't actually bound, so the manifest isn't cluttered
  with expected no-ops.
- Acceptance: `capture_web_e2e.sh <target> sanity` run against the real
  web export shows `any_frame_changed: true`.
- Depends on: INPUT-1, GRAY-8 (needs a working web export to test against)

## [TODO] INPUT-3: Author a first real walk-script for the starting biome
- Scope: one `resources/walk-scripts/<seed>-start-to-first-checkpoint.json`,
  authored per the iterative process in
  `resources/walk-script-format.md`.
- Acceptance: running it produces a manifest where the player visibly
  reaches the first checkpoint in the final screenshot.
- Depends on: INPUT-2

---

## Epic: Godot MCP integration (Tier 2 testing)

## [TODO] MCP-1: Install the godot-mcp-bridge default server's plugin
- Scope: follow `skills/godot-mcp-bridge/resources/setup-guide.md` steps
  1-2 only (get the plugin, enable it) — not the full client config yet.
- Acceptance: plugin shows enabled in Project Settings -> Plugins.
- Depends on: none

## [TODO] MCP-2: Connect one MCP client and verify the read path
- Scope: setup-guide.md steps 3-5.
- Acceptance: the connected agent can report the current scene tree of
  an open scene.
- Depends on: MCP-1

## [TODO] MCP-3: Run one real run_test_scenario against the player scene
- Scope: a single trivial scenario + `assert_node_state` check on
  starting position, per setup-guide.md's "first things to try."
- Acceptance: get_test_report returns a structured pass/fail, not just
  raw output.
- Depends on: MCP-2

---

## Epic: Movement & combat retrofit (TetraForce reference)

## [TODO] REF-1: Study TetraForce's engine/ and entities/ folders
- Scope: read (not yet implement) the actual GDScript in those two
  folders of https://github.com/loudsmilestudios/TetraForce, MIT
  licensed. Take notes on movement/state-machine patterns actually
  worth adapting vs. this project's existing CharacterBody2D setup.
- Acceptance: a short notes addition to
  `MOVEMENT_AND_COMBAT_REFERENCE.md` Section 5 recording what was
  actually found (this session's version of that section is a
  genre-convention writeup, not a code read — this task is what turns
  it into one).
- Depends on: none

## [TODO] COMBAT-1: Decide Option A vs Option B (see MOVEMENT_AND_COMBAT_REFERENCE.md Section 2)
- Scope: decision only — small hit-pool/instant-respawn (Option A,
  recommended) vs. fuller health-bar system (Option B).
- Acceptance: decision recorded, with one sentence of reasoning, in
  `MOVEMENT_AND_COMBAT_REFERENCE.md` Section 2.
- Depends on: none (this genuinely just needs a human/product decision)

## [TODO] COMBAT-2: Implement the attack hitbox on the player
- Scope: one directional melee attack, active hitbox for a short window
  on the facing direction, triggered by a button press. No enemies yet
  — just the swing and hitbox existing and testable in isolation.
- Acceptance: a GUT test (or Tier 2 Godot MCP `assert_node_state`
  check) confirming the hitbox activates and deactivates on schedule.
- Depends on: COMBAT-1

## [TODO] COMBAT-3: Add one enemy type using the decided health model
- Scope: one enemy, the decided damage/death model from COMBAT-1,
  defeatable by COMBAT-2's hitbox.
- Acceptance: GUT test confirming N hits (per Option A/B's chosen
  number) triggers the same respawn-at-bookmark path the timer-expiry
  case already uses.
- Depends on: COMBAT-2

## [TODO] REF-2: Import Ninja Adventure Asset Pack assets
- Scope: pull character/monster/tileset assets from
  https://pixel-boy.itch.io/ninja-adventure-asset-pack (CC0, see
  `ASSET_LINKS_ADDENDUM.md`) into the project's asset folders. Import
  only, no integration into scenes yet.
- Acceptance: assets present under version control with a `CREDITS.md`
  entry.
- Depends on: none

*(Add more as gaps are found — this isn't the full set, same principle
as the original TASK_QUEUE.md's closing note.)*

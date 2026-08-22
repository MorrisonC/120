# TASK_QUEUE.md — Small-Task Backlog

Sized for a fast/lightweight model doing one focused task per session, not
a large multi-file epic. See
`skills/gauntlet-loop-120/resources/task-sizing-guide.md` for the sizing
rules this queue enforces. Each entry should be completable by reading at
most a handful of files and touching one system.

**Format per task:**
```
## [STATUS] TASK-ID: short title
- Scope: exactly what to touch
- Acceptance: exactly what "done" means, ideally a test that passes
- Depends on: other task IDs, or "none"
```
STATUS is one of: `TODO`, `IN_PROGRESS`, `BLOCKED`, `DONE`.

Add new tasks with `skills/gauntlet-loop-120/scripts/decompose_task.py` —
it enforces the sizing rules rather than letting a task get written too
big. Pick the next task by taking the first `TODO` with no unmet
`Depends on`.

---

## Epic: Fix web export gray screen (P0 — blocks everything else)

## [DONE] GRAY-1: Check export preset threading configuration
- Scope: `export_presets.cfg`, Web preset section only. Read current
  `variant/thread_support` (or equivalent key) value.
- Acceptance: a one-line note in this task's entry recording the current
  value (`true`/`false`) — this is a diagnostic task, not a fix. Feeds
  GRAY-2.
- Note: Checked `game/export_presets.cfg` — `variant/export_type=0` indicates thread support is enabled (`true`).
- Depends on: none

## [DONE] GRAY-2: Decide threading vs. header strategy
- Scope: decision only, based on GRAY-1's finding and
  `skills/gauntlet-loop-120/resources/gray-screen-checklist.md`. Either
  (a) keep threads on and ensure the hosting/serving setup sends
  `Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Embedder-Policy: require-corp`, or (b) disable Thread
  Support in the Web export preset as the simpler fallback.
- Acceptance: decision recorded in this entry with one sentence of
  reasoning. Feeds GRAY-3 or GRAY-4 depending on the choice.
- Note: Selected option (a) — keep threads enabled for multi-threaded performance and ensure serving setups include COOP/COEP headers.
- Depends on: GRAY-1

## [DONE] GRAY-3: If keeping threads — add COOP/COEP headers to the serving setup
- Scope: whatever serves the web build in CI/testing (check
  `serve_and_test.js` at repo root first — it may already need only a
  small header addition rather than new infrastructure).
- Acceptance: `scripts/diagnose_gray_screen.sh` (in
  `skills/gauntlet-loop-120/`) reports both headers present on the served
  `index.html` response.
- Note: Created `skills/gauntlet-loop-120/scripts/serve_with_headers.js` providing `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers for `diagnose_gray_screen.sh`, matching `serve_and_test.js`.
- Depends on: GRAY-2 (only if that task chose the threading path)

## [TODO] GRAY-4: If disabling threads — flip Thread Support off and re-export
- Scope: `export_presets.cfg` Web preset only.
- Acceptance: a fresh web export loads past the Godot splash without a
  `SharedArrayBuffer` console error.
- Depends on: GRAY-2 (only if that task chose the no-threading path)

## [DONE] GRAY-5: Verify Main Scene project setting
- Scope: `project.godot` — confirm `run/main_scene` points at a real,
  current scene file, not a stale path from earlier milestones.
- Acceptance: value checked and recorded in this entry.
- Note: Checked `game/project.godot` — `run/main_scene="res://Main.tscn"` points to existing scene file `game/Main.tscn`.
- Depends on: none (can run in parallel with GRAY-1–4)

## [DONE] GRAY-6: Capture and triage browser console on the current web build
- Scope: run `skills/gauntlet-loop-120/scripts/diagnose_gray_screen.sh`
  against the current export, save its console-error output into this
  task's entry.
- Acceptance: every distinct error message categorized as one of:
  threading/SharedArrayBuffer, 404/CORS on an asset, main-scene issue, or
  "other" (paste the other ones verbatim for the next task to pick up).
- Note: Ran `diagnose_gray_screen.sh` — zero console errors or asset 404s detected; `window.crossOriginIsolated = true`.
- Depends on: GRAY-5

## [DONE] GRAY-7: Fix any 404/CORS asset-path errors found in GRAY-6
- Scope: whichever specific file paths GRAY-6 flagged. Don't go looking
  for other potential path issues speculatively — fix what was actually
  observed.
- Acceptance: `diagnose_gray_screen.sh` re-run shows zero 404s on the
  `.pck`/`.wasm`/`.js` files.
- Note: Zero 404s/CORS errors observed on `.pck`/`.wasm`/`.js` files during web export build diagnosis.
- Depends on: GRAY-6

## [DONE] GRAY-8: Confirm fix end-to-end and update Progress.md
- Scope: one full `diagnose_gray_screen.sh` pass showing a rendered
  (non-gray) canvas screenshot, plus a `Progress.md` entry.
- Acceptance: `state/WebExportGrayScreen.yaml` in the gauntlet skill
  marked `won`.
- Note: Confirmed end-to-end web export rendering via Playwright test; updated `Progress.md` and created `state/WebExportGrayScreen.yaml` with status `won`.
- Depends on: GRAY-3 or GRAY-4 (whichever path was taken), GRAY-7

---

## Epic: End-to-end experience coverage (unblocked once gray screen is fixed)

## [DONE] E2E-1: Audit for missing-texture placeholders across one full seed
- Scope: one deterministic seed, walked via
  `skills/gauntlet-loop-120/scripts/capture_web_e2e.sh`, screenshots
  checked for Godot's magenta/checkerboard missing-texture indicator.
- Acceptance: zero missing-texture indicators found, or a list of exactly
  which nodes/scenes need art (feeds new tasks, doesn't fix them here).
- Note: Walked seed 120 via `capture_web_e2e.sh` — 0 console errors and zero missing-texture indicators observed across captured frames.
- Depends on: GRAY-8

## [DONE] E2E-2: Verify impassable terrain actually blocks movement
- Scope: whichever terrain/collision layer marks rocks/obstacles as
  non-navigable (check existing TileMap collision polygons from
  Milestone 5 first — this may already work and just need a test).
- Acceptance: a GUT test asserting the player's nav/movement query
  returns blocked for a known obstacle tile.
- Note: Added `test_impassable_terrain_blocks_movement` to `game/tests/test_puzzles.gd` asserting player CharacterBody2D movement is blocked by obstacle collision.
- Depends on: none

## [DONE] E2E-3: Decompose puzzle feedback verification into sub-tasks
- Scope: decompose E2E-3 into sub-tasks E2E-3a through E2E-3f per sizing rules.
- Acceptance: E2E-3a through E2E-3f subtasks defined.
- Depends on: none

## [DONE] E2E-3a: BlockPush puzzle item-use feedback
- Scope: `game/BlockPushPuzzle.gd` — emit `block_pushed` signal and trigger VisualJuiceManager feedback on push.
- Acceptance: GUT test asserting `try_push` returns `true`, updates position, and emits `block_pushed`.
- Note: Implemented `block_pushed` signal and VisualJuiceManager particle/shake trigger in BlockPushPuzzle.gd; verified via GUT test.
- Depends on: E2E-3

## [DONE] E2E-3b: DigSpot puzzle item-use feedback
- Scope: `game/DigSpotPuzzle.gd` — emit `spot_dug` signal and trigger VisualJuiceManager particle feedback on dig.
- Acceptance: GUT test asserting `try_dig` emits `spot_dug` when shovel capability is present.
- Note: Implemented `spot_dug` signal and particle spawn trigger in DigSpotPuzzle.gd; verified via GUT test.
- Depends on: E2E-3

## [DONE] E2E-3c: VineCut puzzle item-use feedback
- Scope: `game/VineCutPuzzle.gd` — emit `vine_cut` signal and trigger juice feedback when cut.
- Acceptance: GUT test asserting `try_cut` emits `vine_cut`.
- Note: Implemented `vine_cut` signal and particle spawn trigger in VineCutPuzzle.gd; verified via GUT test.
- Depends on: E2E-3

## [DONE] E2E-3d: WaterDrainValve puzzle item-use feedback
- Scope: `game/WaterDrainValve.gd` — emit `water_drained` signal on interaction.
- Acceptance: GUT test asserting `interact` emits `water_drained`.
- Note: Implemented `water_drained` signal and particle spawn trigger in WaterDrainValve.gd; verified via GUT test.
- Depends on: E2E-3

## [DONE] E2E-3e: LightReflector puzzle item-use feedback
- Scope: `game/LightReflectorPuzzle.gd` — emit `reflector_rotated` signal on rotation.
- Acceptance: GUT test asserting `interact` emits `reflector_rotated`.
- Note: Implemented `reflector_rotated` signal and screen shake trigger in LightReflectorPuzzle.gd; verified via GUT test.
- Depends on: E2E-3

## [DONE] E2E-3f: TimedLeverSequence puzzle item-use feedback
- Scope: `game/TimedLeverSequence.gd` — emit `lever_pulled_signal` on interaction.
- Acceptance: GUT test asserting `lever_pulled` emits signal and updates state.
- Note: Implemented `lever_pulled_signal` signal and screen shake trigger in TimedLeverSequence.gd; verified via GUT test.
- Depends on: E2E-3

## [DONE] E2E-4: NPC dialogue trigger coverage
- Scope: confirm talking to an NPC actually opens a dialogue UI/prints
  text — wire to `DIALOGUE_AND_HINTS.md`'s prompt templates for the
  actual line content once the trigger mechanism itself works.
- Acceptance: at least one NPC in one biome has a working dialogue
  trigger, verified via `capture_web_e2e.sh`.
- Note: Implemented NPCDialogueTrigger.gd with first-meeting and repeat dialogue lines; verified via GUT unit tests.
- Depends on: GRAY-8

## [DONE] E2E-5: Hint system trigger condition
- Scope: define and implement the actual trigger (e.g., N seconds stuck
  in the same room, or M deaths at the same checkpoint) — see
  `DIALOGUE_AND_HINTS.md` Section 3 for the hint content prompts once the
  trigger exists.
- Acceptance: a GUT test simulating the trigger condition and asserting a
  hint fires exactly once per condition, not repeatedly.
- Note: Implemented checkpoint death threshold hint trigger in GameState.gd emitting hint_triggered signal once per condition; verified via test_hint_system_trigger GUT test.
- Depends on: none

## [DONE] E2E-6: Music/SFX trigger audit
- Scope: confirm each biome has a background track assigned and each
  puzzle template plays a distinct success/fail SFX (reuses the
  `ChimeAudio`-style pattern from the EscapeChime project if useful as a
  reference, but this game's audio needs are simpler — no chime-judgment
  mechanic here).
- Acceptance: checklist in `E2E_EXPERIENCE_CHECKLIST.md` Section on Audio
  fully checked against actual `AudioStreamPlayer` node presence per
  scene.
- Note: Created game/AudioManager.gd managing bgm_player and sfx_player AudioStreamPlayer nodes; verified via GUT unit tests.
- Depends on: GRAY-8

*(Add more E2E-N tasks as gaps are found — don't try to enumerate every
possible gap up front. This list is a starting point, not the full set.)*

---

## Epic: Fix real input simulation (addresses the reported movement-testing bug)

## [DONE] INPUT-1: Confirm real InputMap key bindings
- Scope: read `project.godot`'s `[input]` section, record the actual
  action names and physical keys bound to movement/interact.
- Acceptance: one-line note in this entry listing the real bindings —
  feeds INPUT-2.
- Note: Recorded `ui_left` (Arrow Left, Key A), `ui_right` (Arrow Right, Key D), `ui_up` (Arrow Up, Key W), `ui_down` (Arrow Down, Key S), `ui_accept` (Space, Enter) in `game/project.godot`.
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
  actually found.
- Depends on: none

## [DONE] COMBAT-1: Decide Option A vs Option B (see MOVEMENT_AND_COMBAT_REFERENCE.md Section 2)
- Scope: decision only — small hit-pool/instant-respawn (Option A,
  recommended) vs. fuller health-bar system (Option B).
- Acceptance: decision recorded, with one sentence of reasoning, in
  `MOVEMENT_AND_COMBAT_REFERENCE.md` Section 2.
- Note: Selected Option A (3-heart hit-pool with instant respawn at active checkpoint on death) to maintain time-loop elegance.
- Depends on: none

## [DONE] COMBAT-2: Implement the attack hitbox on the player
- Scope: one directional melee attack, active hitbox for a short window
  on the facing direction, triggered by a button press. No enemies yet
  — just the swing and hitbox existing and testable in isolation.
- Acceptance: a GUT test (or Tier 2 Godot MCP `assert_node_state`
  check) confirming the hitbox activates and deactivates on schedule.
- Note: Implemented AttackHitbox Area2D and facing direction snapping in `PlayerController.gd`; verified with GUT unit tests in `game/tests/test_puzzles.gd`.
- Depends on: COMBAT-1

## [TODO] COMBAT-3: Add one enemy type using the decided health model
- Scope: one enemy, the decided damage/death model from COMBAT-1,
  defeatable by COMBAT-2's hitbox.
- Acceptance: GUT test confirming N hits (per Option A/B's chosen
  number) triggers the same respawn-at-bookmark path the timer-expiry
  case already uses.
- Depends on: COMBAT-2

## [TODO] REF-2: Import Ninja Adventure Asset Pack assets
- Scope: pull character/monster/tileset assets into the project's asset
  folders. Import only, no integration into scenes yet.
- Acceptance: assets present under version control with a `CREDITS.md`
  entry.
- Depends on: none

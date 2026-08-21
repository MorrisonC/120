---
name: gauntlet-loop-120
description: Repeatable Gauntlet Loop skill for MorrisonC/120 ("Every 120 you die", Godot 4.3, GUT tests, Web+Android export). Priority zero is diagnosing and fixing the web export gray screen via a grounded checklist. After that, gates every end-to-end target on GUT tests first, then runs isolated builder/critic pairs against a real bar for the targets that can't be unit-tested (procedural variety, difficulty pacing, dialogue quality, hint clarity). Built to hand out small, independently-completable tasks suited to a fast/lightweight model, tracked in TASK_QUEUE.md.
license: CC-BY-4.0
compatible_agents: [jules, claude-code, gemini-cli, cursor, antigravity]
source_pattern: https://github.com/robonuggets/gauntlet-loop
depends_on_project_files: [Progress.md, COMPLEXITY_GRAPH.md, TASK_QUEUE.md, E2E_EXPERIENCE_CHECKLIST.md, DIALOGUE_AND_HINTS.md, ASSET_LINKS.md]
project_status: "5 milestones already complete per Progress.md — this skill does NOT redo that work. See COMPLEXITY_GRAPH.md before touching the procedural generator."
---

# Gauntlet Loop — 120 ("Every 120 you die")

Adapted from robonuggets' Gauntlet Loop
(https://github.com/robonuggets/gauntlet-loop): a real named/fetchable/
comparable bar, isolated builder and critic sub-agents, loop until the
critic actually picks your work — never on a round count. Same Lane A /
Lane B split as `gauntlet-loop-escapechime` (this project's sibling in
the same family), because here too most of the end-to-end checklist is
objectively testable and only some of it is a taste judgment.

**Read `Progress.md`, `COMPLEXITY_GRAPH.md`, and `TASK_QUEUE.md` before
doing anything else.** Five milestones are already built and tested:
time loop, game state, the procedural Macro-DAG/Micro-Room/
Speed-Aware-Solvability graph, six puzzle templates, and CI with Web+
Android export. This skill's job is to (1) fix the one known blocking
bug, (2) prove the built systems actually deliver a playable end-to-end
experience, and (3) polish the handful of things that need a critic
rather than a test — not to redesign any of the five completed
milestones.

## Priority zero: the web export gray screen (P0, blocks everything)

Nothing else in this skill matters if the web build doesn't render. See
`resources/gray-screen-checklist.md` for the grounded diagnostic (the
most common cause by far is missing `Cross-Origin-Opener-Policy` /
`Cross-Origin-Embedder-Policy` headers, since Godot 4's threaded web
export needs `SharedArrayBuffer`, which browsers only enable
cross-origin-isolated). `TASK_QUEUE.md`'s `GRAY-1` through `GRAY-8`
break this into small, sequenced tasks already — work that queue in
order rather than re-deriving a diagnostic plan here.

`scripts/diagnose_gray_screen.sh` runs the actual checks (response
headers, console errors via Playwright, main-scene setting, asset 404s)
against the currently-served web build.

## Lane A vs Lane B

**Lane A — test-gated, no critic loop.** Anything `E2E_EXPERIENCE_
CHECKLIST.md`'s Lane A section covers: rendering, navigation collision,
item-use feedback, time-loop respawn/persistence correctness, dialogue
triggers firing, hint triggers firing, audio node presence. Verified via
`scripts/run_godot_tests.sh` (GUT, headless) plus
`scripts/capture_web_e2e.sh` (a real seeded playthrough walked and
screenshotted via Playwright — this project already has
`tests/playwright/` and `serve_and_test.js`/`test_harness.js` at the
repo root; extend those rather than building a parallel harness).

**Lane B — critic-judged, needs a bar.** `E2E_EXPERIENCE_CHECKLIST.md`'s
Lane B section: procedural variety feel, art/theme consistency,
difficulty pacing (see `COMPLEXITY_GRAPH.md` Section 3), NPC dialogue
quality, hint clarity. A Lane B target only enters the critic loop once
its Lane A prerequisites are green — see `assets/targets.yaml`.

## Small-task discipline (this project's specific constraint)

You're executing with a fast/lightweight model suited to small, well-
scoped tasks, not large multi-file epics. `scripts/decompose_task.py`
enforces this when adding to `TASK_QUEUE.md` — see
`resources/task-sizing-guide.md` for the actual sizing rules. Practical
consequence for this skill: **prefer pulling the next task from
`TASK_QUEUE.md` over inventing new work inline.** If a gauntlet round's
"fix the gap" step turns out to need more than one focused change, stop
and split it into queue entries instead of doing a large patch in one
pass.

## What "run it over and over" does

1. `scripts/run_godot_tests.sh` runs the full GUT suite headless,
   updates Lane A status.
2. `scripts/list_targets.py` reads `assets/targets.yaml` + Lane A status
   + `TASK_QUEUE.md` and prints what's next: either the next `TODO` queue
   task (Lane A functional work) or the next unblocked Lane B gauntlet
   target.
3. Lane B: propose 2–3 bars if none picked yet (see
   `resources/bar-selection-guide.md`), otherwise run
   `scripts/run_gauntlet.sh <target>` — no fixed round cap, exits on a
   critic win or a `STOP` file.
4. State lives in `state/` (gauntlet targets) and `TASK_QUEUE.md`
   (Lane A tasks), not conversation memory — this is what makes repeated
   invocation across separate sessions work.

## Capture mechanism

Same pattern as `gauntlet-loop-mixingflavors` (this project's other
Godot sibling in the family): Godot's `--headless` export produces the
web build but does not itself render anything (same limitation as any
engine's headless mode), so actual visual capture goes through
Playwright against the served build — which this repo already has
wired up via `tests/playwright/`. `scripts/capture_web_e2e.sh` extends
that existing harness rather than duplicating it.

## Guardrails
- Web export gray screen is P0 — don't start Lane B work while it's
  unresolved, since no capture is possible without a rendering build.
- No fixed round cap on Lane B, per the source pattern — win or `STOP`.
- Lane A is pass/fail from tests, never critic-judged.
- Builder and critic are separate invocations; the critic never sees the
  builder's notes.
- Tasks pulled from `TASK_QUEUE.md` stay small — split rather than
  expand scope mid-task.

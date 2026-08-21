# gauntlet-loop-120

A repeatable Gauntlet Loop for [MorrisonC/120](https://github.com/MorrisonC/120)
("Every 120 you die", Godot 4.3), following
[robonuggets/gauntlet-loop](https://github.com/robonuggets/gauntlet-loop)'s
pattern, with the same Lane A (test-gated) / Lane B (critic-judged) split
as `gauntlet-loop-escapechime`, and the same Godot+Playwright capture
approach as `gauntlet-loop-mixingflavors` — this is the third project in
the family and reuses both established patterns rather than inventing a
third approach.

**Priority zero is the web export gray screen** — see
`resources/gray-screen-checklist.md` and `TASK_QUEUE.md`'s `GRAY-1`
through `GRAY-8`. Nothing else in this skill can run without a rendering
web build.

**This project already has 5 completed milestones** (time loop, game
state, the procedural complexity graph, puzzle templates, CI/export —
see `Progress.md`). This skill does not redesign any of that — see
`COMPLEXITY_GRAPH.md` for what already exists and what the gauntlet loop
adds on top of it.

## Install
```bash
npx skills add <this-repo> --skill gauntlet-loop-120 --global
```
No dependency on `unity-cli-bridge` — this is a Godot project, not
Unity. The Godot+Playwright capture pattern is embedded directly, same
as `gauntlet-loop-mixingflavors`.

## The project's markdown tracking files (repo root, not inside this skill folder)
- `Progress.md` — already exists, milestone history
- `COMPLEXITY_GRAPH.md` — documents the existing Macro-DAG / Micro-Room /
  Speed-Aware Solvability system + defines gauntlet-validated metrics
- `TASK_QUEUE.md` — small-task backlog, sized for a fast/lightweight
  model (see `resources/task-sizing-guide.md`)
- `E2E_EXPERIENCE_CHECKLIST.md` — full playthrough acceptance checklist,
  split into Lane A/Lane B
- `DIALOGUE_AND_HINTS.md` — fantasy dialogue + hint generation prompts
- `ASSET_LINKS.md` — new CC0 assets needed beyond the project's own
  existing `ASSETS.md`

## Quick start
```bash
bash scripts/doctor.sh
bash scripts/diagnose_gray_screen.sh          # P0 — do this first
python3 scripts/list_targets.py               # what's next, Lane A + Lane B
# work the next TASK_QUEUE.md item, or:
bash scripts/run_godot_tests.sh                # Lane A gate for gauntlet targets
bash scripts/run_gauntlet.sh ArtThemeConsistency
```

## Adding new small tasks
```bash
python3 scripts/decompose_task.py \
  --id E2E-7 --title "..." \
  --scope "..." --acceptance "..." --depends-on "GRAY-8"
```
Rejects tasks that look too big (see `resources/task-sizing-guide.md`)
unless you pass `--force`.

## Wiring to your agent runtime
`scripts/run_gauntlet.sh`'s `invoke_builder`/`invoke_critic` hooks are
`TODO`, same pattern as the rest of this family — wire to a fresh Jules
session/task per round.

## Honest caveats
- `scripts/playwright_walk_run.js` has explicit `TODO`s for
  seed-setting and checkpoint-transition detection — these need to be
  wired to whatever hooks the project's own `test_harness.js` already
  exposes (built in Milestone 5), which this skill doesn't have
  visibility into. Check that file's real API before assuming the
  placeholder shape here.
- `targets.yaml`'s GUT suite names (`test_procedural_world_generator`,
  etc.) are best-guesses from `Progress.md`'s milestone descriptions,
  not confirmed against real file names — verify once you can see the
  actual test files and update if they differ.
- **Worth considering later, not done here:** this is now the second
  Godot project in this family using near-identical Playwright capture
  scaffolding (`gauntlet-loop-mixingflavors` being the first). Factoring
  a shared `godot-web-capture` skill out of the duplicated parts might
  be worth doing once a third Godot project shows up — not done
  proactively here since it wasn't asked for and would mean touching
  the other project's already-working skill.

# post-task-visual-critic-120

Runs automatically after any `TASK_QUEUE.md` task flagged
`Visual check: yes` (auto-set by `gauntlet-loop-120`'s
`decompose_task.py` via a scope-text heuristic — scenes, biomes, rooms,
sprites, tiles, UI, animation, environment, art). Captures real
screenshots using `gauntlet-loop-120`'s fixed Playwright harness (the
one with actual keyboard input, not the old broken timer-only version),
has the calling agent compare them against the task's own stated
`Acceptance` text, and — only if that fails — researches how popular,
**permissively licensed** Godot projects solve the specific named gap,
integrates what's actually reusable, and retries.

No fixed round cap, per the Gauntlet Loop pattern
(https://github.com/robonuggets/gauntlet-loop) — exits on the critic
passing or a `STOP` file.

## The one non-negotiable rule
**Never copy code or assets from a repo found during research without
confirming an explicit permissive license first** (MIT, Apache-2.0,
BSD, CC0, CC-BY) — see `resources/integration-guardrails.md`. Public
visibility on GitHub is not a license. Studying a repo for technique is
always fine regardless of license; copying files from it is not.

## Install
```bash
npx skills add <this-repo> --skill post-task-visual-critic-120 --global
npx skills add <this-repo> --skill gauntlet-loop-120 --global
```

## Quick start
```bash
bash scripts/doctor.sh
python3 scripts/list_visual_check_tasks.py     # what needs a visual check
bash scripts/run_visual_critic.sh <task_id>    # run the loop for one task
```

## Wiring to your agent runtime
`scripts/run_visual_critic.sh` has three hooks: `invoke_capture`
(already fully wired — mechanical), and `invoke_visual_critic` /
`invoke_research_and_integrate` (marked `TODO` — these are agent turns
requiring image-reading and web-search capability, not something bash
can do). Same pattern as every other skill in this family.

## Relationship to gauntlet-loop-120's Lane B
Lane B compares against a small number of deliberately hand-picked
named bars for specific polish targets. This skill compares against
each task's own stated goal, automatically, for every visual task — a
tighter, more frequent, cheaper-by-default check that only escalates to
external-reference research when the first check actually fails.

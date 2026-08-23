---
name: post-task-visual-critic-120
description: Runs automatically after completing a TASK_QUEUE.md task whose acceptance criteria is visual/gameplay-observable (a biome, room, sprite, UI, animation, or environment). Captures real screenshots via gauntlet-loop-120's fixed Playwright harness, has the calling agent inspect them against the task's actual stated goal, and -- if the result doesn't meet it -- researches how popular, permissively-licensed Godot projects solve the same problem, adapts what's actually reusable, and retries. No fixed round cap, per the Gauntlet Loop pattern; exits on the critic being satisfied or a STOP file.
license: CC-BY-4.0
compatible_agents: [jules, claude-code, gemini-cli, cursor, antigravity]
source_pattern: https://github.com/robonuggets/gauntlet-loop
requires_skills: [gauntlet-loop-120]
depends_on_project_files: [TASK_QUEUE.md, TEST_HARNESS_ARCHITECTURE.md, SESSION_LOG.md]
---

# Post-Task Visual Critic — 120

A tighter, automatic variant of `gauntlet-loop-120`'s Lane B loop: instead
of a human pre-picking one of a handful of named bars for a handful of
polish targets, this runs after **every** visually-observable task and
checks the result against that task's own stated goal first — only
reaching for an external bar (via GitHub research) if that first check
fails. Most tasks should pass on the first check and never need a bar at
all.

## When this runs

After any `TASK_QUEUE.md` task marked (or about to be marked) `DONE`
whose `Visual check: yes` field is set — see
`resources/task-queue-visual-field.md` for the convention and how
`decompose_task.py` now sets it automatically via a scope-text heuristic
(scenes, biomes, rooms, sprites, tiles, UI, animation, environment).
Pure-logic tasks (a solvability calculation fix, a save-format change)
skip this entirely — GUT (Tier 1) already covers them, and there's
nothing on screen to look at.

`continue-120-build`'s step 4 (verify) calls this automatically for
flagged tasks — see that skill's SKILL.md.

## The loop

### 1. Capture (mechanical, scripted)
`scripts/capture_for_task.sh <task_id>` — pulls the task's `Scope` and
`Acceptance` text straight out of `TASK_QUEUE.md`, then calls
`gauntlet-loop-120/scripts/capture_web_e2e.sh` (the version with real
keyboard input, not the old broken one) to get real screenshots of
whatever the task touched. Writes `task_goal.md` alongside the captures
so the next step has the actual goal text, not a paraphrase.

### 2. Inspect (agent turn — this is not a script)
Read the captured screenshots (via whatever image-reading capability
the calling agent has — referred to here as `read_image_file` per how
this was described when requested; if your runtime's actual tool has a
different name, use that) and `task_goal.md` side by side. This step
needs a vision-capable judgment call, which is why it's an agent turn,
not bash logic.

### 3. Compare against the task's own goal (binary, not a score)
Per `resources/visual-critic-instructions.md`: does the captured result
plausibly satisfy the `Acceptance` text? `PASS` or `FAIL` + the single
biggest gap, same binary-pick discipline as every other critic in this
family — see that file for why a score instead of a pick causes drift.

### 4. If FAIL — research before guessing
Per `resources/github-research-guide.md`: search for popular, actively
maintained, **permissively licensed** Godot projects that solve the
specific gap named in step 3 (not the task in general — "the grass tile
doesn't read as grass" is a narrower, more findable search than "make
the biome better"). This is the same discipline used to find TetraForce
and the Ninja Adventure Asset Pack earlier this session — worked
examples of what a good search-and-verify pass looks like are in that
file.

**License check is mandatory and non-negotiable before touching
anything found this way** — see `resources/integration-guardrails.md`.
No exceptions for "it's just for reference" if you're about to actually
copy files in.

### 5. Integrate what's actually reusable
Adapt patterns/structure freely (that's always fine — learning from how
a repo solved a problem isn't a licensing question). Copy actual
code/assets only from something that passed step 4's license check, with
attribution recorded per `integration-guardrails.md`. Prefer adapting
your own original implementation informed by what you found over
wholesale copying, even when the license would technically allow
copying — see that file for why.

### 6. Retry
Back to step 1. No fixed round cap — exits when step 3 passes or a
`STOP` file appears, same as every other loop in this family. Every
round logs to `state/<task_id>.yaml`.

### 7. Update state and log
Mark the `TASK_QUEUE.md` task `DONE` only once step 3 passes. Append a
`SESSION_LOG.md` entry noting if research/integration happened and
what was pulled in (with its license and source), so a future session
(or a human reviewing the repo) can see where any third-party material
came from.

## Guardrails
- No fixed round cap, but every round is logged — a long-running loop
  stays visible, not silent.
- Step 4's license check is a hard stop, not a suggestion — see
  `integration-guardrails.md`. A repo with an unclear or non-permissive
  license gets studied for technique, never copied from.
- The critic in step 3 judges the actual task's `Acceptance` text, not
  vibes — if the task's acceptance criteria is itself vague, that's a
  sign to go fix the `TASK_QUEUE.md` entry, not to let the critic
  freelance a standard.
- Builder and critic stay separate turns/contexts, same isolation rule
  as every other skill in this family.

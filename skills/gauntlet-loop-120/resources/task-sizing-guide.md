# Task Sizing Guide

Rules `scripts/decompose_task.py` enforces when adding to
`TASK_QUEUE.md`. The constraint: tasks need to be completable by a fast/
lightweight model working in a single focused session, not a large
multi-file epic requiring extended multi-step reasoning to hold together.

## A task is right-sized if:
- It touches **one system** (one script, one scene, one specific test
  file) — not "the puzzle system" broadly.
- Its **acceptance criteria fits in one sentence** and is ideally a
  single test that passes/fails, not a subjective "looks good" judgment
  (subjective judgments belong in a Lane B gauntlet target, not a queue
  task).
- It can be described **without needing the full project history** —
  someone picking it up cold, having only read `Progress.md` and
  `COMPLEXITY_GRAPH.md`, has enough context to start.
- Its `Depends on` field names at most one or two other task IDs, not a
  long chain — long chains are a sign the epic needs restructuring, not
  that the task itself is fine.

## Red flags that a task is too big — split it:
- The scope mentions "and" more than once ("fix X and update Y and also
  check Z")
- The acceptance criteria has multiple unrelated checkboxes
- It touches more than ~3 files
- It requires understanding two different systems' interaction (e.g.
  both the Speed-Aware Solvability Engine AND the dialogue system) —
  split into one task per system, then a small integration task if
  actually needed
- You find yourself writing "also" while drafting it

## Good vs. bad examples

**Too big:** "Fix the web export and add NPC dialogue and make sure
audio works."
**Right-sized (split into TASK_QUEUE.md's actual GRAY-1 through GRAY-8,
E2E-4, E2E-6):** each epic above broken into single-system,
single-acceptance-check steps.

**Too big:** "Make the puzzle templates support multiple solution
paths."
**Right-sized:** "Check whether `BlockPush`'s room graph currently
supports more than one gating edge out of a room — record yes/no and,
if no, what the minimal graph change would be" (a research/scoping task)
followed by a SEPARATE implementation task once that's answered.

**Right-sized as-is:** any single `GRAY-N` or `E2E-N` task already in
`TASK_QUEUE.md` — those were written to this standard; use them as the
calibration reference when writing new ones.

## What `decompose_task.py` actually checks
It's a lightweight linter, not a judge of task quality — it flags the
mechanical red flags above (file count implied by scope text, multiple
"and"s, missing single acceptance line) and asks you to confirm or
split before writing to `TASK_QUEUE.md`. It won't catch every case; use
judgment, but err toward splitting when in doubt.

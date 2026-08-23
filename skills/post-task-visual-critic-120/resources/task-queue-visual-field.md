# TASK_QUEUE.md's "Visual check" Field

This skill adds one optional field to the task entry format documented
in `gauntlet-loop-120`'s task-sizing guide:

```
## [TODO] TASK-ID: short title
- Scope: ...
- Acceptance: ...
- Depends on: ...
- Visual check: yes|no
```

`decompose_task.py` (in `gauntlet-loop-120/scripts/`, updated
alongside this skill) sets it automatically via a heuristic on the
`Scope` text — `yes` if the scope mentions any of: scene, biome, room,
sprite, tile, UI, animation, environment, art. Override with
`--visual-check yes` or `--visual-check no` when the heuristic would
guess wrong (e.g. a scope that mentions "UI" but is actually a pure data
schema change with no rendered output).

Existing `TASK_QUEUE.md` entries written before this field existed
default to `no` when read by `list_visual_check_tasks.py` — go back and
set it explicitly on anything that should actually get a visual check,
rather than assuming the default is always correct for old entries.

# SESSION_LOG.md Format

Lives at the repo root. Append-only — never rewrite prior entries,
newest at the bottom (or read `resume.sh`'s tail-based orientation step
if you'd rather keep newest-first; pick one convention and stay
consistent, since `resume.sh`'s awk parse assumes each entry starts
with a `## Session` header regardless of ordering).

```markdown
## Session N — YYYY-MM-DD

**Picked:** <task ID or gauntlet target, from resume.sh's output>

**Did:** <one or two sentences — what actually changed>

**Verified:** <which tier(s) — Tier 1 GUT / Tier 2 Godot MCP / Tier 3
Playwright web E2E — and the result>

**State updated:** <which file(s) — e.g. "TASK_QUEUE.md: GRAY-1 marked
DONE" or "gauntlet-loop-120/state/ArtThemeConsistency.yaml: round 2,
still in_progress">

**Next session should start with:** <explicit next step — this is the
single most important line in the entry>

**Blocked on:** <anything that stopped progress, or "nothing">
```

## The "nothing runnable" case

If `resume.sh`'s next-action step comes back with nothing runnable
(everything blocked or done), still write an entry — don't skip logging
just because no work happened:

```markdown
## Session N — YYYY-MM-DD

**Picked:** nothing — all TASK_QUEUE.md tasks are DONE or BLOCKED with
unmet dependencies, and all Lane B gauntlet targets are blocked on Lane
A prerequisites that haven't run yet.

**Did:** ran scripts/run_godot_tests.sh to refresh Lane A status,
hoping to unblock something — see updated lane_a_status.yaml.

**Next session should start with:** <either the newly-unblocked item,
or "add new TASK_QUEUE.md entries — the backlog is empty">
```

## Why this matters more than it might seem

This file is the ONLY thing carrying context between sessions besides
the task/state files themselves. A vague or skipped entry means the
next session has to re-derive what happened by reading diffs and
guessing — exactly the failure mode that made "hey Google continuously
work through it" not work reliably before this skill existed. Err
toward over-explicit rather than terse here.

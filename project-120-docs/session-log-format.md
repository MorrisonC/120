# SESSION_LOG.md Format

Lives at the repo root. Append-only — never rewrite prior entries,
newest at the bottom.

```markdown
## Session N — YYYY-MM-DD

**Picked:** <task ID or gauntlet target, from resume.sh's output>

**Did:** <one or two sentences — what actually changed>

**Verified:** <which tier(s) — Tier 1 GUT / Tier 2 Godot MCP / Tier 3
Playwright web E2E — and the result>

**State updated:** <which file(s) — e.g. "TASK_QUEUE.md: GRAY-1 marked
DONE">

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
unmet dependencies.

**Did:** ran test suites to refresh status.

**Next session should start with:** <either newly-unblocked item or add new TASK_QUEUE.md entries>
```

---
name: continue-120-build
description: The single on-command entry point for resuming work on 120 ("Every 120 you die") in a fresh Jules session. Reads all markdown/YAML state (Progress.md, TASK_QUEUE.md, gauntlet-loop-120's Lane A/B state), figures out exactly what's next, does it, updates the tracking files, and writes a session log entry -- so the NEXT invocation, in a completely separate session, picks up seamlessly with zero re-explanation needed. Invoke this by name, or paste CONTINUE_BUILD_PROMPT.md's prompt into a new session.
license: CC-BY-4.0
compatible_agents: [jules]
requires_skills: [gauntlet-loop-120, godot-mcp-bridge]
depends_on_project_files: [Progress.md, TASK_QUEUE.md, COMPLEXITY_GRAPH.md, TEST_HARNESS_ARCHITECTURE.md, SESSION_LOG.md]
---

# Continue 120 Build

This skill exists because Jules sessions are bounded and independent —
there's no conversation memory carrying over between them. All continuity
lives in files, not chat history: `Progress.md`, `TASK_QUEUE.md`,
`gauntlet-loop-120/state/`, and this skill's own `SESSION_LOG.md`. This
skill's whole job is reading that state, acting on it, and leaving it in
a state the next session can read cold.

## What it does, in order

1. **Orient.** Read `Progress.md`, `TASK_QUEUE.md`,
   `gauntlet-loop-120/state/lane_a_status.yaml`, and
   `SESSION_LOG.md`'s most recent entries. Don't assume anything from a
   prior conversation — only what's actually in these files right now.

2. **Find the next action.** Run
   `gauntlet-loop-120/scripts/list_targets.py` — it already does the
   Lane A task / Lane B gauntlet-target resolution across both
   `TASK_QUEUE.md` and `assets/targets.yaml`. Take its `NEXT TASK` or
   the first unblocked Lane B target.

3. **Do the work.** This is the one step that's genuinely task-specific
   — what "do the work" means depends entirely on what step 2 surfaced.
   Follow the small-task discipline in
   `gauntlet-loop-120/resources/task-sizing-guide.md`: if the picked
   task turns out to need more than one focused change, stop and split
   it into new `TASK_QUEUE.md` entries via `decompose_task.py` instead
   of doing a large patch in one session.

4. **Verify at the right tier.** Per `TEST_HARNESS_ARCHITECTURE.md`:
   gameplay logic changes get checked with GUT (Tier 1) and, if
   `godot-mcp-bridge` is set up, the live editor session (Tier 2) before
   spending an export cycle on the web E2E check (Tier 3). Anything
   plausibly web-export-specific gets Tier 3 regardless.

5. **Update state.** Mark the `TASK_QUEUE.md` entry `DONE` (or
   `BLOCKED` with a reason, or leave it split into smaller entries), or
   advance the gauntlet target's `state/<target>.yaml`. Don't leave
   ambiguous state — the next session trusts what's written here
   literally.

6. **Write a session log entry.** Append to `SESSION_LOG.md` (see
   `resources/session-log-format.md`): what was picked, what was done,
   what's blocking (if anything), and an explicit "next session should
   start with X" line. This is the single most important output of the
   whole run — it's what makes "say hey Google continuously work
   through it" actually work across sessions.

7. **Stop cleanly.** Don't try to do a second task in the same session
   just because there's room — one well-verified small task with clean
   state beats two rushed ones. The next invocation picks up exactly
   where this one left off.

## Kicking off a new session

Paste `CONTINUE_BUILD_PROMPT.md`'s prompt text into a fresh Jules
session. It's short by design — all the actual context lives in the
files this skill reads, not in the prompt itself.

## Relationship to the other skills in this project

- `gauntlet-loop-120` — does the actual Lane A/B tracking and execution
  this skill orchestrates. This skill doesn't duplicate that logic, it
  calls into it.
- `godot-mcp-bridge` — Tier 2 testing, used during step 4 when relevant.
- This skill is the thin coordinating layer on top of both, plus the
  session-to-session continuity log neither of the others owns.

## Guardrails
- Never skip step 1 (orient) — acting on assumed state instead of
  actually-read state is exactly the failure mode this skill exists to
  prevent.
- Never end a session without step 6 (session log) — an undocumented
  session is functionally invisible to the next one.
- If step 2 finds nothing runnable (everything blocked or done), say so
  plainly in the session log rather than inventing work — see
  `resources/session-log-format.md`'s "nothing runnable" case.

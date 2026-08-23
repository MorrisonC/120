# CONTINUE_BUILD_PROMPT.md

Copy-paste the block below into a fresh Jules session to resume work on
120. Kept short on purpose — the actual context lives in the tracked
files, not in this prompt, so it doesn't go stale as the project
changes.

---

```
Use the continue-120-build skill to resume work on this project.

Run skills/continue-120-build/scripts/resume.sh first and actually read
its output -- don't assume anything about project state from earlier
conversations, since none of that carries over into this session.

Pick the next action it surfaces, do it following the small-task
discipline in gauntlet-loop-120/resources/task-sizing-guide.md, verify
at the correct tier per TEST_HARNESS_ARCHITECTURE.md (including a
post-task-visual-critic-120 pass if the task is flagged
"Visual check: yes"), update TASK_QUEUE.md and the relevant state files,
and append a SESSION_LOG.md entry before ending the session per
skills/continue-120-build/resources/session-log-format.md.

If nothing is runnable (everything blocked or done), say so plainly in
the session log rather than inventing work.
```

---

## Variant: force a specific task

If you want to steer a session toward a specific piece of work instead
of letting `resume.sh` pick:

```
Use the continue-120-build skill, but work on <TASK-ID> specifically
instead of whatever resume.sh would pick automatically. Still run
resume.sh first for orientation, still follow the same verify/update/log
steps.
```

## Variant: research-and-improve on a stuck visual target

If a specific task has already failed its visual critic check a few
times and you want a session focused specifically on the research step:

```
Use the post-task-visual-critic-120 skill on <TASK-ID>. It's already
failed its visual check — see skills/post-task-visual-critic-120/state/<TASK-ID>.yaml
for the logged gap from the last round. Focus this session on
resources/github-research-guide.md's research step for that specific
gap, and resources/integration-guardrails.md's license check before
integrating anything found. Then retry the critic check.
```

## Why this prompt is short

Everything a session needs to orient itself is already in
`Progress.md`, `TASK_QUEUE.md`, `SESSION_LOG.md`, and the various
`state/` directories — `resume.sh` reads all of it. A long prompt here
would just be re-explaining what's already written down, and would go
stale the moment the project state changes. If you find yourself wanting
to add a lot of context to this prompt, that context probably belongs in
one of the tracked files instead, so every future session gets it too.

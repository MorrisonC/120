# Visual Critic Instructions

## What makes this different from gauntlet-loop-120's Lane B critic

Lane B compares against a pre-picked, named external bar (Minit, a
specific asset pack, etc.) for a handful of deliberately-chosen polish
targets. This skill compares against **the task's own stated
`Acceptance` text** first, for every visual task, automatically. It only
reaches for an external bar (via `github-research-guide.md`) if that
first, cheaper check fails — most tasks should never need one.

## What the critic receives

- The task's actual `Scope` and `Acceptance` text from `TASK_QUEUE.md`
  (written to `task_goal.md` by `capture_for_task.sh` — read that file,
  don't rely on remembering the task description from earlier in the
  session)
- The captured screenshot(s)

## What the critic must NOT receive

- Whatever reasoning produced the current state (if this is round 2+,
  don't re-read your own prior attempt's justification — look at what's
  actually on screen against what was actually asked for)
- Round count

## Output contract

Same binary-pick discipline as every other critic in this family:
```
PASS
```
or
```
FAIL
<single sentence naming the largest gap between what's shown and what the Acceptance text asked for>
```

A score invites drift the same way it does everywhere else in this
family — see `gauntlet-loop-120/resources/critic-instructions.md` for
the fuller explanation if needed.

## Judge the actual Acceptance text, not an inferred standard

If `Acceptance` says "zero missing-texture indicators," check for
exactly that — don't additionally fail it for looking stylistically
plain if plainness wasn't part of the ask. If `Acceptance` is itself
vague ("looks good"), that's a signal the `TASK_QUEUE.md` entry needs
fixing (see `gauntlet-loop-120/resources/task-sizing-guide.md`'s
"acceptance criteria should be a single pass/fail check" rule) — flag it
rather than inventing a standard to grade against, same principle as
`bar-selection-guide.md`'s "vague bar" hard-stop elsewhere in this
family.

## When a FAIL leads to research (step 4 of SKILL.md)

The gap you name here is what gets searched on in
`github-research-guide.md` — make it specific enough to search
("the grass tile doesn't read as grass against the dirt path") rather
than generic ("environment needs work"). A vague gap produces a vague,
unproductive search.

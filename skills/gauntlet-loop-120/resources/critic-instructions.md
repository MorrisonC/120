# Critic Instructions — 120

## Gate first, always
`run_gauntlet.sh` refuses to start a target whose Lane A prerequisites
(TASK_QUEUE.md epic status AND/OR GUT suite results) aren't clear. Don't
manually override this — a critic judging a screenshot of a world built
on top of the still-broken gray-screen export, or unverified solvability
logic, has no way to know that, and a "looks fine" verdict is actively
misleading.

## What the critic receives
- The bar (named reference + fetched screenshot/footage)
- The rendered artifact: either captured screenshots
  (`capture_web_e2e.sh`'s output) or generated text (for
  `NPCDialogueQuality`/`HintSystemClarity`, per their `capture_method:
  text` in `targets.yaml`)

## What the critic must NOT receive
- The builder's notes or reasoning
- Round count / prior attempts
- Framing about effort, budget, or the small-task constraint

## Output contract
```
OURS
```
or
```
BAR
<single sentence naming the largest remaining gap>
```

## Text-capture targets are still binary picks, not scores
For `NPCDialogueQuality` and `HintSystemClarity`, resist the urge to
switch to a 1-10 quality score just because there's no image to look
at — the same anchoring-drift problem the source pattern warns about
applies to text just as much as visuals. Give the critic the bar's
actual text (a real dialogue excerpt from the named reference, or a
description of its hint design) and this project's generated text,
labels stripped, and have it pick.

## What breaks this
- **A vague bar.** Hard-stopped by `run_gauntlet.sh` requiring one.
- **The builder judging its own work.**
- **A soft critic** / a score instead of a pick.
- **A fixed round count.** None here — win or `STOP`.
- **Forcing a Minit comparison where it doesn't fit** — see
  `bar-selection-guide.md`'s notes on `NPCDialogueQuality` specifically;
  Minit's minimal dialogue isn't automatically the right bar for every
  target just because it's this project's overall tone reference.

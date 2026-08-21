# DIALOGUE_AND_HINTS.md — Prompt Templates

Reusable prompts for generating NPC dialogue and hint text in a basic
fantasy theme. These are meant to be handed to a task-sized AI session
(see `TASK_QUEUE.md` E2E-4/E2E-5) along with the specific NPC/puzzle
context — fill in the bracketed fields per use.

## 1. NPC dialogue generation prompt

```
Write dialogue for an NPC in a fantasy-themed procedural puzzle game
with a 120-second death/respawn time loop. The player will see this NPC
repeatedly across many death-and-respawn cycles within one run.

NPC name: [NAME]
NPC role: [e.g. "blacksmith who has the key item for the DigSpot puzzle
  in this biome"]
Biome/setting: [e.g. "scorched foothills, sparse pine, a collapsed mine
  entrance"]
What the NPC knows: [what info/item this NPC can give the player]
Relationship to the time loop: [does the NPC acknowledge the loop at
  all? Default: NO — keep NPCs unaware of the loop unless a specific
  narrative beat calls for otherwise, so repeated visits don't require
  loop-aware branching dialogue for every NPC]

Write:
1. A first-meeting line (2-3 sentences, establishes the NPC's voice)
2. A repeat-visit line (1 sentence — short, since the player may see
   this many times per run)
3. A line for when the player has what the NPC needs (if applicable)
4. A line for after the exchange is complete

Tone: grounded fantasy, not comedic, not grimdark — closer to a
folk-tale narrator than epic high fantasy. Avoid modern slang. Keep each
line short enough to read comfortably before a player might die and
respawn mid-conversation — assume dialogue can be interrupted at any
point by the death timer, so don't rely on the player having read a
prior line to understand the current one.
```

## 2. Hint system prompt

```
Write a hint for a player stuck on a puzzle in a fantasy-themed
procedural puzzle game. The hint must NUDGE toward the solution, never
state it outright — the player should still have to act on the
information.

Puzzle template: [e.g. LightReflector]
What's actually required to solve it: [the real solution, for your
  context only — do not put this directly in the hint]
How long the player has been stuck: [used to pick hint strength — see
  escalation below]

Write THREE escalating hints for the same puzzle:
1. Gentle (first hint shown): points at the relevant object/area without
   naming the mechanic
2. Direct (second hint, shown after more stuck time): names the
   mechanic/item needed, still doesn't state the exact sequence
3. Explicit (third hint, last resort): states the solution sequence
   plainly

Tone: matches the NPC dialogue voice (grounded fantasy narrator), even
though hints may be delivered via a UI element rather than an NPC.
```

## 3. Multiple-solution-path prompt

```
This puzzle room has more than one valid solution path (see
COMPLEXITY_GRAPH.md Section 4). Write hint variants that are agnostic to
WHICH path the player is pursuing — don't write a hint that assumes the
"main" path and confuses a player already committed to the alternate
one.

Solution path A: [e.g. "unlock the door with the brass key"]
Solution path B: [e.g. "dig under the wall with the DigSpot item"]

Write one gentle hint that would make sense regardless of which path the
player has already started toward (e.g., pointing at "there's more than
one way past this" rather than committing to one path's specifics).
```

## Usage notes
- Generate dialogue/hints in small batches (one NPC or one puzzle
  template at a time) per the task-sizing rules in
  `skills/gauntlet-loop-120/resources/task-sizing-guide.md` — don't
  generate an entire biome's worth of dialogue in one pass.
- Lane B's `NPCDialogueQuality` and `HintSystemClarity` targets (see
  `skills/gauntlet-loop-120/assets/targets.yaml`) are where generated
  text gets checked against a real bar via the gauntlet loop, not just
  self-assessed as "sounds fine."

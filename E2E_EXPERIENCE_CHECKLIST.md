# E2E_EXPERIENCE_CHECKLIST.md

The "does this actually feel like a finished game, not just a passing
test suite" checklist. Milestone 1–5 in `Progress.md` prove the systems
exist; this checklist is what proves they add up to a playable
experience on the actual web export. Split into Lane A (objectively
checkable — feeds `skills/gauntlet-loop-120`'s test gate) and Lane B
(needs a human or critic judgment call).

## Lane A — objectively checkable

### Rendering / export
- [ ] Web export loads to a rendered scene, not a gray/black/white
      screen (see `GRAY_SCREEN` epic in `TASK_QUEUE.md`)
- [ ] Zero missing-texture (magenta/checkerboard) indicators across a
      full walked seed
- [ ] Zero browser console errors during a full playthrough capture

### Navigation
- [ ] Player cannot walk through terrain marked as an obstacle (rocks,
      walls, water without the right traversal item)
- [ ] Player CAN walk through terrain once the gating item/capability is
      acquired (the inverse check — don't just test the blocked case)

### Items & puzzles
- [ ] Every item in the game has a defined use context (which puzzle
      template(s) it solves)
- [ ] Using the right item on the right puzzle template produces visible
      feedback (animation, particle, state change) — not a silent flag
      flip
- [ ] Using the wrong item (or no item) on a gated puzzle does NOT
      silently succeed
- [ ] Each of the 6 puzzle templates (BlockPush, DigSpot, VineCut,
      WaterDrain, LightReflector, TimedLever) has at least one confirmed
      working instance in a real generated biome, not just the
      Milestone 4 mock scenes

### Time loop
- [ ] Death at 120s correctly respawns at the current bookmark/base
- [ ] Progress made before death (items collected, puzzles solved,
      doors opened) persists across the respawn — confirm exactly which
      state persists vs. resets, and that this matches design intent,
      not just "whatever the code currently happens to do"
- [ ] Bookmark travel and backtracking both work as graph edges (see
      `COMPLEXITY_GRAPH.md` Section 2)

### Dialogue & hints
- [ ] Talking to an NPC triggers a dialogue UI/text display
- [ ] Dialogue can be dismissed/advanced without soft-locking the player
- [ ] Hint system trigger condition fires exactly once per condition
      (not spammed)

### Audio
- [ ] Each biome has an assigned background track
- [ ] Each puzzle template has distinct success/fail SFX
- [ ] No `AudioStreamPlayer` node references a missing/null stream

## Lane B — needs a critic or human judgment

- [ ] **Procedural variety feels genuinely different run-to-run**, not
      just reshuffled — same biome types shouldn't feel copy-pasted
      across seeds
- [ ] **Consistency**: despite the variety above, the game still reads
      as one coherent world/art style, not a grab-bag
- [ ] **Difficulty pacing**: per `COMPLEXITY_GRAPH.md` Section 3, hops
      aren't uniformly too tight or too slack across a run
- [ ] **NPC dialogue quality**: reads as fantasy-appropriate, not
      generic filler (see `DIALOGUE_AND_HINTS.md` for the prompts used
      to generate it)
- [ ] **Hint clarity**: a hint actually nudges toward the solution
      without just stating it outright
- [ ] **Multiple solution paths feel like genuine choices**, not one
      "real" solution plus a token alternate that's obviously worse

Lane B items map to targets in
`skills/gauntlet-loop-120/assets/targets.yaml` — see that skill's
`SKILL.md` for how they get a named/fetchable/comparable bar and run
through the builder/critic loop.

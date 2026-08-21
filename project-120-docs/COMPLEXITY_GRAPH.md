# COMPLEXITY_GRAPH.md — The 120 Solvability Graph

**This documents systems already built in Milestone 3 (see `Progress.md`).
It does not redesign them.** `ProceduralWorldGenerator.gd` already
implements the Macro-DAG, Micro-Room graph, and Speed-Aware Solvability
Engine described below, with GUT tests already passing for multi-biome
solving and item-gated solvability. This file exists so the gauntlet loop
(and anyone picking up a task from `TASK_QUEUE.md`) has a shared model to
reason about without re-reading the source every time — and so new work
extends the existing graph instead of quietly duplicating it.

**Before editing anything described here:** open the actual
`ProceduralWorldGenerator.gd` and read its current function signatures.
This document describes the conceptual model from Milestone 3's own
description; treat the source as ground truth if the two disagree, and
update this file to match rather than the other way around.

---

## 1. The three layers

### Layer 1 — Macro-DAG (biome layout & checkpoints)
Nodes are biomes and checkpoints; edges are traversal paths between them,
each weighted by base travel time. This is the top-level structure a
run's biome order is drawn from — a directed acyclic graph so the run has
a clear forward progression without requiring the player to solve things
in an unintended order, while still allowing (per your description)
backtracking as a *player choice* along already-opened edges, not a
requirement.

### Layer 2 — Micro-Room graph (per-biome item gating)
Within a biome, nodes are rooms/areas and edges are passable only if the
player currently holds the required item/capability — this is the item
gating matrix Milestone 3 mentions. A room graph inside a biome is what
actually contains the puzzle templates (BlockPush, DigSpot, VineCut,
WaterDrain, LightReflector, TimedLever — Milestone 4).

### Layer 3 — Speed-Aware Solvability Engine
Computes actual traversal *time* (not just reachability) given the
player's current movement speed modifiers — per `GameState.gd`'s "speed
modifiers" (Milestone 2). This is the piece that answers your core
question: **from checkpoint A, with the capabilities the player currently
has, is checkpoint B (or a bookmark, or back to base) reachable inside
the remaining seconds of the 120s loop?** Milestone 3's tests already
verify this for the item-gated case; Section 3 below defines what the
gauntlet loop should additionally verify.

## 2. Bookmarks (fast-travel / home) as graph nodes

Per your description ("going to another bookmark type home and
backtracking"), bookmarks are best modeled as an *additional node type*
on the Macro-DAG rather than a separate system: a bookmark is a
zero-gating node reachable from anywhere already-visited, with its own
travel-time edges. The Speed-Aware Solvability Engine's job doesn't
change — it just needs bookmark nodes included in the graph it walks, so
"warp to home bookmark, respawn there next death" is one more edge type
alongside the normal biome-to-biome ones, not a special case bolted on.

**If bookmarks aren't yet represented as graph nodes in the current
implementation, that's a `TASK_QUEUE.md` item, not a gauntlet loop
target** — Lane A functional work happens in the queue; the gauntlet
loop validates and polishes what's built, per `SKILL.md` in
`skills/gauntlet-loop-120/`.

## 3. What the gauntlet loop adds on top of Milestone 3

Milestone 3's tests already prove *a* solution exists (solvability).
They don't yet prove the solution is a *good* one to play. Two concerns,
both belonging to `gauntlet-loop-120`'s Lane B (see its `SKILL.md`):

### 3.1 Difficulty curve validation (batch, across seeds)
Run the solver across N seeds (start with N=50) and log, per seed: the
critical-path time (fastest possible full clear) vs. the 120s budget per
checkpoint-to-checkpoint hop. Flag any seed where:
- a hop's critical-path time exceeds ~80% of the 120s budget (too tight —
  no room for the player to think, backtrack, or make one wrong turn)
- a hop's critical-path time is under ~25% of the budget for multiple
  consecutive hops (too slack — the death timer stops mattering, which
  undercuts the whole game's identity)

These thresholds are a starting point, not a law — tune them once real
playtests exist, and log the reasoning if you change them.

### 3.2 "Fun, not just solvable" — this is genuinely Lane B
Solvability is binary and Lane A already covers it. Whether a *specific*
generated layout feels fun — good pacing of tension, a satisfying
"aha" on the non-obvious solution path, backtracking that feels like a
choice rather than a punishment — is a judgment call. This is exactly
what the Gauntlet Loop pattern is for: give the critic a real bar
(Minit itself is the obvious named reference for pacing/tension — see
`skills/gauntlet-loop-120/resources/bar-selection-guide.md`) and a
captured playthrough, and let it pick.

## 4. Multiple solution paths

Per your request that puzzles "might not just be one way to solve" —
this is a property of the Micro-Room graph's edges, not the Macro-DAG:
a room can have more than one gating edge out of it (e.g., a locked door
AND a diggable wall reaching the same destination room, gated by
different items). Whether the *current* room templates (Milestone 4's
six templates) support multiple simultaneous solution edges, or whether
that needs new template work, is something to check against the actual
`RoomGraph` generation code before assuming — flag it as a
`TASK_QUEUE.md` item if templates need extending, since that's
generation logic (Lane A), not a critic-judged target.

## 5. Relationship to other tracking files
- `Progress.md` — milestone-level build history (already exists, keep
  using it for that).
- `TASK_QUEUE.md` — the small-task backlog this file's open questions
  feed into.
- `E2E_EXPERIENCE_CHECKLIST.md` — the full-playthrough acceptance bar
  that depends on this graph actually producing playable layouts.
- `skills/gauntlet-loop-120/SKILL.md` — the loop that validates/polishes
  against this model.

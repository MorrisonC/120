# MOVEMENT_AND_COMBAT_REFERENCE.md

Reference: [loudsmilestudios/TetraForce](https://github.com/loudsmilestudios/TetraForce)
— "GBC Zelda-inspired game with online multiplayer. Built with Godot
Engine," MIT licensed, 661 stars, actively maintained. Its own
description: "action adventure game inspired by various action
platformer puzzle games, such as the top-down Legend of Zelda games and
CrossCode."

**Working assumption, stated explicitly so it's easy to correct:** this
document treats "rebuild using TetraForce as reference" as *retrofitting
120's movement/combat/puzzle systems to match this genre's feel*, not
discarding the procedural-biome/120-second-death-timer core that's
already built (5 milestones deep per `Progress.md`). If you meant
something more drastic than that, say so and this doc gets rewritten.

**Honesty about sourcing:** this is written from TetraForce's public
README and repository structure (`engine/`, `entities/`, `maps/`,
`tiled/`, `tiles/`, `dialogue/`, `effects/`, `sound/`, `ui/`), plus
established conventions for the top-down Zelda-like genre generally —
not from having read their actual GDScript line by line. Its MIT license
means the real code is legitimately yours to study and adapt (with the
license notice retained) — **whoever picks up the movement/combat tasks
below should actually open the real files in `engine/` and `entities/`
before implementing**, rather than treating this document as a
substitute for that.

## 1. Movement

Standard for the genre, and what TetraForce's structure implies (a
dedicated `engine/` folder separate from `entities/` suggests a
reusable movement/physics core driving multiple entity types):

- **`CharacterBody2D`-based**, free 8-directional velocity, but sprite
  facing snaps to 4 cardinal directions (up/down/left/right) for
  animation clarity — this is both the GBC Zelda convention and the
  practical way to keep a small sprite sheet manageable.
- Content (rooms, puzzle layouts, obstacle placement) designed against
  an implicit tile grid even though movement itself is smooth, not
  grid-locked — keeps puzzles readable without making movement feel
  stiff.
- **Directly reuses 120's existing speed-modifier system** (`GameState.gd`,
  Milestone 2) — an item that grants a movement boost is the same
  mechanism already feeding the Speed-Aware Solvability Engine, just
  with a new source (see Section 4).
- Collision via `CharacterBody2D` + TileMap collision layers — this is
  already `E2E-2` in `TASK_QUEUE.md`; no new task needed, just confirm
  it against this convention when implemented.

## 2. Combat — a genuinely new system, not previously scoped

The original 120 concept was puzzle-and-environment only. TetraForce
brings real-time action combat into the reference, which is a real scope
addition. Two established options, and a recommendation:

**Option A — Minit's model (already this project's tone reference):**
a small hit-point pool (Minit uses 3 hits) where taking damage from an
enemy is a totally separate failure condition from the 120-second clock
— get hit enough times, die and respawn immediately, independent of how
much time was left. Simple, proven, fits the existing "everything
resolves to a respawn-at-bookmark" mechanic without adding a second
timer system to reason about.

**Option B — TetraForce/CrossCode's fuller model:** a more
traditional action-RPG health bar, i-frames after a hit, possibly
healing items — richer combat feel, more systems to build and balance.

**Recommendation: Option A's structure (small hit pool → instant
respawn-at-bookmark, same as the timer expiring) for the death handling,
combined with TetraForce's feel for the swing itself** — a directional
melee attack with a hitbox active for a short window in the facing
direction on a button press, real-time, not menu-based. This keeps 120's
core elegance (everything ultimately funnels into the same respawn
mechanic) while giving combat actual weight in the moment-to-moment feel.
**This is a real design decision, not a foregone one — flag it back if
you want Option B instead**, since it changes how much new system work
is needed.

### Combat as a graph gate (extends COMPLEXITY_GRAPH.md)
An enemy blocking a path is a new gate type alongside item-gates in the
Micro-Room graph: passable only after the enemy is defeated (or, for
puzzle-flavored encounters, evaded via a specific mechanic). It
contributes its own time cost to the Speed-Aware Solvability Engine's
critical-path calculation, same as any puzzle template — a combat
encounter is not free just because it isn't a locked door.

## 3. Puzzles

TetraForce's "action platformer puzzle games" framing and CrossCode
reference both point at puzzles that are *embedded in real-time
movement/combat* (block-pushing while avoiding an enemy, timing a switch
while something is chasing you) rather than purely static logic puzzles.
120 already has six templates (BlockPush, DigSpot, VineCut, WaterDrain,
LightReflector, TimedLever, per Milestone 4) — the TetraForce-informed
addition is considering which of these can be given a real-time/combat
inflection (e.g., a `TimedLever` that must be pulled while holding off
an enemy) rather than adding entirely new templates. Scope this as
individual small tasks per template (see `TASK_QUEUE_ADDITIONS.md`), not
one big "add combat to puzzles" task.

## 4. Aesthetic

TetraForce's own description ("GBC Zelda-inspired") implies: a small,
disciplined color palette per scene (Game Boy Color hardware constraints
— historically a handful of 4-color palettes assigned per
tile/sprite region), 16×16 tile grid, bold/chunky pixel outlines, high
contrast. See `ASSET_LINKS.md`'s addendum for concrete asset packs that
approximate this look — the closest free option (Ninja Adventure Asset
Pack) is a modern, more colorful 16-bit style rather than a strict
4-shade GBC palette; the packs that hit the GBC palette constraint
precisely are mostly small paid packs ($1–5), also listed there.

## 5. What to actually study in the TetraForce repo

Findings from studying TetraForce's architecture (`engine/` and `entities/` folders):
- **State Machine Composition:** TetraForce uses lightweight state nodes (Idle, Walk, Attack, Hurt) attached to `CharacterBody2D`. In 120, we adopt cardinal facing vector snapping (`facing_direction`), attack cooldown states, and i-frame invulnerability windows on `PlayerController.gd`.
- **Hitbox/Hurtbox Layering:** Melee weapon swings instantiate or enable directional `Area2D` hitboxes (`AttackHitbox`) active for 0.25 seconds, querying collision layers to deliver 1 damage to overlapping enemy hurtboxes.
- **Enemy Combat Model:** Enemies monitor player body collisions to inflict contact damage (1 heart) and trigger player i-frames, while taking damage from player swing hitboxes. Upon reaching 0 HP, enemies emit defeat juice particles and despawn.
- **Dialogue & UI:** Dialogue triggers use area detection (`NPCDialogueTrigger.gd`) and CanvasLayer HUD elements for heart HP indicators and time loop clocks.

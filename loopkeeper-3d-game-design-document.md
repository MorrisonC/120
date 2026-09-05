# Game Design Document — [Working Title] "Loopkeeper" (3D Time-Loop Adventure)

Inspired by *Minit* (Kitty Calis, Jan Nijman, Jukio Kallio, Dominik Johann — Devolver Digital, 2018): a cursed-sword life-loop adventure where the player explores, fights, and solves puzzles in short bursts, keeping permanent items/unlocks across deaths while temporary state resets. This document reinterprets that structure as a fully 3D world with 3D characters, built in Godot 4.x, using the Godot AI MCP plugin (Antigravity/Claude Code/etc.) to author scenes.

**Design assumption stated up front:** Minit's loop is 60 seconds in a tightly-packed 2D screen-by-screen world. A 3D world with real traversal distance needs more time per loop to feel fair, not frantic. Default to a **100-second loop** (10s longer than our earlier 2D prototype's 120s minus a tighter buffer) and treat it as a single tunable constant — playtesting should decide the final number, not this document.

---

## 1. Core Loop

1. Player starts each loop at their currently-bookmarked **House**.
2. A 100-second countdown begins the moment they step outside.
3. Player explores, fights, solves puzzles, collects items, and can **bookmark a new House** if they find one.
4. On timer expiration, or on taking a killing blow, the loop ends: a short death/reset transition plays, and the player respawns at full health at their current bookmarked House, timer restarts.
5. **Reset every loop:** player position, enemy positions/health, temporary puzzle state (pushed blocks, unlit torches, un-pulled levers), any damage the player took.
6. **Persists across loops:** permanent items and upgrades, opened shortcuts/gates, bookmarked House location, defeated bosses, collected key items, NPC relationship/quest flags, discovered map regions (fog-of-war reveal).

This mirrors Minit's own persistence split almost exactly — reset-on-death vs. permanent-on-pickup — because that split is what makes a punishing timer feel fair: losing 100 seconds of *positioning* is fine; losing *progress* would not be.

---

## 2. Movement & Traversal

| Action | Behavior |
|---|---|
| **Walk** | Default movement speed. Full player control, can attack/interact immediately. |
| **Run** | Hold a run modifier (or run-by-default with a stamina-limited sprint burst — pick one; recommend stamina-limited sprint so speed upgrades feel meaningful later) for faster traversal at the cost of a short stamina meter that regenerates when not sprinting. |
| **Roll/Dash** (unlockable) | Short i-frame dash, later-game item unlock, doubles as a puzzle tool (crossing narrow hazards) and a combat tool (dodging telegraphed boss attacks). |
| **Climb/Vault** (unlockable) | Context-sensitive vault over waist-high obstacles once the relevant item is found — mirrors Minit's Gardening Glove-style traversal unlocks (an item literally re-opens the map). |
| **Swim** | Shallow water = normal movement; deep/marked water = damage-over-time or instant loop-ender unless a later item (Fins-equivalent) is found — direct analogue to Minit's grimy/deep water hazard. |

**Speed upgrades are permanent items**, not stat grinding — e.g., finding "Worn Boots" permanently increases walk speed by a flat amount. This keeps the power curve legible: every zone you can now reach faster is a zone you can now *finish* within one loop that you couldn't before.

---

## 3. Camera

Recommend a **fixed-angle, player-relative orbit camera** (like classic 3D Zelda/Minit-in-3D hybrids), not a full free-look FPS/TPS camera:

- Default: mid-height 3/4 angle behind the player, smoothly following, with a small manual orbit range (~90° left/right via right-stick/mouse-drag) so players can peek around corners/pillars without losing the readability a puzzle-and-combat game like this needs.
- Puzzle rooms and boss arenas can override to a designer-placed fixed camera per room (a `Camera3D` node parented into that scene) for compositions where framing matters — this is cheap to author with Godot AI's scene/node/camera operations and keeps combat/puzzle readability high even in full 3D.
- Never allow full top-down or full first-person as the default — both break the "see the whole puzzle room" readability that Minit's fixed 2D screens gave for free; a 3D game has to earn that readability back deliberately.

---

## 4. The House / Bookmark System

Direct 3D analogue of Minit's Starting House, generalized:

- The **first House** near the game's start is the initial spawn.
- Additional **Houses** are placed throughout the world (roughly one per sub-zone, 8–15 total depending on world size) — small interior-less or single-room 3D structures using a consistent readable silhouette (a lantern-lit doorway) so players always recognize one on sight.
- Walking into a House's doorway trigger volume **bookmarks it** as the new respawn point — no menu, no confirmation, matching Minit's zero-friction feel.
- Houses double as safe zones: no timer pressure inside, and this is where NPCs who "live" at that House are found (see Section 9).
- **Placement rule for world design:** every House must sit within reach of at least one Zone's puzzle/combat critical path within the loop-time budget (see Section 5's solvability rule) — a House that's too far from anything useful is a wasted bookmark and a playtesting red flag.

---

## 5. World Map & Zone Design

### 5.1 Structure
A **hub-and-spoke, semi-open graph** (not a hard linear DAG like our earlier 2D procedural prototype, since a handcrafted 3D Metroidvania-style world benefits more from designed interconnection than pure procedural generation):

- One central Overworld area connects to 5–8 **Zones** (biomes), each gated by either a traversal item (can't cross deep water until Fins, can't climb the cliff until the Grapple, etc.) or a key item found in another Zone.
- Each Zone is itself a small hand-authored graph of rooms/screens, exactly like Minit's own world — not an open sandbox.

### 5.2 The Solvability & Backtracking Rule (non-negotiable design constraint)
For every Zone:
1. **Solvable within one loop from its nearest House.** Every mandatory puzzle/combat gate inside a Zone must be completable, start to finish, from the nearest bookmarked House within the loop timer, including travel time. If a Zone's critical path is longer than that, it must contain a mid-zone House or a shortcut unlock partway through (exactly like Minit's shortcut gates that open from the far side once you've been through once).
2. **Backtrackable, not just forward-solvable.** Every Zone must have a return path to the Overworld (or a shortcut back) that doesn't require re-solving that Zone's puzzles — once a Zone is cleared, moving through it again (for a key item you missed, or to reach a boss with a new item) must be strictly faster than the first pass. This is what keeps a fully-explorable 3D open world from becoming a repeated-puzzle slog on every loop.
3. **No hard soft-locks.** No permanent item, key, or unlock may be missable-and-required — if something can be permanently consumed or destroyed, either it respawns each loop (it wasn't meant to persist) or it's guaranteed obtainable another way.

### 5.3 Suggested Zone Roster (thematic, mapped later to real Quaternius asset packs in the companion Art Assets document)
| Zone | Theme | Core traversal gate |
|---|---|---|
| Overworld Village | Hub, Houses, NPCs, low danger | None (starting area) |
| Whispering Woods | Forest, first combat/puzzle intro | None — first Zone |
| Sunken Marsh | Swamp/water, deep-water hazard | Requires the Fins item to fully clear |
| Old Quarry | Cliffs/mining, vertical traversal | Requires a Grapple/Climb item |
| Ashen Ruins | Dungeon interior, dark rooms | Requires a Lantern item (mirrors Minit's flashlight-only dark rooms) |
| Frostpeak | Mountain, ice-sliding puzzles | Requires Warm Cloak (frost damage otherwise) |
| The Hollow | Final dungeon, hardest puzzles + final boss | Requires all/most prior key items |

---

## 6. Puzzle Design

Puzzle types, each reusable across Zones with reskins:

- **Item-gated pathing:** a locked gate/vine/rockslide that only a specific permanent item clears — the primary way Zones interlock (Metroidvania backbone).
- **Timed environmental puzzles:** a pressure plate that must be held while another action happens elsewhere — solved with a permanent throwable/placeable item (a "Stone" you can carry and drop on a plate) rather than requiring co-op, since this is single-player.
- **Light/dark puzzles:** rooms that are pitch black without the Lantern (direct Minit reference) — navigation-by-memory puzzles once you've seen the room once, since darkness resets each loop but your memory of the layout doesn't.
- **Sequence/switch puzzles:** multiple switches in the correct order to open a door — rewards a full loop's exploration in one Zone, then a fast repeat run to execute the solution once known (this is the "learn, then execute" rhythm Minit is built around).
- **Boss-key puzzles:** a short puzzle gauntlet immediately before a boss door, deliberately designed to be quick on repeat attempts so failed boss fights don't feel like a puzzle-replay tax.

---

## 7. Combat System

- **Primary weapon:** a stab/swing melee attack (direct analogue to Minit's cursed Sword) — short range, directional, can also destroy certain environment props (bushes, weak walls) to open paths.
- **Health:** small heart-based pool (start at 3), with Heart-Container-equivalent permanent pickups scattered through Zones (one per Zone, optional side content) raising max health — mirrors Minit's six heart containers.
- **Enemy design tiers:**
  - *Tier 1 (Overworld/early Zones):* single-hit-kill, simple patrol/charge AI, telegraphed 0.5s before attacking.
  - *Tier 2 (mid Zones):* 2–3 hit kill, has one special behavior (ranged lob, shield that must be flanked, burrow/pop-up).
  - *Tier 3 (late Zones/mini-bosses):* multi-phase pattern, requires a specific item or timing to beat efficiently within loop time.
- **Weapon upgrades are permanent items**, same philosophy as speed upgrades: a longer blade, a charged heavy-attack, a throw/boomerang variant (direct nod to Minit's Sword Thrower upgrade) — each upgrade should make at least one previously-annoying enemy or puzzle trivially easier, so progression is felt, not just numerically bigger damage.

---

## 8. Bosses

One boss per major Zone (5–6 total), each:

- Fought in a **dedicated arena room** — large enough for a 3D orbit camera to read clearly, using a fixed designer-placed camera per Section 3.
- Has **exactly one unique mechanic** the player must learn and exploit, not a generic bigger-health-bar reskin:
  - *Woods boss:* summons adds that must be killed to expose a weak point (teaches basic priority-target combat).
  - *Marsh boss:* submerges/resurfaces — punishing melee-only players into using a thrown item to interrupt it.
  - *Quarry boss:* rolls boulders the player must dodge or redirect using the Grapple item back at it.
  - *Ashen Ruins boss:* fight plays out mostly in the dark, only visible during its own attack telegraphs — a direct mechanical use of the Zone's Lantern gimmick.
  - *Frostpeak boss:* the arena floor is ice — player and boss both slide, turning positioning into the puzzle.
  - *The Hollow (final boss):* a gauntlet that calls back one mechanic from each prior boss in sequence.
- **The loop timer keeps running during boss fights** (no special exemption) — losing a boss fight to the clock rather than to damage is an intentional design tension, exactly like Minit never pausing its minute for anything. If playtesting shows this feels unfair for a specific boss, the fix is giving that boss a closer House/checkpoint, not pausing the global rule.

---

## 9. NPCs & Houses

- Each House has 0–2 resident NPCs who give **hints, not instructions** — pointing at a Zone's general challenge without spelling out the exact solution, matching Minit's cryptic-but-fair NPC dialogue style.
- A few NPCs give **sidequests** that reward optional Heart Containers or cosmetic items, not mandatory progression — side content should never gate the main path.
- One companion animal (a dog, direct Minit reference) follows the player from the first House once found, provides no combat help, but occasionally reacts (bark/point) near a nearby secret — purely a warmth/charm device, not a mechanic.

---

## 10. Items (representative list — reinterpret names/flavor freely, keep the *functional categories*)

| Category | Effect | Design role |
|---|---|---|
| Traversal key items | Unlock Fins/Grapple/Lantern/Cloak-equivalents | Zone-gating, Metroidvania backbone |
| Strength item (Coffee-equivalent) | Lets the player push heavy blocks/boulders | Opens shortcuts and puzzle solutions gated behind moving obstacles — confirmed Minit mechanic (Coffee item), not just a speed/reach upgrade |
| Speed upgrade (Fast Shoes-equivalent) | +walk speed, or +sprint duration; in Minit this is purchased with collected currency, not found | Makes farther Houses/Zones reachable per loop; consider gating behind a coin-collection sidequest rather than a fixed pickup, matching the source material |
| Weapon upgrade | Longer reach / throw variant (Sword Thrower-equivalent, a confirmed post-boss reward in Minit) / charge attack | Makes specific enemies/puzzles newly trivial |
| Heart Container | +1 max heart | Optional, confirmed as a 6-total collectible set in Minit; combat safety margin |
| Roll/Dash | I-frame short dash | Late unlock, combat + traversal dual-use |
| Map fragment | Reveals a Zone's layout on the map UI | Reduces blind-exploration cost per loop |

**Note on an item I could not verify:** some summaries describe a Watering-Can-equivalent item as also extinguishing fires or powering machinery. I could only confirm its use for watering/reviving a stranded NPC (which unlocks a further item) and growing a plant tied to a heart container — if you want a fire/machinery interaction in our version, treat it as a new addition, not a ported mechanic.

---

## 10a. Fast Travel — Waypoints (Televator-equivalent)

Minit includes three map-wide fast-travel points ("Televators"), unlocked progressively by activating terminals, once a specific optional island is found. This directly solves the tension in Section 5.2's backtracking rule at full-game scale: hand-designed shortcuts handle backtracking *within* a Zone, but a 3D world with 5–8 Zones benefits from a small number of long-range waypoints for cross-Zone backtracking late-game.

- Place 3–4 **Waypoint Shrines**, one per major Zone, each requiring a small activation task (not just walking up to it) — mirrors the terminal-activation gate rather than making fast travel free from the start.
- Waypoints are a *quality-of-life* system layered on top of the House network, not a replacement for it — Houses remain the death-respawn point; Waypoints are a manually-triggered menu teleport available once discovered, used between loops or mid-loop at a time cost (a short teleport animation, not instant) so it doesn't trivialize the loop-timer tension.

---

## 11. UI / HUD

- **Top corner:** heart pips (current health), current loop timer (numeric + a subtle pulsing vignette in the final 15 seconds — direct callback to the earlier 2D prototype's HUD spec).
- **Item slot indicator:** shows currently-equipped consumable/throwable if the player is carrying one.
- **Minimap (optional, unlock-gated by Map Fragments):** small corner map of the current Zone only, not the whole world — keeps some old-school "figure it out" feel even in 3D.
- **No pause-menu inventory management mid-loop** — permanent items are passive/automatic (matching Minit's philosophy of "the items just work, no menu fiddling") except for the single equippable throwable/consumable slot.

---

## 12. Technical Architecture (Godot 4.x)

Autoload singletons (naming intentionally consistent with our earlier 2D prototype's architecture, since the concepts transfer directly):

- **`TimeManager.gd`** — countdown, `loop_expired` signal, HUD timer updates.
- **`GameState.gd`** — `loop_state` (resets every death: enemy HP/position, puzzle temp-state) vs. `run_state` (persists: items, bookmarked House, opened gates, cleared bosses, map fragments, **and now `activated_waypoints: Array[StringName]`** — see below). Waypoint activation state belongs in `run_state`, not `loop_state`: activating a Waypoint Shrine (Section 10a) is exactly the kind of permanent world-unlock that must survive a loop death, same bucket as an opened gate.
- **`WorldGraph.gd`** — the Zone/House adjacency graph used both for design-time solvability validation (Section 5.2) and, now that Section 10a specifies fast travel as a real feature rather than a maybe, as the actual runtime source for the fast-travel menu: it exposes `get_waypoint_positions(only_activated: bool)` so the menu only ever lists Waypoints the player has actually unlocked, and it's the same graph structure that already backs the minimap — no second data structure needed for the two features.
- **Player:** `CharacterBody3D` with a state machine (Idle/Walk/Run/Attack/Roll/Hit/Dead) driven by an `AnimationTree` (blend space for locomotion, one-shot layers for attack/hit).
- **Enemies:** shared `EnemyBase.gd` (health, hit-reaction, death-on-timeout via `GameState.loop_state`) with per-tier behavior scripts attached.
- **Houses:** a `House.gd` script on an `Area3D` trigger volume that calls `GameState.set_bookmark(global_position)`.
- **`WaypointShrine.gd`** — a distinct script from `House.gd`, not a variant of it, since the two persist different things and trigger differently: an `Area3D` alone isn't enough to activate one (Section 10a's "small activation task," e.g. an interact-and-hold or a short puzzle at the shrine, not just walking up to it). On activation, calls `GameState.activate_waypoint(waypoint_id)` and appends to `run_state.activated_waypoints`. Keep `House` and `WaypointShrine` fully separate scripts/scenes even though both are "landmarks you unlock" — collapsing them into one flag-driven script would make it easy to accidentally let a Waypoint act as a death-respawn point (or vice versa), which Section 10a explicitly rules out.
- **Fast-travel execution:** a `FastTravel.gd` (likely a method on `GameState` or a small dedicated autoload) that, on player confirmation from the Waypoint menu, plays the short teleport animation from Section 10a (deliberately not instant), then repositions the player and resumes the active `TimeManager` countdown unpaused — fast travel costs loop time, it doesn't stop the clock.
- **NavigationRegion3D** baked per Zone for enemy pathfinding; every walkable surface must be part of the baked navmesh — this is also the practical fix for "floating assets," since anything not touching the navmesh visually reads as wrong and is easy to spot in a bake-preview screenshot.

---

## 13. Definition of Done — Playtestable Milestone

A Zone is considered complete when all of the following hold, verified by actual play (not just level-editor inspection):

- [ ] Solvable start-to-finish from its nearest House within the loop timer (Section 5.2, rule 1)
- [ ] Backtrackable faster than the first pass, once cleared (rule 2)
- [ ] No missable required item/key (rule 3)
- [ ] No visually floating or clipping props — every static mesh sits on the baked navmesh or has a visible support structure
- [ ] All enemies telegraph before attacking and reset correctly on loop death
- [ ] Camera composition reads clearly in every puzzle/combat room, including boss arenas
- [ ] Full loop, house-to-house, tested at least 10 times with no soft-lock
- [ ] If the Zone contains a Waypoint Shrine: activation persists correctly across a loop death, and fast-traveling to/from it costs visible loop time rather than being instant

See the companion **Art Assets & Build Plan** document for the specific open-source asset packs, placement workflow, and the Godot AI–driven iteration loop used to reach this milestone for each Zone.

---

## 14. Post-Game Alternate Modes (stretch goal, build after the main game is complete)

Minit ships two confirmed post-game modes worth adapting once the core game is solid — do not attempt these until Section 13's Definition of Done is met for every Zone, since both modes only make sense against a fully-solvable base game:

- **Second Run (Hard Mode analogue):** unlocked after finishing the game once. Cuts the loop timer to **40 seconds** (down from the base loop), caps the player at **1 heart with upgrades disabled**, weakens the starting weapon, and re-places several items/enemies so a memorized route from the first playthrough doesn't trivially solve it. For our 3D version: relocate at minimum the Zone's *first* key item and one enemy encounter per Zone — a full re-shuffle isn't necessary to recreate the "your memory alone isn't enough" effect.
- **Mary's Mode (free-exploration analogue):** unlocked after Second Run. Removes the loop timer entirely, played as an alternate character, with its own small unique ending beat. This is a low-cost mode to add — same world, same Zones, timer system simply disabled — and gives completionist players a way to revisit the world without pressure.

Both are explicitly **post-launch scope**, not core-loop requirements — listed here so they're not forgotten, not so they compete with the Section 13 milestone for priority.

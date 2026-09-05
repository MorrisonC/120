# TASK_QUEUE_ADDITIONS_polish_zones_audio.md

Written to match `TASK_QUEUE.md`'s existing format and sizing rules
(`skills/gauntlet-loop-120/resources/task-sizing-guide.md`) exactly — one
system per task, one-sentence acceptance criteria, minimal dependency
chains. Merge these into `TASK_QUEUE.md` (or run them through
`decompose_task.py` first if you want it to double-check sizing). New ID
prefixes used here (`AUDIO`, `CLEAN`, `WOODS`, `MARSH`, `QUARRY`, `FROST`,
`HOLLOW`, `POLISH`) don't collide with existing ones (`COMBAT`, `GRAY`,
`INPUT`, `MCP`, `REF`, `SLASH`, `VIS`).

Priority order reflects the leverage analysis from the zone-scaffolding
review: audio and cleanup first (cheapest, highest-impact), then
structural zone builds, then polish. Frostpeak's visual dressing is
deliberately excluded — it's blocked on asset sourcing outside this
queue's scope (see FROST-2's note).

---

## Epic: Real Audio System (P0 — highest leverage, cheapest fix)

## [TODO] AUDIO-1: Source Kenney Impact Sounds pack
- Scope: download https://kenney.nl/assets/impact-sounds (CC0, 130
  assets), extract into `assets/audio/impact/`.
- Acceptance: `assets/audio/impact/` contains at least 10 `.ogg`/`.wav`
  files; add one line to `ASSET_LINKS.md` recording the source and
  license.
- Depends on: none

## [TODO] AUDIO-2: Source Kenney UI Audio pack
- Scope: download https://kenney.nl/assets/ui-audio (CC0, 50 assets),
  extract into `assets/audio/ui/`.
- Acceptance: `assets/audio/ui/` contains at least 10 files; one line
  added to `ASSET_LINKS.md`.
- Depends on: none

## [TODO] AUDIO-3: Source Kenney RPG Audio pack
- Scope: download https://kenney.nl/assets/rpg-audio (CC0, 50 assets),
  extract into `assets/audio/rpg/`.
- Acceptance: `assets/audio/rpg/` contains at least 10 files; one line
  added to `ASSET_LINKS.md`.
- Depends on: none

## [TODO] AUDIO-4: Add real-stream lookup table to AudioManager.gd
- Scope: `scripts/core/AudioManager.gd` only. Add a `_sfx_streams:
  Dictionary` mapping sound-name strings to preloaded `AudioStream`
  resources; in `_play_sfx_internal`, check `_sfx_streams` first and
  fall back to the existing `_generate_tone_stream` only if the name
  isn't in the dictionary yet.
- Acceptance: calling `AudioManager.play_sfx("test_placeholder")` with
  one entry manually added to `_sfx_streams` plays that real file
  instead of a synthesized tone; a `test_run` suite test confirms the
  fallback path still works for an unmapped name.
- Depends on: none (can land before AUDIO-1/2/3 finish; the dictionary
  can start empty)

## [TODO] AUDIO-5: Wire combat hit sounds to Impact Sounds pack
- Scope: whichever script currently calls `play_sfx` for a weapon-hit
  event (check `scripts/combat/` first) — add real entries to
  `_sfx_streams` for hit/block/miss.
- Acceptance: landing a hit in-game plays a real impact sound, not the
  procedural tone.
- Depends on: AUDIO-1, AUDIO-4

## [TODO] AUDIO-6: Wire item pickup sound to UI Audio pack
- Scope: `scripts/items/ItemPickup3D.gd` only.
- Acceptance: picking up an item plays a real chime, not the procedural
  tone.
- Depends on: AUDIO-2, AUDIO-4

## [TODO] AUDIO-7: Add per-surface footstep switching
- Scope: `scripts/player/PlayerController3D.gd` only. Raycast down from
  the player, check the hit surface's material/group (add a simple
  `"surface_type"` group tag to ground meshes if none exists), select
  the matching footstep sound from `assets/audio/rpg/`.
- Acceptance: walking on grass vs. stone (Village vs. a dungeon floor)
  produces audibly different footstep sounds.
- Depends on: AUDIO-3, AUDIO-4

## [TODO] AUDIO-8: Add per-zone ambient loop
- Scope: `scripts/core/AudioManager.gd` plus one new looping
  `AudioStreamPlayer` child. Key the active ambient loop to
  `GameState.loop_state.current_zone`.
- Acceptance: entering a different zone changes the background ambient
  loop within one frame of the zone-change signal firing.
- Depends on: AUDIO-3, AUDIO-4

---

## Epic: Asset Cleanup (P0 — trivial, do immediately)

## [TODO] CLEAN-1: Remove or justify AetherRevolver.glb
- Scope: `assets/models/weapons/AetherRevolver.glb` only. Confirm via
  `grep -r AetherRevolver scenes/ scripts/` that it's genuinely
  unreferenced (already checked once — came back empty), then delete
  the file, or if it turns out to be intentional, add a one-line note
  in `ASSET_LINKS.md` explaining its intended use.
- Acceptance: either the file no longer exists, or `ASSET_LINKS.md`
  explains why a sci-fi weapon belongs in this project.
- Depends on: none

---

## Epic: WhisperingWoods Structural Build

## [TODO] WOODS-1: Ground, collision, and NavigationRegion3D
- Scope: new `scenes/zones/WhisperingWoods.tscn` — ground plane, material
  (reuse Village's grass material as a temporary stand-in per the
  scaffolding doc), `StaticBody3D`+`CollisionShape3D`, baked
  `NavigationRegion3D`.
- Acceptance: a `test_run` collision/navmesh test (per Testing doc §5.C)
  passes with zero gaps for this new scene.
- Depends on: none

## [TODO] WOODS-2: Place House and Waypoint Shrine
- Scope: `WhisperingWoods.tscn` only — instance
  `res://scenes/world/House.tscn` at (0,1,100) and
  `res://scenes/world/WaypointShrine.tscn` at (10,1,115), matching
  `WorldGraph.gd`'s `house_woods_1`/`waypoint_woods` exactly.
- Acceptance: positions match `WorldGraph.gd`'s dictionary values exactly
  (assert this in a `test_run` test, not just by eye).
- Depends on: WOODS-1

## [TODO] WOODS-3: Zone entrance gate
- Scope: `WhisperingWoods.tscn` — one `BreakableProp3D` instance at
  (0,50) blocking the corridor from the Village, destroyable only via
  an equipped-Sword attack (check `capabilities.has_sword` before
  allowing destruction).
- Acceptance: attacking the gate without the Sword item does nothing;
  attacking it with the Sword equipped destroys it and the state
  persists via `run_state.opened_shortcuts`.
- Depends on: WOODS-1

## [TODO] WOODS-4: Place Hunter NPC with quest stage 0 dialogue
- Scope: `WhisperingWoods.tscn` + `NPC.gd`'s `quest_id`/
  `dialogue_by_stage` export (implement the NPC.gd extension from the
  Master World Map doc's Section 1 first if not already done — check
  before assuming it exists).
- Acceptance: interacting with the Hunter NPC at (5,95) shows the
  stage-0 line; `GameState.get_quest_stage("hunter_wolves")` returns 0
  by default.
- Depends on: WOODS-2

## [TODO] WOODS-5: Place wolf-den enemy encounter
- Scope: `WhisperingWoods.tscn` — 3 enemy instances at (15,80), (18,85),
  (12,82) using `enemies/Snake.glb` or `enemies/Rat.glb` as a themed
  stand-in (no wolf model exists yet — see scaffolding doc §3.1).
- Acceptance: all 3 enemies spawn, patrol within a 6m radius of their
  spawn point, and defeating all 3 advances
  `GameState.advance_quest("hunter_wolves", 1)`.
- Depends on: WOODS-4

## [TODO] WOODS-6: Place Coffee item and pushable-block puzzle
- Scope: `WhisperingWoods.tscn` — Coffee item pickup at (-20,90) using a
  re-skinned `items/Potion1_Filled.glb`; one `PushBlock3D` instance at
  (-15,105) using `village/Crate.glb`, blocking the shortcut path back
  toward the Village.
- Acceptance: the block cannot be pushed until `capabilities.can_push`
  is true; pushing it after Coffee is collected opens a shortcut, and
  `run_state.opened_shortcuts` records it.
- Depends on: WOODS-1

---

## Epic: SunkenMarsh Structural Build

## [TODO] MARSH-1: Ground, collision, and NavigationRegion3D
- Scope: new `scenes/zones/SunkenMarsh.tscn`, same pattern as WOODS-1,
  darker/desaturated material tint per scaffolding doc §3.2.
- Acceptance: same as WOODS-1's acceptance, for this scene.
- Depends on: none

## [TODO] MARSH-2: Place House and Waypoint Shrine
- Scope: `SunkenMarsh.tscn` — House at (-100,1,0), Waypoint at
  (-95,1,10), matching `WorldGraph.gd`'s `house_marsh_1`/
  `waypoint_marsh`.
- Acceptance: same pattern as WOODS-2.
- Depends on: MARSH-1

## [TODO] MARSH-3: Build WaterPlane.gd for deep-water gating
- Scope: new `scripts/world/WaterPlane.gd` + a simple transparent-blue
  material with a scrolling normal map (no external asset needed).
  Area3D-based: applies damage-over-time to the player unless
  `capabilities.can_swim` is true.
- Acceptance: a `test_run` test calling the water area's damage logic
  directly confirms it's a no-op with `can_swim = true` and applies
  damage over time when false.
- Depends on: MARSH-1
- Note: this is a genuinely new technical task, not just placement —
  flagged as such in the scaffolding doc; don't treat it as equivalent
  effort to the other zones' item/enemy placement tasks.

## [TODO] MARSH-4: Place Hermit NPC and Fins item
- Scope: `SunkenMarsh.tscn` — NPC at (-95,5) with `quest_id`
  `hermit_lostboots`; Fins item pickup at (-90,-20) using a re-skinned
  `items/Potion1_Filled.glb` or `items/Key1.glb`.
- Acceptance: interacting with the NPC shows stage-0 dialogue;
  collecting Fins sets `capabilities.can_swim = true`.
- Depends on: MARSH-2

## [TODO] MARSH-5: Place bog guardian enemy
- Scope: `SunkenMarsh.tscn` — one Tier 2 enemy at (-85,-15) using
  `enemies/Frog.glb` scaled 1.5-2x, with one special behavior (ranged
  lob) per GDD §7's Tier 2 spec.
- Acceptance: the enemy requires 2-3 hits to defeat and uses its ranged
  attack at least once in a `test_run`-scriptable combat scenario, or
  confirmed manually if the attack timing isn't unit-testable.
- Depends on: MARSH-2

## [TODO] MARSH-6: Place marsh boss
- Scope: `scenes/enemies/MarshBoss.tscn`, new scene — reuse
  `enemies/Frog.glb` scaled significantly larger, submerge/resurface
  state machine per GDD §8.
- Acceptance: the boss is only damageable while in its "surfaced" state,
  asserted via a `test_run` test calling the boss script's state
  methods directly (per Testing doc §5.A's synchronous-test guidance).
- Depends on: MARSH-1

---

## Epic: OldQuarry Structural Build

## [TODO] QUARRY-1: Ground, collision, and NavigationRegion3D
- Scope: new `scenes/zones/OldQuarry.tscn`, gray-brown material tint
  stopgap per scaffolding doc §3.3.
- Acceptance: same pattern as WOODS-1.
- Depends on: none

## [TODO] QUARRY-2: Place House and Waypoint Shrine
- Scope: House at (0,1,-100), Waypoint at (15,1,-90), matching
  `house_quarry_1`/`waypoint_quarry`.
- Acceptance: same pattern as WOODS-2.
- Depends on: QUARRY-1

## [TODO] QUARRY-3: Place Foreman NPC and rockslide enemies
- Scope: NPC at (5,-95) with `quest_id` `foreman_cavein`; 2 Tier 1
  enemies at (10,-70) and (14,-73) using `enemies/Rat.glb` or
  `enemies/Wasp.glb`.
- Acceptance: same acceptance pattern as WOODS-4/5.
- Depends on: QUARRY-2

## [TODO] QUARRY-4: Place Grapple item and climbing puzzle volumes
- Scope: Grapple item at (20,-80), reachable without the item (bootstrap
  ramp/ladder); climbing-puzzle collision volumes at (25-40,-60 to -90).
- Acceptance: the item is reachable with zero prior capabilities;
  `capabilities.can_climb` becomes true on pickup.
- Depends on: QUARRY-2

## [TODO] QUARRY-5: Place Quarry boss (boulder-roll mechanic)
- Scope: `scenes/enemies/QuarryBoss.tscn`, new scene, at (40,-100). Use a
  simple rock-textured sphere primitive for the boulder prop (no rock
  asset exists yet — don't block this task on sourcing one).
- Acceptance: a `test_run` test confirms the boulder only damages the
  boss when redirected via `capabilities.can_climb`'s associated
  Grapple action, not on ordinary contact.
- Depends on: QUARRY-1

---

## Epic: Frostpeak Structural Build (structural only — see FROST-2's note)

## [TODO] FROST-1: Ground, collision, and NavigationRegion3D
- Scope: new `scenes/zones/Frostpeak.tscn`. Elevated terrain matching
  `WorldGraph.gd`'s Y=10 anchor — build an actual ascending ramp/path
  from ground level, not a flat plane at height.
- Acceptance: same navmesh/collision acceptance as WOODS-1, plus a
  walkable path confirmed from (40,0,-40) up to the House at
  (80,10,-80).
- Depends on: none

## [TODO] FROST-2: Structural placement only — House, Waypoint, gating
- Scope: House at (80,10,-80), Waypoint at (90,10,-70), a `has_item`
  check gating deeper zone access on `WarmCloak`.
- Acceptance: positions match `WorldGraph.gd` exactly; entering without
  `capabilities.has_warmth` applies frost damage over time (reuse the
  `WaterPlane.gd` damage-over-time pattern from MARSH-3 as a template).
- Depends on: FROST-1
- Note: **do not** proceed to a visual dressing pass for this zone —
  per the scaffolding doc §1, no cold-biome asset exists in the project
  yet. This task and FROST-1 are structural only; visual dressing is a
  separate, blocked epic once Ultimate Stylized Nature Pack's snow
  variant is sourced.

---

## Epic: TheHollow Structural + Dressing Build (best-covered by existing assets)

## [TODO] HOLLOW-1: Descent point in OverworldVillage
- Scope: `scenes/zones/OverworldVillage.tscn` — add a well/trapdoor at
  roughly (0,0,15) that transitions the player to TheHollow's House at
  (0,-20,0).
- Acceptance: entering the descent point moves the player to TheHollow
  and updates `loop_state.current_zone`.
- Depends on: none

## [TODO] HOLLOW-2: Ground, collision, dressing pass
- Scope: new `scenes/zones/TheHollow.tscn` — use
  `modular_ruins/FBX/Arch_Gothic.fbx`, `Bookcase_Full.fbx`,
  `Bricks.fbx`, `BridgeSection.fbx` freely (already well-covered per
  scaffolding doc §3.5).
- Acceptance: same navmesh/collision acceptance as WOODS-1; this zone
  can go straight to a real dressing pass, not a stopgap one.
- Depends on: HOLLOW-1

## [TODO] HOLLOW-3: MasterKey gate check
- Scope: immediately past the House — check for Sword, Lantern, Fins,
  Grapple, WarmCloak all present before allowing further progress
  (design decision from Master World Map doc §8).
- Acceptance: a `test_run` test confirms the gate blocks progress with
  any one of the five items missing and allows it with all five present.
- Depends on: HOLLOW-2

## [TODO] HOLLOW-4: Final boss (reuse Ashen Ruins spider mesh, larger + tinted)
- Scope: `scenes/enemies/FinalBoss.tscn` — reuse the `RuinsBoss.tscn`
  spider mesh at larger scale with a distinct emissive tint, per the
  "no new geometry for bosses" rule (Art Assets doc §3).
- Acceptance: boss instantiates without new mesh assets; a `test_run`
  test confirms each prior boss's mechanic (add-summon, submerge-
  interrupt, boulder-redirect, dark-telegraph, ice-slide) triggers in
  sequence per GDD §8.
- Depends on: HOLLOW-3

---

## Epic: AAA-Adjacent Polish Pass

## [TODO] POLISH-1: Hit-stop on weapon connect
- Scope: whichever script resolves a successful hit (check
  `scripts/combat/` first) — brief `Engine.time_scale` dip (~0.05-0.08s)
  on connect, before damage/knockback apply.
- Acceptance: a landed hit produces a measurably briefer game-time delay
  before knockback applies, confirmed by logging `Engine.time_scale`
  during the hit-stop window.
- Depends on: none

## [TODO] POLISH-2: Screen shake with accessibility toggle
- Scope: camera script (check `scripts/camera/` first) — small, capped
  shake on hits taken/dealt and boss telegraphs; one new setting
  (`Settings.screen_shake_enabled`, default true) that disables it
  entirely when off.
- Acceptance: shake fires on a test hit event with the setting on, and
  produces zero camera offset with the setting off.
- Depends on: none

## [TODO] POLISH-3: Audit SlashArc VFX coverage
- Scope: research/scoping task only — check every attack-triggering
  script for whether `assets/models/vfx/SlashArc.glb` fires
  consistently. Record which attack types are missing it.
- Acceptance: a list of attack types with/without the VFX, recorded in
  this task's `Note:` field. Feeds a separate POLISH-3b implementation
  task if gaps are found.
- Depends on: none

## [TODO] POLISH-4: Impact-flash particle on enemy hit
- Scope: one new `GPUParticles3D` burst effect (no new asset needed),
  triggered on enemy `take_damage`.
- Acceptance: a particle burst is visible at the hit location on every
  successful enemy hit.
- Depends on: none

## [TODO] POLISH-5: HUD heart-pip animation on damage/heal
- Scope: HUD script only (whichever node listens to
  `GameState.health_changed`) — replace instant redraw with a brief
  scale-pulse or color-flash per pip changed.
- Acceptance: taking damage or healing visibly animates the affected
  heart pip(s) rather than snapping instantly.
- Depends on: none

## [TODO] POLISH-6: Confirm or implement final-15-seconds timer pulse
- Scope: `TimeManager.gd` + HUD timer display only.
- Acceptance: a research check first — confirm whether this is already
  implemented (it was specified in the GDD/Testing docs); if missing,
  add a pulsing vignette/timer-color-change in the last 15 seconds of
  the loop.
- Depends on: none

## [TODO] POLISH-7: Audit and fix NPC idle animation loops
- Scope: `NPC.gd` and its `AnimationPlayer` usage only.
- Acceptance: every placed NPC loops an idle animation rather than
  holding a static pose; record which NPCs failed the audit in this
  task's `Note:` field before fixing them.
- Depends on: none

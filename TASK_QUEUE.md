# TASK_QUEUE.md

## [DONE] E2E-1: Rendering & visual cohesion
- Scope: Verify WebGL web export canvas rendering and visual cohesion across zones.
- Acceptance: Playwright web E2E tests pass with non-black non-zero pixel canvas render.

## [DONE] E2E-2: Navigation & collision
- Scope: Verify player movement navigation and collision geometry across all biomes.
- Acceptance: Playwright walk/run test detects movement and collision checks pass.

## [DONE] E2E-3: Item use & persistence
- Scope: Verify item pickup, equipment capabilities, and run state persistence across death resets.
- Acceptance: Item tests pass and capabilities flip in GameState.

## [DONE] E2E-4: NPC dialogue triggers
- Scope: Verify dialogue stage transitions and NPC interaction areas.
- Acceptance: Interacting with NPCs triggers stage-appropriate dialogue.

## [DONE] E2E-5: Hint system & HUD
- Scope: Verify HUD map overlay, timer, and hint system triggers.
- Acceptance: Map toggles and hints render on HUD canvas.

---

## Epic: Real Audio System (P0)

## [DONE] AUDIO-1: Source Kenney Impact Sounds pack
## [DONE] AUDIO-2: Source Kenney UI Audio pack
## [DONE] AUDIO-3: Source Kenney RPG Audio pack
## [DONE] AUDIO-4: Add real-stream lookup table to AudioManager.gd
## [DONE] AUDIO-5: Wire combat hit sounds to Impact Sounds pack
## [DONE] AUDIO-6: Wire item pickup sound to UI Audio pack
## [DONE] AUDIO-7: Add per-surface footstep switching
## [DONE] AUDIO-8: Add per-zone ambient loop

---

## Epic: Asset Cleanup (P0)

## [DONE] CLEAN-1: Remove or justify AetherRevolver.glb

---

## Epic: WhisperingWoods Structural Build

## [DONE] WOODS-1: Ground, collision, and NavigationRegion3D
## [DONE] WOODS-2: Place House and Waypoint Shrine
## [DONE] WOODS-3: Zone entrance gate
## [DONE] WOODS-4: Place Hunter NPC with quest stage 0 dialogue
## [DONE] WOODS-5: Place wolf-den enemy encounter
## [DONE] WOODS-6: Place Coffee item and pushable-block puzzle

---

## Epic: SunkenMarsh Structural Build

## [DONE] MARSH-1: Ground, collision, and NavigationRegion3D
## [DONE] MARSH-2: Place House and Waypoint Shrine
## [DONE] MARSH-3: Build WaterPlane.gd for deep-water gating
## [DONE] MARSH-4: Place Hermit NPC and Fins item
## [DONE] MARSH-5: Place bog guardian enemy
## [DONE] MARSH-6: Place marsh boss

---

## Epic: OldQuarry Structural Build

## [DONE] QUARRY-1: Ground, collision, and NavigationRegion3D
## [DONE] QUARRY-2: Place House and Waypoint Shrine
## [DONE] QUARRY-3: Place Foreman NPC and rockslide enemies
## [DONE] QUARRY-4: Place Grapple item and climbing puzzle volumes
## [DONE] QUARRY-5: Place Quarry boss (boulder-roll mechanic)

---

## Epic: Frostpeak Structural Build

## [DONE] FROST-1: Ground, collision, and NavigationRegion3D
## [DONE] FROST-2: Structural placement only — House, Waypoint, gating

---

## Epic: TheHollow Structural + Dressing Build

## [DONE] HOLLOW-1: Descent point in OverworldVillage
## [DONE] HOLLOW-2: Ground, collision, dressing pass
## [DONE] HOLLOW-3: MasterKey gate check
## [DONE] HOLLOW-4: Final boss

---

## Epic: AAA-Adjacent Polish Pass

## [DONE] POLISH-1: Hit-stop on weapon connect
## [DONE] POLISH-2: Screen shake with accessibility toggle
## [DONE] POLISH-3: Audit SlashArc VFX coverage
## [DONE] POLISH-4: Impact-flash particle on enemy hit
## [DONE] POLISH-5: HUD heart-pip animation on damage/heal
## [DONE] POLISH-6: Confirm or implement final-15-seconds timer pulse
## [DONE] POLISH-7: Audit and fix NPC idle animation loops

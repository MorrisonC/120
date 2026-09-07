# Issues & Bug Fixes TODO List

- [x] **3D World Cohesion & Gated Progression Overhaul (Cat Quest Style)**
  - Solution: Reorganized 3D asset directory hierarchy (`nature`, `town`, `props`, `ruins`, `dungeon`, `characters`, `enemies`). Cleanly scrubbed legacy 1-bit references from documentation and manifests. Implemented `QuestManager.gd` autoload with `user://world_save.cfg` state persistence, `GateBarrier3D` 3D roadblock node, `NoticeBoardUI` micro-quest system, and `Overworld.tscn` contiguous multi-zone map.

- [x] **Issue 1: Blown-Out Lighting & Asset Flickering**
  - Problem: Multiple active `DirectionalLight3D` and `WorldEnvironment` nodes stacked across zone scenes in `Main3D.tscn`.
  - Solution: Standardized single centralized directional light and world environment in `Main3D.tscn`.

- [x] **Issue 2: Giant NPC Scale Mismatch & Game Starting Orientation**
  - Problem: `NPCElder` scale mismatch.
  - Solution: Rescaled NPCs to 0.6 character scale.

- [x] **Issue 3: House Interior Missing & Teleport Trapping**
  - Problem: Entering house trapped player in exterior collision.
  - Solution: Created spatial interior room offset with explicit exit door triggers.

- [x] **Issue 4: Sword Attack Non-Functional on Tap / Delayed Action**
  - Problem: Delayed sword attacks.
  - Solution: Updated attack triggers to execute immediately on `is_action_just_pressed("attack")`.

- [x] **Issue 5: Dash Button Non-Functional**
  - Problem: Missing capabilities dict and input actions.
  - Solution: Added `capabilities` dictionary on `GameState.gd` and registered roll/dash actions.

- [x] **Issue 6: Open Source Asset Integration (Kenney Kits CC0)**
  - Solution: Downloaded and integrated CC0 asset packs from Kenney, Quaternius, and KayKit.

- [x] **Issue 7: Playwright E2E Screenshot Verification**
  - Solution: Verified WebGL rendering via Playwright E2E tests and captured screenshot telemetry.

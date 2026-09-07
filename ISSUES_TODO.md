# Issues & Bug Fixes TODO List

- [ ] **Issue 1: Blown-Out Lighting & Asset Flickering**
  - Problem: 7 active `DirectionalLight3D` and `WorldEnvironment` nodes stacked simultaneously across loaded zone scenes in `Main3D.tscn`, causing 7x light energy blowout (solid blinding white scene) and sky/shadow depth flickering.
  - Solution: Remove duplicate lighting/environment nodes from individual zone scenes, maintaining a single unified `DirectionalLight3D` and `WorldEnvironment` in `Main3D.tscn` (or managed dynamically). Calibrate ambient light and tonemapping.

- [ ] **Issue 2: Giant NPC Scale Mismatch & Game Starting Orientation**
  - Problem: `NPCElder` in `OverworldVillage` uses unscaled `Farmer.glb` (scale 1.0), making him 5 meters tall and towering giant over player and house. Starting orientation of player and camera is misaligned.
  - Solution: Rescale `NPCElder` and all zone NPCs to character scale (0.6). Orient player spawn and orbit camera to smoothly face the village center on startup.

- [ ] **Issue 3: House Interior Missing, Trapped Inside Collision & Appearing Under World**
  - Problem: Entering a house steps inside a solid closed exterior mesh (`House_1.glb`) with no interior furniture, no interior floor, no interior lighting, and no exit door trigger. Static colliders trap the player inside forever while camera clips into geometry.
  - Solution: Download Kenney Furniture Kit assets (CC0). Build a furnished house interior room with floor, walls, warm lighting, bed, table, chair, bookshelf, rug, bookmark point, and an explicit `ExitArea3D` door trigger that teleports the player back outside in front of the house doorway.

- [ ] **Issue 4: Sword Attack Non-Functional on Tap / Delayed Action**
  - Problem: `PlayerController3D.gd` only triggered attacks on `is_action_just_released("attack")`, ignoring `is_action_just_pressed("attack")` tap inputs and touch UI sword button. Attack hitbox mask mismatch on destructible objects.
  - Solution: Update `PlayerController3D.gd` to launch sword attacks instantly on `is_action_just_pressed("attack")`. Ensure `AttackArea` collision mask hits enemies, pots, chests, and bushes.

- [ ] **Issue 5: Dash Button Non-Functional**
  - Problem: `PlayerController3D.gd` checked `game_state.capabilities.can_dash`, but `capabilities` dictionary was missing on `GameState.gd`. Input bindings for dash were incomplete.
  - Solution: Add `capabilities` dictionary on `GameState.gd` with `"can_dash": true` and `"can_attack": true`. Bind Space / Shift / F / Q / Touch DASH button to `roll_dash` and `attack`.

- [ ] **Issue 6: Open Source Asset Integration (Kenney Furniture Kit CC0)**
  - Problem: Lack of 3D interior props for house interiors.
  - Solution: Download Kenney Furniture Kit zip, extract GLTF furniture into `game/assets/models/props/interior/`, and document sources in `ASSET_LINKS.md`.

- [ ] **Issue 7: Playwright E2E Screenshot Verification & TODO Completion**
  - Problem: Need visual verification of fixes in headless WebGL export via Playwright screenshots.
  - Solution: Capture screenshots navigating through village, using sword attack, dashing, entering house interior, and exiting house. Confirm visual fixes and mark TODO items complete.

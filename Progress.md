# Progress Tracker

## Milestone 1: Project Initialization & Progress Tracking - COMPLETED
- [x] Download and install Godot 4.3 Linux headless.
- [x] Initialize a new Godot 4 project.
- [x] Create `Progress.md` tracking setup.
- [x] Install and configure GUT (Godot Unit Test) framework.
- [x] Configure `.gutconfig.json` for running GUT tests.
- [x] Complete pre-commit steps.
- [x] Submit changes.

## Milestone 2: Core Time-Loop Engine - COMPLETED
- [x] Implement `TimeManager.gd` with 120s loop, signals, and pause/resume mechanics.
- [x] Implement `GameState.gd` with loop state, run state, movement speed modifiers, and respawn logic.
- [x] Write GUT tests for time loop reset lifecycle and speed/capability state management.
- [x] Update `Progress.md` and verify GUT tests pass headlessly.
- [x] Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
- [x] Submit the change for Milestone 2.

## Milestone 3: Procedural World Generator & Solver - COMPLETED
- [x] Implement `ProceduralWorldGenerator.gd` Macro-DAG logic (biome layout and checkpoints).
- [x] Implement Micro-Room graph generator and logic for item gating matrices.
- [x] Implement the Speed-Aware Solvability Engine (travel-time calculations based on modifiers).
- [x] Write GUT tests for multi-biome solver and item-gated solvability logic.
- [x] Update `Progress.md` and verify GUT tests pass headlessly.
- [x] Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
- [x] Submit the change for Milestone 3.

## Milestone 4: Modular Puzzle Templates - COMPLETED
- [x] Implement puzzle templates: BlockPush, DigSpot, VineCut, WaterDrain, LightReflector, TimedLever.
- [x] Create mock room scenes or scripts to integrate these puzzles.
- [x] Write tests to ensure puzzles interact correctly with player capabilities.
- [x] Update `Progress.md` and verify GUT tests pass headlessly.
- [x] Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
- [x] Submit the change for Milestone 4.

## Milestone 5: Assets, CI/CD, and Export Configuration - COMPLETED
- [x] Download Kenney CC0 assets via curl, document in `ASSETS.md`.
- [x] Setup basic Godot TileMaps with collision polygons and layers.
- [x] Create GitHub Actions workflow (`.github/workflows/build.yml`) for GUT tests and Web/Android exports.
- [x] Configure Web export and Android export profiles in `export_presets.cfg`.
- [x] Update `Progress.md`.
- [x] Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
- [x] Submit the change for Milestone 5.

## Web Export Gray Screen Resolution & Gauntlet Diagnostics - COMPLETED
- [x] Audit export preset threading configuration (`variant/export_type=0`).
- [x] Configure COOP/COEP headers (`Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`) for Web export servers.
- [x] Verify main scene configuration (`run/main_scene="res://Main.tscn"`).
- [x] Run `diagnose_gray_screen.sh` and verify zero browser console errors or asset 404s.
- [x] Execute end-to-end automated Playwright Web test (`serve_and_test.js`) and capture WebGL rendering screenshots.
- [x] Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.

## End-to-End Experience Coverage - COMPLETED
- [x] Audit for missing-texture placeholders across full seed walkthroughs (E2E-1).
- [x] Verify impassable terrain blocks player movement (E2E-2).
- [x] Implement signals and visual juice feedback for all 6 puzzle templates (BlockPush, DigSpot, VineCut, WaterDrain, LightReflector, TimedLever) (E2E-3a through E2E-3f).
- [x] Implement NPC dialogue triggers with first-meeting and repeat lines (E2E-4).
- [x] Implement hint system trigger conditions and signals (E2E-5).
- [x] Perform audio trigger audit and add `AudioManager.gd` with BGM and SFX players (E2E-6).
- [x] Verify all 26 GUT unit tests pass headlessly and all Lane B gauntlet targets are unblocked.
- [x] Complete pre-commit steps.

## TetraForce Movement/Combat Retrofit & Jules AI Continuity Skill - COMPLETED
- [x] Implement InputMap bindings for WASD/Arrows (`ui_left`, `ui_right`, `ui_up`, `ui_down`, `ui_accept`).
- [x] Implement top-down 8-directional movement, cardinal facing vector snapping, attack hitboxes, and 3-heart health system in `PlayerController.gd`.
- [x] Add safe checkpoint beacon zones, enemy contact damage, HP heart UI, and checkpoint respawning in `Main.gd`.
- [x] Integrate `continue-120-build` skill, `resume.sh`, `capture_web_e2e.sh`, `playwright_walk_run.js`, `MOVEMENT_AND_COMBAT_REFERENCE.md`, `CONTINUE_BUILD_PROMPT.md`, and `SESSION_LOG.md`.
- [x] Install `godot_mcp_bridge` editor plugin and test scenario runner.
- [x] Complete all 31 tasks in `TASK_QUEUE.md`.
- [x] Execute gauntlet loop critic evaluation (`run_gauntlet.sh`) for `ArtThemeConsistency` and `ProceduralVarietyFeel` targets against TetraForce bar.
- [x] Verify unit test suite headlessly (28 GUT tests passing across 8 suites).
- [x] Complete pre-commit steps.

## Land Terrain & TileMap Visual Retrofit - COMPLETED
- [x] Refactor HUD layout with top panel background, clear margins, and non-overlapping Labels/Hearts UI.
- [x] Remove giant raw "SAFE" ground text overlays and floating room names from gameplay areas.
- [x] Implement 16x16 tile-based procedural terrain generator in `TextureGenerator.gd` providing distinct ground, path, wall, and decor textures for all 6 biomes.
- [x] Implement room tilemap builder in `Main.gd` with boundary collision walls, central 32px path corridors, decor distribution, and open doorways.
- [x] Integrate sprite props for checkpoints, item pickups, obstacles, and enemy targets.
- [x] Execute Playwright E2E Web captures and visually verify landscape rendering against top-down Zelda RPG standards.
- [x] Verify all 8 GUT test suites pass headlessly.
- [x] Complete pre-commit steps.

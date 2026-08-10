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

## Milestone 4: Modular Puzzle Templates - IN PROGRESS
- [ ] Implement puzzle templates: BlockPush, DigSpot, VineCut, WaterDrain, LightReflector, TimedLever.
- [ ] Create mock room scenes or scripts to integrate these puzzles.
- [ ] Write tests to ensure puzzles interact correctly with player capabilities.
- [ ] Update `Progress.md` and verify GUT tests pass headlessly.
- [ ] Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
- [ ] Submit the change for Milestone 4.

## Milestone 5: Assets, CI/CD, and Export Configuration
- [ ] Download Kenney CC0 assets via curl, document in `ASSETS.md`.
- [ ] Setup basic Godot TileMaps with collision polygons and layers.
- [ ] Create GitHub Actions workflow (`.github/workflows/build.yml`) for GUT tests and Web/Android exports.
- [ ] Configure Web export and Android export profiles in `export_presets.cfg`.
- [ ] Update `Progress.md`.
- [ ] Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
- [ ] Submit the change for Milestone 5.

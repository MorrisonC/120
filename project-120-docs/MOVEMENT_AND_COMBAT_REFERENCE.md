# MOVEMENT_AND_COMBAT_REFERENCE.md

Reference: Top-down 3D Action RPG (inspired by *Cat Quest* and 3D *Zelda* titles).

**Working assumption:** Retrofitting 120's movement/combat/puzzle systems to match a top-down 3D action RPG feel, preserving the procedural-biome and 120-second time loop core mechanics while using 3D character bodies, smooth camera tracking, and real-time combat.

## 1. Movement

Standard for 3D top-down action RPGs:

- **`CharacterBody3D`-based**, free 8-directional or analog velocity with smooth rotation and movement.
- Top-down 3/4 isometric perspective camera tracking the player character.
- **Directly reuses 120's existing speed-modifier system** (`GameState.gd`) — items granting movement boosts feed into the Speed-Aware Solvability Engine.
- Collision via `CharacterBody3D` + 3D Collision Shapes and World Environment colliders.

## 2. Combat

Real-time action combat with directional melee attacks:

- Small hit-point pool (heart HUD indicators) where taking damage triggers brief i-frame invulnerability windows.
- Directional melee attacks (`AttackArea` in 3D) active for short attack windows on button press or touch input.
- Enemies monitor body collisions to deliver contact damage while taking damage from player swing hitboxes. Upon reaching 0 HP, enemies emit particle effects and despawn.

### Combat as a graph gate (extends COMPLEXITY_GRAPH.md)
An enemy blocking a path is a gate type alongside item-gates in the Micro-Room graph: passable only after the enemy is defeated or evaded. It contributes its own time cost to the Speed-Aware Solvability Engine's critical-path calculation.

## 3. Puzzles

3D environmental puzzles embedded in real-time movement and combat (pushing 3D blocks, pulling levers, pressure plates, cutting vines, reflectors) across procedural zones and dungeons.

## 4. Aesthetic

3D Stylized Low-Poly / Cel-Shaded aesthetic utilizing modular glTF/GLB models, vibrant saturated materials, procedural sky environment, directional sun lighting with SSAO, and ACES tonemapping. See `ASSETS.md` for the full 3D asset registry (Kenney Nature/Town/Dungeon, Quaternius Ruins/Props, KayKit Adventurers/Skeletons).

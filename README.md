# Loopkeeper 3D (120)

> **Visual & Technical Style:** 3D Stylized Low-Poly Adventure (inspired by *Cat Quest* and top-down *Zelda* titles), utilizing modular glTF/GLB models, vibrant saturated PBR/cel-shaded materials, directional sun lighting, and a fixed top-down 3/4 isometric perspective.

## Overview

Loopkeeper 3D is a 3D time-loop action RPG built in Godot 4. Players explore a continuous open world composed of diverse biomes (Overworld Village, Whispering Woods, Sunken Marsh, Old Quarry, Frostpeak, and Ashen Ruins), solving environmental puzzles, fighting enemies in real-time combat, and attempting to stabilize the time loop before the 120-second timer expires.

## Architecture & Asset Pipeline

- **Engine:** Godot 4 (GL Compatibility / WebGL2 export support)
- **3D Assets:** Low-poly modular glTF/GLB models sourced from Kenney (Nature, Town, Dungeon kits), Quaternius (Ultimate Modular Ruins, Fantasy Props), and KayKit (Adventurers, Skeletons, Animations).
- **Lighting & Materials:** Saturated PBR materials with ACES tonemapping, directional sun light, procedural sky environment, and SSAO.
- **Camera:** Fixed top-down 3/4 isometric 3D perspective with smooth character tracking.

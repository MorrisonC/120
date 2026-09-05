# Art Assets & Build Plan — "Loopkeeper" (3D Time-Loop Adventure)

Companion to the Game Design Document. Every pack named below was confirmed live on quaternius.com at research time — these are real, current packs, not guesses. Quaternius releases everything under a CC0-style free license (per the site's own License page) — free for personal and commercial use — but re-check the license file bundled in each download before shipping, since exact wording can change pack to pack.

**Every pack referenced anywhere in this document is linked in Section 11's master table** — that table is the single source of truth for direct links; the prose sections above it name packs without repeating the URL every time.

---

## 1. Sourcing Philosophy

- **One character rig standard, everywhere.** Quaternius's humanoid packs are explicitly built as "Retargetable" onto a shared "Universal" rig — pick that rig once and every animation/character pack snaps onto it without per-asset rework. This is the single most important sourcing decision: it turns "find one animation per action" into "download one animation library and reuse it across every humanoid in the game."
- **Low-poly/stylized aesthetic throughout**, not photorealistic — matches Quaternius's whole catalog, keeps file sizes small (important if you ever want a web export), and matches Minit's own charmingly simple visual identity translated to 3D.
- **Prefer packs already tagged for the relevant use** (dungeon, medieval, RPG, monsters) over generic ones — Quaternius's tags map cleanly onto this game's Zone list.

---

## 2. Player Character & Animation

| Need | Pack | Why |
|---|---|---|
| Player base mesh + rig | **Universal Base Characters** | Explicitly rigged/retargetable; includes stylized human variants suitable for a Minit-style "ordinary person" protagonist. |
| Core animation set | **Universal Animation Library** and **Universal Animation Library 2** | Between the two: idle, walk/jog/run, combat (attack swings), crawling, death, parkour, slide, farming/fishing (repurpose one as the "interact/pick up item" gesture). Covers every state machine node listed in the GDD's Section 12 player state machine. |
| Cosmetic variation (optional) | **Modular Character Outfits – Fantasy** | Lets the player's look change as they collect armor-flavored items, without new rigs. |

**Animation-state mapping** (GDD §12 state machine → source clip):
- Idle → Universal Animation Library "Idle"
- Walk/Run → Universal Animation Library "Walk"/"Jog"/"Run" blended by speed
- Attack (stab) → Universal Animation Library "Combat" swing clip, trimmed/retimed to a fast stab
- Roll/Dash (unlock) → Universal Animation Library 2 "Slide" or "Parkour" clip repurposed
- Hit-reaction → nearest available reaction/flinch clip in either library; if none exists, this is the one clip worth hand-animating in Godot's `AnimationPlayer` (short, 2–3 keyframes, cheap to author directly with Godot AI's AnimationPlayer authoring tools)
- Death/loop-reset → "Death" clip, cut short/faded into the death-transition VFX rather than played to completion

---

## 3. Enemies & Bosses

| Zone tier | Pack | Notes |
|---|---|---|
| Early/overworld regular enemies | **Easy Enemy Pack** (bee, wasp, snake, rat, spider, frog) | Simple silhouettes, good for Tier 1 telegraphed one-hit-kill enemies. |
| Mid-game regular + dungeon enemies | **Bestiary – Dungeon Monsters Kit** | Rigged, retargetable, medieval/fantasy — the single best-fit pack for Ashen Ruins and The Hollow. |
| General monster variety (Marsh/Frostpeak flavor) | **Ultimate Monsters** and **Cute Animated Monsters Pack** | Broad roster (yeti, cactus, demon, ghost, mushroom, bat, slime, dragon, skull, etc.) — pull specific creatures matching each Zone's theme (yeti → Frostpeak, mushroom/demon → Ashen Ruins/Marsh). |
| Lightweight filler enemies | **Animated Monster Pack** (dragon, skeleton, bat, slime — tagged "easy") | Good Tier 1/2 filler where a full Bestiary rig is overkill. |
| Bosses | Scale up the most thematically-fitting mesh from the packs above per Zone (e.g., a larger yeti from Ultimate Monsters for the Frostpeak boss) rather than sourcing unique boss meshes | No boss-specific asset pack exists in this catalog — differentiate bosses through **scale, a unique material tint/emissive glow, and VFX** (Godot AI's built-in particle presets: fire, smoke, sparks, magic, lightning — see Section 8) rather than new geometry. This keeps every boss visually distinct without new art. |

---

## 4. World / Zone Terrain Kits

| Zone (from GDD §5.3) | Pack(s) |
|---|---|
| Overworld Village (Houses, hub) | **Medieval Village MegaKit** or **Medieval Village Pack** / **Simple Buildings Pack** — use one small building silhouette consistently as the "House" prefab described in GDD §4 |
| Whispering Woods | **Ultimate Stylized Nature Pack** + **Stylized Tree Pack** |
| Sunken Marsh | **Ultimate Nature Pack** (has willow/swamp-appropriate flora) + **Simple Nature Pack** for filler rocks/grass |
| Old Quarry | **Ultimate Modular Ruins Pack** (statues, columns, rubble) for cliff/quarry dressing |
| Ashen Ruins | **Modular Dungeons Pack** / **Modular Dungeon Pack** — barrels, chests, carpets, statues, built for exactly this kind of interior |
| Frostpeak | **Ultimate Stylized Nature Pack** reused with a snow-tinted material override (cheap: one material swap via Godot AI rather than a whole new pack) |
| The Hollow (final dungeon) | **Modular Dungeons Pack** + **Ultimate Fantasy RTS** kit's temple/tower pieces for a grander final-area silhouette |

---

## 5. Props, Items & Weapons

| Need | Pack |
|---|---|
| Pickup items, chests, potions, gems, keys | **Ultimate RPG Pack** and **RPG Essentials Pack** |
| Sword/weapon variants (base + upgrades) | **Modular Weapons Pack** (sword, dagger, bow, arrow, shield, axe, hammer, scythe) |
| Furniture/interior dressing for Houses | **Ultimate House Interior Pack** or **Furniture Pack** |
| General fantasy set-dressing (crates, barrels, cauldrons, market stalls) | **Fantasy Props MegaKit** |

---

## 6. Companion Animal

**Ultimate Animated Animal Pack** includes a husky/Shiba Inu-styled dog among its animal roster — use this directly as the Minit-inspired companion dog from GDD §9. Same pack covers wolves/foxes if you want a wild-animal reskin for a specific Zone's ambient wildlife too.

---

## 7. NPC Villagers

**RPG Character Pack** (wizard, knight, monk, ranger, assassin — animated, textured, medieval/dungeon themed) covers House-resident NPCs with enough variety that each House's NPC can look distinct without extra sourcing.

---

## 8. Placement, Lighting & the "No Floating Assets" Problem

This is a workflow discipline, not a single setting — it's the thing that most often makes an AI-assisted 3D build look wrong even when every individual asset is fine.

1. **Ground-snap every placed static mesh.** When placing a prop via Godot AI's scene/node operations, follow every placement with a downward raycast (or a quick manual check) from the prop's origin to the terrain/floor mesh, and set the prop's Y position to the hit point — never place by eyeballed coordinates alone. Any prop with a flat base (crates, chests, furniture) should have its origin at its own base, not its center, specifically so this snap is a one-step operation.
2. **Every static mesh needs a collision shape**, even set-dressing — a `StaticBody3D` + matching `CollisionShape3D` (or `CollisionPolygon3D` from a trimesh for irregular ruin pieces). This isn't just for gameplay collision — it's what lets Godot's navigation baking correctly exclude non-walkable geometry, which is the other half of the floating-asset problem (props that *look* fine but let the player walk through/under them).
3. **Bake `NavigationRegion3D` per Zone after placement, not before.** Bake, then take a Godot AI smart screenshot of the navmesh overlay — any walkable-looking area that didn't get included in the bake is either missing collision on the floor mesh beneath it or has a prop incorrectly marked as a navigation obstacle. This is a fast, visual way to catch both floating props and invisible walk-blockers in the same pass.
4. **Contact shadows and ambient occlusion are what actually sell "grounded."** A perfectly-snapped prop with no shadow underneath still reads as floating to the human eye. Use Godot 4's SDFGI (or baked lightmaps for static Zones, cheaper at runtime) with at least a soft-shadow-casting `DirectionalLight3D` per Zone — this is a WorldEnvironment/lighting setup task, well within Godot AI's documented lighting operations.
5. **Per-Zone lighting mood** (also solves readability, not just aesthetics): warm/dappled light + green-tinted ambient for Whispering Woods; desaturated blue-gray + fog for Sunken Marsh; warm torchlight pools in Ashen Ruins/The Hollow (deliberately dark between pools, per GDD §6's Lantern puzzle); cool blue-white + particle snow for Frostpeak. Fog color/density per Zone also helps depth-cue distant terrain so nothing at the horizon looks like it's floating in a void.

---

## 9. Import & Technical Settings

- Import all Quaternius glTF files with **"Skeleton3D" retargeting** enabled where applicable — since every character pack shares the Universal rig, Godot's animation retargeting tools should let one `AnimationLibrary` drive every humanoid character/enemy that uses that rig.
- For static environment props: generate collision via **trimesh** for irregular geometry (ruins, rocks) and **convex/box** for simple furniture — trimesh is more accurate but more expensive; reserve it for large terrain pieces, not every small prop.
- Keep a **per-Zone scene** (one `.tscn` per Zone) rather than one giant world scene — matches the GDD's Zone-graph structure, keeps navmesh bakes and lighting bakes scoped and fast to iterate on, and lets Godot AI operate on one Zone at a time without loading the whole world.

---

## 10. Godot AI–Driven Build & Iteration Workflow

This plugin (MIT-licensed, from the MCP-for-Unity team) exposes 150+ real editor operations to any connected MCP client — including Antigravity, which you're using. The workflow below uses only documented capabilities, not assumed ones.

### Build phase (per Zone)
1. **Scene scaffold:** use Godot AI's scene/node operations to create the Zone's `.tscn`, add a `WorldEnvironment`, `DirectionalLight3D`, and a ground/terrain mesh first.
2. **Terrain & structure placement:** import and place the relevant Zone kit (Section 4) — walls, floors, set pieces — following the ground-snap + collision discipline in Section 8.
3. **Props & items:** place Section 5's props, and item pickups from the GDD's Section 10 list, each with an `Area3D` pickup trigger script.
4. **Enemies:** instance the Zone-appropriate enemy scenes from Section 3, attach patrol/attack behavior scripts.
5. **Lighting pass:** apply the Zone's lighting mood (Section 8, point 5), bake lighting/navmesh.
6. **Materials/VFX for anything boss- or hazard-related:** use Godot AI's one-call material and particle presets (fire, smoke, sparks, magic, lightning) directly, rather than hand-authoring shaders, for boss tells and hazard indicators (e.g., a magic-particle glow on a boss's exposed weak point).

### Test & iterate phase (per Zone, repeatable)
1. **Visual QA via smart screenshots:** capture the in-game framebuffer from a few camera angles per room (mirrors the visual-regression discipline from the earlier 2D project's Playwright step, but native to the editor here) — check for floating props, navmesh gaps, and lighting/readability issues per Section 8.
2. **Solvability & backtracking validation:** implement the `WorldGraph.gd` adjacency check from the GDD's Section 12 as a GUT test — assert every Zone's critical path is reachable within the loop timer from its nearest House, and that a return path exists that's shorter than the first pass (GDD §5.2, rules 1–2). This is the same DAG-solvability discipline used in the earlier 2D procedural prototype, just validated against a hand-authored graph instead of a generated one.
3. **Combat/puzzle playtest pass:** play each Zone start-to-finish at least 10 times (GDD §13's Definition of Done) — log deaths, time-to-clear, and any point where the camera or lighting made a puzzle/enemy unreadable.
4. **One fix at a time, then re-screenshot/re-test:** exactly the discipline from the earlier statistical playtest-iteration prompt — don't bundle a lighting fix with a navmesh fix with a prop-placement fix in the same pass, so it's clear which change actually resolved which symptom.
5. **Mark the Zone "done"** only when every checkbox in the GDD's Section 13 Definition of Done is checked from actual play, not editor inspection alone.

Repeat this per Zone until the full 5–8 Zone roster (GDD §5.3) is built, then do one final full-game playthrough pass (House 1 through The Hollow) to confirm the whole Zone graph interlocks correctly — no Zone should turn out to require an item that's only reachable *after* that Zone in practice.

---

## 11. Master Asset Link Table

Every URL below was read directly off quaternius.com's own listing page, not reconstructed — this is the direct-link table Section 0's note above points to. Two packs (rows marked *) have near-identical names on the site itself ("Modular Dungeons Pack" vs. "Modular Dungeon Pack") — both are real, distinct pages, listed separately here on purpose so they aren't conflated.

| Pack | Used for | Link |
|---|---|---|
| Universal Base Characters | Player rig | https://quaternius.com/packs/universalbasecharacters.html |
| Universal Animation Library | Core animation set | https://quaternius.com/packs/universalanimationlibrary.html |
| Universal Animation Library 2 | Extended animation set (parkour/slide) | https://quaternius.com/packs/universalanimationlibrary2.html |
| Modular Character Outfits – Fantasy | Cosmetic player variation | https://quaternius.com/packs/modularcharacteroutfitsfantasy.html |
| Easy Enemy Pack | Tier 1 enemies | https://quaternius.com/packs/easyenemy.html |
| Bestiary – Dungeon Monsters Kit | Mid-game/dungeon enemies | https://quaternius.com/packs/bestiarydungeonmonsterskit.html |
| Ultimate Monsters | General monster roster (boss donors) | https://quaternius.com/packs/ultimatemonsters.html |
| Cute Animated Monsters Pack | General monster roster, alt | https://quaternius.com/packs/cutemonsters.html |
| Animated Monster Pack | Lightweight filler enemies | https://quaternius.com/packs/animatedmonster.html |
| Medieval Village MegaKit | Overworld Village / Houses | https://quaternius.com/packs/medievalvillagemegakit.html |
| Medieval Village Pack | Overworld Village / Houses, alt | https://quaternius.com/packs/medievalvillage.html |
| Simple Buildings Pack | House prefab, alt | https://quaternius.com/packs/simplebuildings.html |
| Ultimate Stylized Nature Pack | Whispering Woods / Frostpeak (tinted) | https://quaternius.com/packs/ultimatestylizednature.html |
| Ultimate Nature Pack | Sunken Marsh | https://quaternius.com/packs/ultimatenature.html |
| Simple Nature Pack | Filler flora/rocks | https://quaternius.com/packs/simplenature.html |
| Stylized Tree Pack | Tree dressing, all outdoor Zones | https://quaternius.com/packs/stylizedtree.html |
| Ultimate Modular Ruins Pack | Old Quarry | https://quaternius.com/packs/ultimatemodularruins.html |
| Modular Dungeons Pack * | Ashen Ruins / The Hollow | https://quaternius.com/packs/modulardungeon.html |
| Modular Dungeon Pack * | Ashen Ruins / The Hollow, alt | https://quaternius.com/packs/medievaldungeon.html |
| Ultimate Fantasy RTS | The Hollow's temple/tower dressing | https://quaternius.com/packs/ultimatefantasyrts.html |
| Ultimate RPG Pack | Pickups, chests, potions, gems | https://quaternius.com/packs/ultimaterpg.html |
| RPG Essentials Pack | Pickups, alt/overflow | https://quaternius.com/packs/rpg.html |
| Modular Weapons Pack | Sword/weapon variants | https://quaternius.com/packs/medievalweapons.html |
| Fantasy Props MegaKit | General set-dressing | https://quaternius.com/packs/fantasypropsmegakit.html |
| Ultimate House Interior Pack | House interior dressing | https://quaternius.com/packs/ultimatehomeinterior.html |
| Furniture Pack | House interior dressing, alt | https://quaternius.com/packs/furniture.html |
| Ultimate Animated Animal Pack | Companion dog + ambient wildlife | https://quaternius.com/packs/ultimateanimatedanimals.html |
| RPG Character Pack | House-resident NPCs | https://quaternius.com/packs/rpgcharacters.html |

If any link 404s by the time you go to download (Quaternius reorganizes its catalog occasionally), search the pack name directly on quaternius.com/assets rather than assuming the pack was removed — I'd rather flag that possibility than guarantee link permanence I can't verify.

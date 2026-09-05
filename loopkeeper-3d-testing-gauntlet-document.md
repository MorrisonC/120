# Loopkeeper — Technical Testing & Gauntlet Iteration Document

Companion to the Game Design Document and Art Assets & Build Plan. Covers how to test, critique, and iteratively improve the 3D build in Godot, combining deterministic automated tests with a **Gemini 3.8 Flash** vision critic pass — both wired through the **Godot AI** MCP addon (godotengine.org/asset-library/asset/5050) you're already using with Antigravity. Confirmed directly from the addon's own repo, not assumed: it ships **150+ operations**, its **own native GDScript test framework** (`McpTestSuite`/`test_run` — not GUT), and **smart screenshots** from the editor viewport, the in-game framebuffer, or a cinematic camera. Architecture: `MCP client → godot-ai attach (stdio) → Python server (auth HTTP, port 8000) → Godot editor plugin (auth WebSocket, port 9500)`.

Also confirmed real and current: `gemini-3.8-flash`, released September 2, 2026, multimodal (text/image/audio/video/PDF input, 1M-token context) — and notably, **Antigravity's own SDK already defaults to this exact model**, which is why Section 3.2's recommended default wiring needs no separate API setup.

---

## 1. Testing Philosophy

Two fundamentally different kinds of "broken" require two fundamentally different kinds of test, and conflating them is where testing loops go wrong:

- **Objective/deterministic** — collision, respawn state, item logic, puzzle solvability, boss state machines. These have a correct answer. Test them with Godot AI's native `McpTestSuite` framework (Section 2), every run. Never let a subjective opinion override a failing deterministic test.
- **Subjective/qualitative** — "does this look professional," "is this puzzle visually readable," "does this boss arena compose well." These don't have a single correct answer, but they aren't unmeasurable either — this is where the Gemini vision critic (Section 3) earns its place, scoring and describing what it sees against a fixed rubric so findings are at least *consistent* and *specific*, even though they're ultimately a matter of judgment.

The **Gauntlet** (Section 4) is the repeatable loop that runs both kinds of test together every iteration: one change at a time, re-test, compare against baseline, never trust a single run, never let an unverified finding become an "action taken" without a human decision in the loop.

---

## 2. Deterministic Tests via Godot AI's Native Test Framework

### 2.1 What it actually is (not GUT — read this before writing any test)
Godot AI ships its own in-editor GDScript test framework: `McpTestSuite` (base class — assertions + lifecycle hooks) and `McpTestRunner` (discovery, execution, result collection), invoked through the MCP tool `test_run`. This runs against whatever project the connected editor has open — i.e., Loopkeeper itself once the addon is enabled in that project. There is no reason to add GUT as a second dependency here; the addon you're already running for scene-building is the same one that runs your tests.

### 2.2 Discovery rules
- Scanned directory: `res://tests/`, **top level only** — subdirectories are not scanned, so don't nest suites by category.
- Filename must match `test_*.gd`, must `extend McpTestSuite`, must be instantiable.
- A file that fails to load (parse error, wrong base class) lands in the result's `load_errors` array — the rest of the run still proceeds.
- Suites run sorted by `suite_name()`; within a suite, `test_*` methods run alphabetically.
- **Test methods must be synchronous — no `await`.** A test suspends at its first `await` and everything after it silently never runs. This is a real constraint, not a style preference, and it directly shapes what belongs in this layer vs. what needs a live game session (Section 2.5).

### 2.3 Skeleton (real API, copy this pattern)
```gdscript
@tool
extends McpTestSuite

func suite_name() -> String:
    return "items"              # short id, matched by test_run suite=...

func test_coffee_item_enables_push() -> void:
    var player = track(PlayerScene.instantiate())
    GameState.run_state.items.erase("push_strength")
    assert_false(player.can_push_block(), "should not push without the item")
    GameState.run_state.items.append("push_strength")
    assert_true(player.can_push_block(), "should push once the item is granted")
```

`track(obj)` frees the object after the test (and again after `suite_teardown`) — use it for every instantiated node so suites don't leak state into each other. `skip("reason")` marks an unmet precondition rather than a pass or fail. **A test that completes with zero assertions automatically fails** ("likely skipped its logic") — this is a real guardrail the runner enforces, and it directly reinforces this document's own "a finding must be specific and checkable" philosophy from Section 3.4: the framework itself refuses to let an empty test silently count as verification.

### 2.4 Running tests
```
test_run                              # all suites — compact: counts + failures only
test_run suite=items                  # one suite, exact match on suite_name()
test_run test_name=push               # only tests whose name contains "push"
test_run exclude_test_name=slow,flaky # skip matching tests
test_run verbose=true                 # every individual result, not just failures
```
120-second server-side timeout for the whole run. Result shape includes `passed`/`failed`/`skipped`/`total`, a `failures` array (only present when non-empty, each with `suite`, `test`, `message`, `assertion_count`), and `load_errors` when a suite file didn't parse. Re-fetch the last result without re-running via `test_manage(op="results_get")`.

### 2.5 What this layer can and cannot cover (important — shapes Section 5)
Because tests run synchronously on the editor's main thread and **must not** open modal dialogs, switch scenes, or start/stop the game, `McpTestSuite` is the right tool for **logic and state**, not for **live simulated play**:

- **Good fit:** `WorldGraph` solvability/backtracking math, `GameState.run_state`/`loop_state` transition logic called directly, item-flag-and-downstream-effect checks (Section 5.F), respawn state assertions (Section 5.E), boss state-machine transitions tested by calling the boss script's methods directly rather than playing the fight.
- **Not a fit:** the boss win-rate simulation across ≥30 real attempts (Section 5.A), the camera-orbit screenshot sweep (Section 5.C), or anything requiring the game to actually be running in real time. Those need Godot AI's **game control + smart screenshot** operations against a live play session, which is a separate capability from `test_run` — plan for a human or agent-driven play session for that category, not an automated headless loop, unless/until the addon exposes a scripted-input play-session tool (its own roadmap lists "Physics, Shaders, Terrain, Custom Tools" as coming next, not scripted play sessions — don't assume that exists yet).

---

## 3. The Gemini Critic System

### 3.1 What it is
A vision-capable pass over screenshots captured at defined checkpoints during automated or manual play, using Godot AI's **smart screenshots** (editor viewport, in-game framebuffer, or cinematic camera — confirmed real, with built-in "vision routing" so even a text-only connected model can make use of them). It does **not** replace `McpTestSuite` — it catches the category of problem synchronous state assertions structurally cannot: "this technically works but looks wrong," which is exactly the class of bug the Mixingflavors project's cube-rotation and background-mismatch issues turned out to be.

### 3.2 Wiring options (both real, pick based on friction tolerance)
1. **Agent-native critique (recommended default):** since Antigravity's own SDK already runs on Gemini 3.8 Flash, and Godot AI's smart screenshots are explicitly built to let the connected agent *see* the scene, the lowest-friction path is having the agent itself (you, working through Antigravity) call the screenshot operation and perform the critique as a reasoning step in the same session — no separate API wiring, no extra service to maintain.
2. **Direct API call:** an `HTTPRequest` node in a test-runner scene POSTs to the Gemini API (`gemini-3.8-flash`) with a screenshot (saved to disk by Godot AI's screenshot operation, then read and base64-encoded) plus the rubric prompt (Section 3.3) as text, parses the JSON response, and appends it to the findings log (Section 6). More setup, but fully scriptable/schedulable — use this only if you want the critique to run unattended in CI without a human/agent session active, since option 1 has no such path today.

### 3.3 Rubric Prompt (use verbatim, or adapt — keep the JSON-output requirement)
```
You are reviewing a screenshot from a 3D indie adventure game (Godot engine,
low-poly stylized art). Score the following on a 1-10 scale, and for any
score below 8, give ONE specific, checkable observation (describe a location
in the frame, not a vague impression):

1. Grounding: does anything look like it's floating, clipping through
   geometry, or incorrectly scaled relative to its surroundings?
2. Lighting/mood: does the lighting match an intentional atmosphere for this
   scene, or does it look flat/default/mismatched?
3. Readability: in a puzzle or combat screenshot, is the important element
   (switch, weak point, hazard) visually distinguishable at a glance?
4. Composition: does the camera framing read clearly, or is anything
   important cut off, obscured, or poorly centered?
5. Cohesion: do all visible assets appear to belong to the same visual
   style/tier, or does anything look mismatched (e.g. a placeholder-quality
   asset next to finished ones)?

Respond ONLY with JSON, no other text:
{
  "scores": {"grounding": N, "lighting": N, "readability": N, "composition": N, "cohesion": N},
  "findings": [{"category": "...", "score": N, "observation": "specific, checkable description"}],
  "overall_impression": "one sentence, plain language"
}
```

### 3.4 Critical caveat
A critic finding is a **hypothesis, not a verdict**. Before it becomes an "action taken" in the gauntlet report: if it claims something is floating/clipping, verify against the actual collision/navmesh state (Section 5.C) rather than just re-lighting the shot to make it "look" fixed. If it claims a puzzle element is unreadable, verify a human hasn't already solved that exact room easily in playtesting before treating it as a real problem. Aesthetic opinions compound easily into false confidence if treated as ground truth — they're a lead to check, not a fact.

---

## 4. The Gauntlet Loop

```
1. Pull latest, one change scoped per gauntlet run (per the one-fix-at-a-time
   discipline from the earlier iteration-loop work).
2. STAGE — Deterministic tests. Run `test_run` (scoped with suite=/test_name=
   to whatever this run targets). Any failure stops the gauntlet immediately;
   do not proceed to visual critique on a build with a known logic bug.
3. STAGE — Screenshot capture at the defined checkpoints for this run's
   category (boss arena, puzzle room, HUD state, camera sweep — Section 5),
   via Godot AI's smart screenshot operation (editor viewport / in-game
   framebuffer / cinematic camera, whichever fits the checkpoint).
4. STAGE — Gemini critic pass on the captured screenshots (Section 3.3).
   Append raw findings to GAUNTLET_REPORT.md (Section 6) before triage —
   never discard a finding silently.
5. STAGE — Triage: separate each finding into VERIFIED (checked against
   `test_run`/collision/navmesh state, confirmed real) or UNVERIFIED
   (subjective, needs a human call, or contradicted by other test data).
   Only VERIFIED findings get scheduled as fixes this cycle.
5a. STAGE — Route VERIFIED findings: most are fixable with assets already
   in the project (reposition, re-material, re-light). If a VERIFIED
   finding turns out to be a defect in the source Blender data itself
   (bad normals, unapplied transforms, excess poly count) rather than a
   Godot-side placement problem, branch to the Blender MCP repair sub-loop
   (Section 8) instead — see Section 8.3 for exactly which findings qualify.
6. Apply the one scheduled fix. Re-run steps 2-4 on the same checkpoints.
   Compare against the pre-fix baseline — score should move in the
   predicted direction; if it doesn't, the fix didn't address the actual
   cause, revert and re-diagnose rather than layering another change on top.
7. Repeat until the category's promotion criteria (Section 7) are met.
```

---

## 5. Category Test Suites

### A. Boss Fights (GDD §8)
- **`test_run` suite, per boss, one test per unique mechanic:** Woods boss — weak point only exposed after all adds are cleared, not before. Marsh boss — submerge/resurface timing matches spec, damage window only active while surfaced. Quarry boss — boulder redirect via the Grapple item deals damage back to the boss; without the item, redirect is not possible. Ashen Ruins boss — boss is only visible/targetable during its own telegraphed attack windows, asserted directly on the boss script's visibility-state property, not inferred from "the fight is beatable." Frostpeak boss — ice-slide physics apply equally to player and boss. Final boss — each prior sub-mechanic triggers in the correct sequence. Call the boss script's state-transition methods directly in these tests rather than trying to play the fight — that keeps them synchronous and `test_run`-compatible per Section 2.5.
- **Timer regression:** explicit `test_run` test asserting `TimeManager` never receives a pause call during any boss encounter (GDD §7's "no exemption" rule).
- **Balance simulation (needs a live session, not `test_run` — see Section 2.5):** scripted or human "average-skill" attempts at each boss, ≥30 runs, tracking win rate. No fixed target is prescribed here — set the band during first playtesting and treat deviations from *that* baseline as the signal.
- **Critic checkpoints:** cinematic-camera screenshot (GDD §3's designer-placed boss-arena camera) at fight start, at the moment the unique mechanic first activates, and at defeat. Rubric focus: readability — "can you tell what the boss is about to do from this frame alone."

### B. Puzzle Solving (GDD §5.2, §6)
- **`test_run` — Zone solvability graph:** the `WorldGraph.gd` adjacency check from the Art Assets doc's test phase — assert every Zone's critical path is reachable within the loop timer from its nearest House, a return path exists that's faster than the first pass (GDD §5.2 rules 1-2), and no required item is missable (rule 3). Pure data/logic — a clean fit for this layer.
- **Puzzle-type-specific `test_run` tests:** item-gated paths only open with the correct permanent-item flag set; pressure-plate/dropped-item puzzles hold state correctly within a loop and reset on death (call the reset method directly and assert state, don't play it out); dark rooms are dark because the Lantern flag is unset, verified as a flag check; sequence/switch puzzles reject incorrect orderings.
- **Critic checkpoint:** in-game framebuffer screenshot from the player's actual solving vantage point in each puzzle room (this one needs a live session — it's about what a real player sees, not editor state). Ask specifically: "identify any interactive element that is visually ambiguous, hidden, or easy to mistake for background geometry."

### C. Player Collision (Art Assets doc §8, carrying forward the Mixingflavors rotation-distortion lesson)
- **`test_run` — collision/navmesh consistency sweep:** for every static prop instance in a Zone (iterate the scene tree, a synchronous, editor-side operation), assert a `CollisionShape3D`/`CollisionPolygon3D` exists, and assert the baked `NavigationRegion3D` correctly excludes non-walkable geometry and includes every intended walkable surface.
- **Camera-orbit sweep (needs live/cinematic-camera capture, not `test_run`):** Godot AI's cinematic-camera screenshot mode, captured at N evenly-spaced angles around a full rotation. This exists specifically because the Mixingflavors project's cube looked fine from most angles and only broke on rotation due to alpha-blend depth-sorting — bake that exact failure class into this suite from day one. Any transparent/emissive material (torchlight, magic VFX, water) gets this sweep by default.
- **Critic pass on the sweep sequence:** feed the angle sequence to Gemini and ask it to flag any object that appears to shift, clip, or flicker inconsistently between adjacent angles.

### D. Visual Appeal & Professional Game Design
This is the category where the critic is the *primary* tool, since "looks professional" has no deterministic test. Still apply the same discipline:
- Score every Zone's establishing shot and each House/boss-arena (cinematic-camera screenshots) against the full Section 3.3 rubric.
- Cross-check the "cohesion" score against something semi-objective where possible: are all visible meshes drawn from the intended asset-pack tier for that Zone (Art Assets doc §4), or has a mismatched placeholder or wrong-Zone asset been left in by accident?
- **Discard vague findings.** A finding like "looks a bit plain" without a specific checkable location is not actionable.

### E. Respawn (GDD §2 core loop, §12 architecture)
- **`test_run` — core respawn assertions (call `GameState`'s reset method directly, assert state — synchronous, clean fit):** on `loop_expired` or a killing blow, player position snaps to the current bookmarked House; `loop_state` fully resets (enemy HP/position, temporary puzzle state); `run_state` is fully untouched (items, opened gates, cleared bosses, map fragments, `activated_waypoints`); current health restores to current max heart count, not a hardcoded default.
- **Waypoint-specific:** `activated_waypoints` persists across a death; fast-travel execution costs visible loop time (compare `TimeManager` remaining before and after) and is never instant.
- **Edge case — death during a boss fight:** the boss's `loop_state` resets correctly while any pre-boss puzzle-key unlock already achieved this run stays flagged in `run_state`.

### F. Item Use & Item Collection (GDD §10)
- **`test_run`, one test per item, per the Section 2.3 skeleton:** pickup sets the correct `run_state` flag exactly once (guard against double-counting); the corresponding gameplay effect actually applies post-pickup — e.g., the push-strength item genuinely enables `can_push_block()`, not just that a boolean flipped. This is a direct, deliberate defense against the exact bug class found in the earlier Mixingflavors work, where a hint mechanic set visual state without ever calling the function that made it functionally real — build the "does the downstream effect actually fire" assertion into every item test from the start.
- **Persistence:** one-line test per item confirming it survives a loop death (it lives in `run_state`, not `loop_state`).
- **Equip-slot consumable:** assert only one throwable/consumable can be equipped at a time, and that using it triggers both its effect and any cooldown/consumption correctly.
- **Critic checkpoint (live session):** screenshot the HUD item-slot indicator immediately before pickup, immediately after, and immediately after use. Ask Gemini to confirm the visual state change is clearly distinguishable between all three — a direct callback to "does it look like something happened," precisely where the Mixingflavors Hint button's bug went unnoticed until a player reported it.

---

## 6. Findings Log Format — `GAUNTLET_REPORT.md`

Structured consistently with the `BALANCE_ROADMAP.md` pattern used on the Mixingflavors project:

```markdown
## Gauntlet Run: <date>

### Category: <Boss Fights | Puzzle Solving | Collision | Visual | Respawn | Items>
- **test_run status:** <passed/failed/skipped/total, failing test names if any>
- **Critic scores:** grounding N, lighting N, readability N, composition N, cohesion N
- **Findings:**
  - [ ] VERIFIED - <specific observation> - action: <fix scheduled / already fixed>
  - [ ] UNVERIFIED - <specific observation> - needs: <human review / more data>
- **Change tested this run:** <the one scoped change>
- **Result vs. baseline:** <metric before -> after>
```

Never mark a finding VERIFIED without the cross-check described in Section 3.4.

---

## 7. Promotion / Stopping Criteria

A feature category (a specific boss, a specific Zone's puzzles, respawn logic, an item) is considered gauntlet-clean when, over **3 consecutive gauntlet runs**:

- `test_run` passes with no regressions for every suite touching that category
- Critic scores across all five rubric dimensions are ≥8, or every finding below 8 has been triaged to UNVERIFIED-and-accepted (a deliberate design choice, not an unresolved bug)
- No VERIFIED finding remains unfixed
- For boss fights specifically: win-rate over ≥30 live-session attempts sits within the band established during first playtesting (Section 5.A)
- The relevant GDD §13 Definition-of-Done checklist is fully checked from actual play, not editor inspection

Once a category is gauntlet-clean, drop it to a lighter periodic regression check (re-run its `test_run` suite via `test_run suite=<name>` on any change that touches related files) rather than continuing active tuning — the same discipline used once Mixingflavors' telemetry-fidelity work stabilized.

---

## 8. Blender MCP Integration — Repair & Diagnosis Sub-Loop

### 8.1 What this actually is (official Blender Foundation tool, not a third-party one)
You're using the **official Blender Lab MCP server** (blender.org/lab/mcp-server, source at projects.blender.org/lab/blender_mcp, v1.0.0). This is a genuinely different tool than the third-party asset-generation servers that exist in this space — worth being precise about, since it changes what belongs in this sub-loop:

- **Requires Blender 5.1+.** Three separate pieces must be installed: (1) an add-on inside Blender, (2) an MCP-compatible LLM client (the official docs walk through llama.cpp specifically), (3) the MCP server itself connecting the two.
- **What it does:** a natural-language interface over Blender's own Python API (`bpy`) — scene analysis, data-block cleanup, relationship queries, debugging, and documentation generation, all by having the connected LLM read and execute Blender Python. The official examples: finding high-polygon objects that contribute little on-screen (performance outliers), fixing data-block naming typos, querying which objects use a given material, and auto-documenting a Geometry Nodes setup.
- **What it does NOT do:** generate new 3D models from a text prompt. There's no AI mesh-generation backend built into this server (no Rodin/Meshy/TripoSR-equivalent). If you specifically want "type a description, get a new mesh," that's not what this tool provides — it's for working with Blender data that already exists, via Python automation and analysis. This directly narrows what belongs in this sub-loop compared to a generation-capable server: **this is a repair-and-diagnose loop, not a create-from-nothing loop.**

### 8.2 Security warning — read this before wiring it into any automated loop
The official docs state this plainly, and it matters a lot for a Gauntlet loop meant to run repeatedly: **the MCP server executes LLM-generated code in Blender with no guardrails protecting your data from deletion or exfiltration.** Blender's own recommendation is to run it in a VM or on a system without access to sensitive data. Practical implications for Loopkeeper:

- Don't point this server at your only copy of a `.blend` source file — work from a version-controlled or otherwise disposable copy, especially once this is wired into a repeatable automated loop rather than a one-off manual session.
- Treat any automated invocation the same way you'd treat any other LLM-generated-code-execution step: review before it runs unattended in CI, don't grant it access to anything outside the specific asset files it needs to touch.
- This is a stronger caution than anything else in this document — Godot AI's WebSocket connection is loopback-only with rotating auth; this tool's code-execution model has no equivalent protection.

### 8.3 Where this fits in the Gauntlet — diagnosis and repair, not generation
Most VERIFIED findings from Sections 4-5 are fixable with assets you already have, entirely inside Godot via Godot AI (reposition, re-material, re-light). This sub-loop is for the narrower case where the *source Blender data itself* needs inspecting or fixing before a Quaternius-sourced (or otherwise already-owned) mesh is right:

- A mesh contributes disproportionately to poly count relative to its on-screen footprint (the official tool's own headline use case — directly useful for keeping Loopkeeper's Zones performant, especially background/set-dressing props from the bulkier Quaternius kits).
- A mesh has bad normals, non-uniform/unapplied transforms, or a missing material assignment — all explicitly named in the official docs' own example-prompt list, and all directly explain the class of "floating/clipping/wrong-looking" critic findings from Section 3.4 when the actual cause turns out to be the source data, not Godot-side placement.
- Data-block naming or organization is inconsistent enough to slow down finding the right asset when many Quaternius packs are merged into one project.

**What this sub-loop is not for:** a genuinely missing asset with no existing source. For that, the options remain what the Art Assets doc already covers — search harder in the Quaternius/PolyHaven/Sketchfab catalogs first, and only reach for a generation-capable tool (a different, third-party server — not this one) as a last resort, with the same license-verification discipline the rest of this project already follows.

### 8.4 The sub-loop
```
1. Diagnose: point the Blender MCP server at the source .blend for the
   flagged asset, and run the relevant natural-language query — poly-count-
   vs-screen-size outlier check, bad-normals check, non-uniform-transform
   check, or "which objects use material X" depending on what Section 3.4's
   verification turned up. Use a disposable/version-controlled copy per the
   Section 8.2 warning, not the only copy of the source file.
2. If the diagnosis confirms a real source-data defect (bad normals, un-
   applied transform, wrong/missing material, excessive poly count for its
   on-screen size): have the LLM write and run the targeted Blender Python
   fix, then re-export glTF/GLB with transforms applied and PBR material
   mapping preserved, for Godot 4 import.
3. If the diagnosis finds nothing wrong at the source-data level, the
   problem is back in Godot's court — placement, import settings, or
   material override — not a Blender-side fix. Don't force a Blender-side
   change onto a problem that isn't actually there.
4. Re-import into the project via Godot AI, and run the fixed asset through
   the SAME collision/navmesh test_run suite and the SAME critic pass
   (Sections 5.C and 5.D) as any other asset before accepting the fix —
   no exemption just because the repair happened in a different tool.
5. Log the resolution in GAUNTLET_REPORT.md as ASSET_REPAIRED (Section 8.6)
   — this sub-loop repairs source data, it doesn't create new assets, so
   there's no ASSET_CREATED case here the way a generation-capable tool
   would have.
```

### 8.5 Diagnostic prompt bank (adapted from the official docs' own example list, mapped to Gauntlet categories)
Directly useful starting points for Step 1 above, since these came from Blender's own published examples rather than being invented for this doc:
- *Performance / Section 5.C (collision & scene health):* "Analyze the scene and list objects with the highest polygon count relative to their on-screen size."
- *Correctness / Section 5.C:* "Find objects that have meshes with bad normals." / "Check my scene for non-uniformly transformed mesh objects."
- *Correctness, general QA pass:* "Verify this checklist: meshes must be manifold, all objects must have materials, naming follows convention, no absolute file paths."
- *Material diagnosis, useful when a critic cohesion finding points at a specific material:* "Which objects are using the following material: `<name>`."

### 8.6 Findings log addition
Extend Section 6's `GAUNTLET_REPORT.md` format with a line whenever this sub-loop is used:
```markdown
- **Asset resolution:** ASSET_REPAIRED via Blender Lab MCP — diagnosis:
  <what the natural-language query found> — fix applied: <summary>
```

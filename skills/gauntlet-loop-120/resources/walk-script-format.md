# Walk Script Format

Used by `playwright_walk_run.js --mode script`. A JSON file describing a
sequence of key holds to replay against the game's canvas.

```json
{
  "seed": 120,
  "moves": [
    {"key": "ArrowUp", "hold_ms": 800, "label": "leave spawn heading north toward the first checkpoint"},
    {"key": "ArrowRight", "hold_ms": 400, "label": "sidestep around the rock blocking the direct path"},
    {"key": "ArrowUp", "hold_ms": 600, "label": "continue north to the checkpoint marker"},
    {"key": "Space", "hold_ms": 100, "label": "interact with the checkpoint / NPC"}
  ]
}
```

- `key` — any Playwright keyboard key name (`ArrowUp`, `KeyW`, `Space`,
  `KeyE`, etc.) — use whatever the project's real `project.godot`
  `[input]` section maps, not a guess. Run `--mode sanity` first if
  you're not sure which scheme (arrows vs WASD) is actually wired.
- `hold_ms` — how long to hold the key down before releasing.
- `label` — free text, purely for readability in the resulting
  `manifest.json` and for whoever authors the next script.

## How a script gets authored

This is intentionally a manual/agent-in-the-loop step, not automatic
pathfinding — see `TEST_HARNESS_ARCHITECTURE.md` for why. The intended
flow:

1. Run `capture_web_e2e.sh <target> sanity` first — confirms input
   reaches the game at all and tells you which key scheme is live.
2. Run `capture_web_e2e.sh <target> script <path>` with a short,
   exploratory script (2-3 moves).
3. Look at the resulting screenshots in the capture dir — did the
   player move the way the label expected? Any obstacle encountered?
4. Write the next script extending the sequence based on what you saw,
   informed by `COMPLEXITY_GRAPH.md`'s description of the current
   seed's layout if you have it (e.g. from the Godot MCP tier reading
   real scene state — see `TEST_HARNESS_ARCHITECTURE.md`'s Tier 2).
5. Repeat until you've walked from spawn to the target checkpoint, at
   which point that sequence becomes a reusable regression script —
   save it under `resources/walk-scripts/<target>.json` for future runs
   instead of re-deriving it each time.

## Reusable scripts directory

Save known-good walk scripts here as they're discovered:
`resources/walk-scripts/<biome-or-target-name>.json`. A script is only
valid for the specific seed it was authored against — since the world
is procedurally generated, a walk script for seed 120 won't necessarily
work for seed 121. Record the seed in the script's own `seed` field and
don't reuse a script across seeds without re-verifying it.

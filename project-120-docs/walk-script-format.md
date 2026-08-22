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
  `[input]` section maps.
- `hold_ms` — how long to hold the key down before releasing.
- `label` — free text, purely for readability in the resulting `manifest.json`.

# ASSET_LINKS.md — New Assets Needed

**This complements, not replaces, the project's own `ASSETS.md`** (from
Milestone 5, which already documents the Kenney tilemap assets pulled via
curl). This file covers what Milestone 5 didn't: character
sprites/animations, NPC portraits, and music/SFX — needed for the
end-to-end experience checklist's dialogue and audio items.

All links verified live. Re-check licenses at download time.

## Character sprites & animations (CC0)

- **Kenney — Animated Characters 3** (walk/idle/attack animation sets,
  matches the tile-scale of Milestone 5's existing Kenney tilemap assets
  for visual consistency)
  https://kenney.nl/assets/animated-characters-3
- **Kenney — Tiny Dungeon** (130+ sprites, fantasy-dungeon themed —
  good fit for underground/mine biomes specifically)
  https://kenney.nl/assets/tiny-dungeon
- **Kenney — full asset browser** (search for more character/prop packs
  as new biome types are added — staying within one publisher keeps the
  art style consistent, which is one of the Lane B checklist items)
  https://kenney.nl/assets?q=character

## Music (CC0 / explicitly Public Domain)

- **Kenney — RPG Audio** (50 SFX pieces — item pickup, puzzle
  success/fail stings, etc.)
  https://kenney.nl/assets/rpg-audio
- **Kenney — Interface Sounds** (UI/dialogue-box sounds)
  https://kenney.nl/assets/interface-sounds
- **Kenney — Digital Audio** (ambient/electronic layer if any biome
  wants a more otherworldly tone)
  https://kenney.nl/assets/digital-audio
- **Fantasy Game Music Tracks (CC0)** — 7 tracks, mystical/shrine/temple
  themed, good fit for calmer biomes or the home bookmark
  https://kmontesdev.itch.io/7-fantasy-music-tracks
- **Fantasy Music Mega Pack (CC0/Public Domain)** — 100+ tracks, wide
  variety, useful if different biomes want distinctly different musical
  identities. Found via itch.io's own CC0+Music+Fantasy tag browse
  (https://itch.io/game-assets/free/tag-fantasy/tag-free-music) —
  re-search there if the direct creator page link moves.

## Godot-specific packaging note

Kenney's audio packs ship as OGG. Godot 4 handles OGG natively for
`AudioStream` — no conversion needed, unlike some other engines. If
you want the smaller-CPU-cost WAV conversion some Kenney/Godot
community packages provide, that's optional, not required:
- **Kenney UI Audio, pre-packaged for Godot (WAV)**
  https://github.com/Calinou/kenney-ui-audio

## Attribution note
CC0 requires no attribution, but a `CREDITS.md` crediting Kenney and any
other named CC0 pack authors by name is good practice, same
recommendation as the other projects in this family.

- **Kenney Impact Sounds** (CC0) — 130 impact/collision/footstep audio files in `assets/audio/impact/` (https://kenney.nl/assets/impact-sounds).
- **Kenney UI Audio** (CC0) — 50 UI click/switch/rollover audio files in `assets/audio/ui/` (https://github.com/Calinou/kenney-ui-audio, https://kenney.nl/assets/ui-audio).
- **Kenney RPG Audio** (CC0) — 50 RPG item/cloth/creak/door audio files in `assets/audio/rpg/` (https://kenney.nl/assets/rpg-audio).

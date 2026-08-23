# ASSET_LINKS_ADDENDUM.md

Supplements the existing `ASSET_LINKS.md` (character/music picks from
the prior session) with picks specifically matched to the TetraForce
"GBC Zelda-inspired" aesthetic direction in
`MOVEMENT_AND_COMBAT_REFERENCE.md`. All links verified live at time of
writing — re-check licenses at download time.

## Primary recommendation: Ninja Adventure - Asset Pack (CC0)
https://pixel-boy.itch.io/ninja-adventure-asset-pack

The strongest single match for 120's needs, verified CC0 ("You can use
any and all of the assets found in this package in your own games, even
commercial ones. Attribution is not required but appreciated"):
- 50+ characters with animations and facesets
- 30+ monsters with animations, 9 bosses
- 60+ items
- Tilesets with floor autotiling, exterior and interior elements
- 100+ sound effects, 37 music tracks
- Full UI theme

A companion Godot 4.0 project is on GitHub
(https://github.com/pixel-boy/NinjaAdventure) — the asset license is
explicitly CC0 per the itch.io page; if you also want to study or reuse
the actual GDScript from that companion project, check its own repo
LICENSE file separately, since asset licensing and code licensing aren't
automatically the same thing even when published together. Multiple
comments on the itch.io page confirm people have specifically used it to
build Zelda-like adventures, so it's a proven fit for this genre, not
just a generic RPG pack.

**Aesthetic note:** this is a modern, fairly colorful 16-bit style, not
a strict 4-shade Game Boy Color palette — closer to "SNES-era top-down
action-adventure" than "actual GBC hardware limits." Good default; see
below if you want the stricter GBC look.

## Supplementary: Overworld Autotiles (CC0)
By dandelion dino — "a simple 16px Zelda-style terrain tileset." Good
lightweight overworld-biome complement to Ninja Adventure's more
detailed interior/dungeon focus. Found via itch.io's own CC0-tagged
tileset collection; search "Overworld Autotiles dandelion dino" on
itch.io to locate the current page (collection link:
https://itch.io/c/3621170/cc0-tilesets).

## If you want the stricter GBC-palette look specifically

The exact niche — "actual 4-shade Game Boy Color palette, Zelda-styled"
— is dominated by small **paid** packs rather than CC0 ones. Named
examples that surfaced during research (verify current price/license
before buying, itch.io pricing changes):
- "Zelda-Style GB Sprite Pack!" — tilesets, characters, animations,
  made to spec for GBC
- "Awakening: Complete Tileset" by Sodacoma (~$3.59) — Zelda-styled,
  designed for Game Boy Color
- "GB Oracles: Character & Interior Pack" (~$5) — explicitly "asset
  pack for Zelda-like Gameboy games"

None of these are free/CC0 — listed because they're a genuinely closer
aesthetic match than anything free found, and $1–5 each is a real option
worth considering if the stricter GBC look matters more than staying
100% no-cost. If staying fully open-source is a hard requirement, Ninja
Adventure Asset Pack + Overworld Autotiles above are the recommendation.

## Relationship to TetraForce's own art

TetraForce's `tiles/` folder has its own original GBC-styled art, but
the repo's root MIT license, while broad ("the Software" is generally
read to cover repository contents), doesn't rule out a separate license
note living inside a specific asset subfolder that this document hasn't
independently confirmed absent. If you want to use TetraForce's actual
tile art rather than the CC0 packs above, check for any license file
specifically inside `tiles/` or `maps/` before doing so — don't assume
the root MIT notice definitely extends to every asset file without a
quick look.

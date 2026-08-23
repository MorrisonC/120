# Integration Guardrails — Read Before Copying Anything

This is the one part of this skill that isn't a judgment call. A
"popular, recent Godot project" found via GitHub search is, by default,
**not** something you can copy code or assets from. Most repositories on
GitHub — including well-known, actively-maintained, star-heavy game
projects — are published for visibility, portfolio, or education, not
under a license that permits reuse. Public visibility is not a license.

## The rule

**Before copying a single file, line of code, or asset from a repo
found during research, confirm all of the following:**

1. **The repo has an explicit license file** (`LICENSE`, `LICENSE.md`,
   or equivalent) — check it directly, the same way this project's own
   docs checked TetraForce's actual `LICENSE` file rather than assuming
   from its README.
2. **The license is a real permissive open license** — MIT, Apache-2.0,
   BSD, CC0, or CC-BY are the ones to look for. GPL/AGPL are
   copyleft — technically open but carry obligations (your project
   would need to be compatibly licensed too) that are worth flagging
   back rather than assuming away.
3. **The license covers the SPECIFIC thing you want** — code and assets
   are often licensed separately even within one repo (this project's
   own `ASSET_LINKS_ADDENDUM.md` flags exactly this for TetraForce's
   `tiles/` folder). A root `LICENSE` file covering code doesn't
   automatically cover art, music, or fonts in the same repo — check
   for a separate notice in the specific subfolder you're pulling from.
4. **No explicit "non-commercial" or "personal use only" carve-out** —
   some repos add restrictions in their README even under an otherwise
   permissive-looking license; the README can narrow what the LICENSE
   file grants.

**If any of these fail, or you're not sure: don't copy.** Study the
repo for technique/pattern/approach instead (always fine — ideas,
structure, and general technique aren't copyrightable the way specific
code and art are) and write an original implementation informed by what
you learned.

## What "studying for technique" looks like vs. what copying looks like

**Fine, no license needed:** reading how a repo structures its tile
autoloading, noticing it uses a particular node hierarchy for grass/water
transitions, and building your own version of that structure with your
own tile art and your own script.

**Requires a confirmed permissive license:** copying their actual
`.tres`/`.tscn` files, their actual GDScript files (even lightly
modified), or their actual sprite/tile image files into this project.

## Attribution, when you do copy something permitted

Record it in the project's `CREDITS.md` (create one if it doesn't
exist): source repo URL, license type, what was taken, and the date.
Keep the license's required notice intact in the copied files themselves
if the license requires that (MIT and Apache-2.0 both do — don't strip
the header comment).

## Worked examples from this session

Two real cases handled this way already, useful as calibration:
- **TetraForce** (loudsmilestudios/TetraForce) — root `LICENSE` file
  confirmed as MIT, applying broadly to "the Software." Used as a
  **study reference** for movement/combat/dialogue patterns
  (`MOVEMENT_AND_COMBAT_REFERENCE.md`), with an explicit caveat flagged
  about its `tiles/`/`maps/` folders possibly carrying separate asset
  licensing not yet independently confirmed — exactly the kind of
  per-category caution this document is asking for.
- **Ninja Adventure Asset Pack** (pixel-boy) — its itch.io page
  explicitly states CC0 for the assets ("You can use any and all of the
  assets found in this package in your own games, even commercial
  ones"), confirmed directly from that statement, not inferred. Assets
  recommended for direct import in `ASSET_LINKS_ADDENDUM.md`. Its
  companion GitHub code project was explicitly flagged as needing its
  own separate license check before assuming the same CC0 terms apply
  to the code.

## If you're not sure, don't guess — flag it

Write the uncertainty into `SESSION_LOG.md` rather than making a call
either way: "found repo X, license unclear on Y, did not integrate,
flagging for a human to check" is a completely acceptable outcome for a
round of this loop. It's not a failure to leave a licensing question
open for a person to resolve.

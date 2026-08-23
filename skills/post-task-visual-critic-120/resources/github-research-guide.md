# GitHub Research Guide

Used in step 4 of the visual critic loop, when a task's captured result
fails the goal check and a real external reference would help fix it.

## Search narrowly, on the specific gap — not the whole task

"Zelda-like Godot game" returns thousands of repos, most irrelevant.
"the grass tile doesn't read as grass against the dirt path" is a much
better starting point for a search than "make the overworld biome
better." Take the critic's single named gap from step 3 and search on
that specifically.

## Signals worth checking, in rough priority order

1. **License first** — filter or skim for MIT/Apache/CC0 before
   evaluating anything else about fit. A perfect visual match with no
   usable license is a dead end per `integration-guardrails.md` — don't
   spend time evaluating fit on something you can't use.
2. **Recently active**, not just popular — a 400-star repo with no
   commits in 4 years may not reflect current Godot 4.x conventions.
   Check the commit history, not just the star count.
3. **Actually built in Godot 4.x**, not 3.x — APIs changed enough
   between major versions that a Godot 3 reference needs translation,
   not direct study.
4. **Genre/scope match** — a full commercial-scale RPG's environment
   system may be far more elaborate than what a single task needs;
   a smaller, focused demo/jam project solving exactly your gap is
   often a better reference than an enormous codebase.

## Worked example from this session

Finding TetraForce and the Ninja Adventure Asset Pack followed this
exact process:
1. Started from a specific need (movement/combat/aesthetic reference for
   a "GBC Zelda-inspired" top-down action game), not a generic search.
2. Checked TetraForce's actual `LICENSE` file directly (MIT) before
   treating it as a usable reference — didn't assume from the README.
3. Checked Ninja Adventure Asset Pack's actual license statement on its
   itch.io page (explicit CC0) before recommending it as an asset
   source, and separately flagged its companion GitHub code repo as
   needing its own independent check rather than assuming the same CC0
   terms carried over.
4. Where the aesthetic niche was dominated by non-free options (the
   strict GBC-palette packs), said so plainly instead of stretching a
   free pick to fit — see `ASSET_LINKS_ADDENDUM.md`'s honest note on
   that.

## Search query construction

Good queries are specific and short, same discipline as any other
research: 2-6 words, one concrete concept. Reformulate rather than
repeating a miss. Examples of narrowing:
- Too broad: "godot zelda game"
- Better: "godot 4 top-down tile autotiling grass path"
- Too broad: "godot dialogue system"
- Better: "godot 4 branching dialogue resource CC0"

## After finding a candidate

1. Read its `LICENSE` file directly — not the README's summary of it.
2. Check whether the specific asset/code category you want is covered
   (see `integration-guardrails.md` point 3).
3. If it passes, note the source + license in your integration and
   proceed per `integration-guardrails.md`'s attribution section.
4. If it fails the license check but the approach is genuinely useful,
   study it for technique and reimplement your own version — this is
   always available regardless of license, since ideas and general
   technique aren't what copyright restricts.

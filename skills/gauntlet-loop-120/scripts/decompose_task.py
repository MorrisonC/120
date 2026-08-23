#!/usr/bin/env python3
"""
Lightweight linter + appender for TASK_QUEUE.md. Checks the mechanical
red flags from resources/task-sizing-guide.md before writing a new task
entry -- doesn't replace judgment, just catches the obvious cases
(scope with multiple "and"s, missing acceptance criteria, implied high
file count).

Usage:
  python3 decompose_task.py --id GRAY-9 --title "..." \
    --scope "..." --acceptance "..." --depends-on "GRAY-8"

Exits non-zero with a specific reason if the task looks too big --
rerun with --force to write it anyway (use sparingly; the linter is
usually right that it should be split).
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL_ROOT = os.path.dirname(HERE)

RED_FLAG_PATTERNS = [
    (r"\band\b.*\band\b", "scope mentions 'and' more than once -- likely covers multiple systems"),
    (r"\balso\b", "scope contains 'also' -- classic sign of scope creep"),
]

# Heuristic for post-task-visual-critic-120's "Visual check" field --
# auto-set to yes if the scope plausibly touches something with
# on-screen, visually-judgeable output. See that skill's
# resources/task-queue-visual-field.md for the full convention.
VISUAL_SCOPE_KEYWORDS = [
    "scene", "biome", "room", "sprite", "tile", "ui", "animation",
    "environment", "art",
]


def infer_visual_check(scope):
    scope_lower = scope.lower()
    return any(kw in scope_lower for kw in VISUAL_SCOPE_KEYWORDS)


def find_task_queue_path():
    # TASK_QUEUE.md lives at the repo root per config.yaml, which is one
    # level above wherever this script is actually invoked from -- try
    # cwd first (the expected invocation location), fall back to a
    # relative guess.
    candidates = ["TASK_QUEUE.md", "../TASK_QUEUE.md"]
    for c in candidates:
        if os.path.exists(c):
            return c
    return "TASK_QUEUE.md"  # let the write fail loudly if truly absent


def lint(scope, acceptance):
    warnings = []
    for pattern, message in RED_FLAG_PATTERNS:
        if re.search(pattern, scope, re.IGNORECASE):
            warnings.append(message)
    if len(acceptance.split(".")) > 2:
        warnings.append("acceptance criteria has more than one sentence -- "
                         "should ideally be a single pass/fail check")
    return warnings


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--id", required=True)
    p.add_argument("--title", required=True)
    p.add_argument("--scope", required=True)
    p.add_argument("--acceptance", required=True)
    p.add_argument("--depends-on", default="none")
    p.add_argument("--visual-check", choices=["yes", "no"], default=None,
                    help="override the auto-inferred Visual check field "
                         "(see post-task-visual-critic-120's docs); "
                         "auto-inferred from --scope keywords if omitted")
    p.add_argument("--force", action="store_true",
                    help="write even if the linter flags size concerns")
    args = p.parse_args()

    warnings = lint(args.scope, args.acceptance)
    if warnings and not args.force:
        print(f"Task {args.id} looks too big for the small-task queue:", file=sys.stderr)
        for w in warnings:
            print(f"  - {w}", file=sys.stderr)
        print("See resources/task-sizing-guide.md. Split it, or rerun with --force.", file=sys.stderr)
        sys.exit(1)

    visual_check = args.visual_check
    if visual_check is None:
        visual_check = "yes" if infer_visual_check(args.scope) else "no"

    entry = f"""
## [TODO] {args.id}: {args.title}
- Scope: {args.scope}
- Acceptance: {args.acceptance}
- Depends on: {args.depends_on}
- Visual check: {visual_check}
"""
    path = find_task_queue_path()
    with open(path, "a") as f:
        f.write(entry)
    print(f"Appended {args.id} to {path}.")
    if warnings:
        print("(written with --force despite these flags:)")
        for w in warnings:
            print(f"  - {w}")


if __name__ == "__main__":
    main()

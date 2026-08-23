#!/usr/bin/env python3
"""
Extracts one task's full entry (title, Scope, Acceptance, Visual check)
from TASK_QUEUE.md by ID, writing it to a standalone task_goal.md the
visual critic step reads alongside the screenshots. Reuses the same
fenced-code-block-aware parsing discipline as gauntlet-loop-120's
list_targets.py (which had a real bug here once -- see that file's
comments -- so this mirrors the fix rather than re-introducing it).
"""
import argparse
import os
import re
import sys

TASK_HEADER_RE = re.compile(r"^## \[(\w+)\] ([\w-]+): (.+)$")


def find_task_entry(path, task_id):
    if not os.path.exists(path):
        return None
    lines_out = []
    current_id = None
    in_code_fence = False
    capturing = False
    with open(path) as f:
        for line in f:
            stripped = line.rstrip("\n")
            if stripped.strip().startswith("```"):
                in_code_fence = not in_code_fence
                continue
            if in_code_fence:
                continue

            m = TASK_HEADER_RE.match(stripped)
            if m:
                if capturing:
                    break  # hit the next task header -- current one is done
                current_id = m.group(2)
                if current_id == task_id:
                    capturing = True
                    lines_out.append(stripped)
                continue

            if capturing:
                if stripped.strip() == "":
                    break
                lines_out.append(stripped)

    return "\n".join(lines_out) if lines_out else None


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--task-queue", required=True)
    p.add_argument("--task-id", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()

    entry = find_task_entry(args.task_queue, args.task_id)
    if entry is None:
        print(f"No entry found for {args.task_id} in {args.task_queue}", file=sys.stderr)
        # Write an empty file so the caller's -s check fails cleanly
        # rather than leaving a stale file from a previous run.
        open(args.out, "w").close()
        sys.exit(1)

    with open(args.out, "w") as f:
        f.write(f"# Task Goal: {args.task_id}\n\n")
        f.write(entry + "\n")

    print(f"Wrote {args.out}")


if __name__ == "__main__":
    main()

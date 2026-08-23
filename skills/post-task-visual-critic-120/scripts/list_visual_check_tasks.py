#!/usr/bin/env python3
"""
Scans TASK_QUEUE.md for tasks with Visual check: yes -- surfaces which
ones still need a visual-critic pass (no state/<id>.yaml yet, or one
that isn't 'passed') before being marked DONE.

Reuses the fenced-code-block-aware parsing discipline established in
gauntlet-loop-120/scripts/list_targets.py.
"""
import os
import re
import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL_ROOT = os.path.dirname(HERE)

TASK_HEADER_RE = re.compile(r"^## \[(\w+)\] ([\w-]+): (.+)$")
FIELD_RE = re.compile(r"^- (\w[\w ]*): (.+)$")


def load_yaml(path, default=None):
    if not os.path.exists(path):
        return default if default is not None else {}
    with open(path) as f:
        return yaml.safe_load(f) or {}


def parse_tasks(path):
    """Returns list of {id, status, title, fields: {...}}."""
    if not os.path.exists(path):
        return []
    tasks = []
    current = None
    in_code_fence = False
    with open(path) as f:
        for line in f:
            line = line.rstrip("\n")
            if line.strip().startswith("```"):
                in_code_fence = not in_code_fence
                continue
            if in_code_fence:
                continue
            m = TASK_HEADER_RE.match(line)
            if m:
                if current:
                    tasks.append(current)
                current = {"status": m.group(1), "id": m.group(2), "title": m.group(3), "fields": {}}
                continue
            if current:
                fm = FIELD_RE.match(line.strip())
                if fm:
                    current["fields"][fm.group(1).strip()] = fm.group(2).strip()
        if current:
            tasks.append(current)
    return tasks


def main():
    cfg = load_yaml(os.path.join(SKILL_ROOT, "assets", "config.yaml"))
    tasks = parse_tasks(cfg.get("task_queue_file", "TASK_QUEUE.md"))
    state_dir = cfg.get("state_dir", "state")

    visual_tasks = [t for t in tasks if t["fields"].get("Visual check", "no").lower() == "yes"]

    print(f"{len(visual_tasks)} task(s) flagged Visual check: yes\n")
    print(f"{'TASK':<12} {'TASK STATUS':<12} {'VISUAL CRITIC STATUS':<22} ROUNDS")
    for t in visual_tasks:
        state = load_yaml(os.path.join(state_dir, f"{t['id']}.yaml"),
                           default={"status": "not_started", "rounds": 0})
        print(f"{t['id']:<12} {t['status']:<12} {state.get('status', 'not_started'):<22} {state.get('rounds', 0)}")

    # Two distinct concerns, not one: whether the visual critic has
    # passed (state/<id>.yaml's own status), and whether TASK_QUEUE.md's
    # own [TODO]/[DONE] marker has been updated to reflect that. A task
    # can be critic-passed but still marked TODO in the queue simply
    # because nobody's flipped it to DONE yet -- that's not the same as
    # needing another check.
    needing_check = [
        t for t in visual_tasks
        if load_yaml(os.path.join(state_dir, f"{t['id']}.yaml")).get("status") != "passed"
    ]
    ready_to_mark_done = [
        t for t in visual_tasks
        if t["status"] != "DONE"
        and load_yaml(os.path.join(state_dir, f"{t['id']}.yaml")).get("status") == "passed"
    ]

    print()
    if needing_check:
        print(f"NEXT TO VISUALLY CHECK: {needing_check[0]['id']}")
    else:
        print("All visual-check-flagged tasks have passed their visual critic check.")
    if ready_to_mark_done:
        ids = ", ".join(t["id"] for t in ready_to_mark_done)
        print(f"READY TO MARK DONE in TASK_QUEUE.md (critic passed, queue status not yet updated): {ids}")


if __name__ == "__main__":
    main()

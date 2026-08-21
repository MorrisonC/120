#!/usr/bin/env python3
"""
Prints the next actionable work, checking TWO queues:
  1. TASK_QUEUE.md's small Lane A tasks (functional work) -- shown first
     since GRAY-* tasks are P0 and block everything else.
  2. assets/targets.yaml's Lane B gauntlet targets -- shown only once
     their prerequisite TASK_QUEUE.md epic is fully DONE and their GUT
     prerequisite suite(s) pass.

Doesn't run tests or the gauntlet loop itself -- purely a "what's next"
view over the two state sources.
"""
import os
import re
import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL_ROOT = os.path.dirname(HERE)

TASK_HEADER_RE = re.compile(r"^## \[(\w+)\] ([\w-]+): (.+)$")
DEPENDS_RE = re.compile(r"^- Depends on: (.+)$")


def load_yaml(path, default=None):
    if not os.path.exists(path):
        return default if default is not None else {}
    with open(path) as f:
        return yaml.safe_load(f) or {}


def parse_task_queue(path):
    """Returns list of {id, status, title, depends_on: [ids]}.

    Skips fenced code blocks (```...```) so the literal format example
    at the top of TASK_QUEUE.md ("## [STATUS] TASK-ID: short title")
    doesn't get parsed as a real task -- caught by testing this against
    the actual file before shipping.
    """
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
                current = {"status": m.group(1), "id": m.group(2), "title": m.group(3), "depends_on": []}
                continue
            if current:
                d = DEPENDS_RE.match(line.strip())
                if d:
                    dep_str = d.group(1).strip()
                    if dep_str.lower() != "none":
                        current["depends_on"] = [x.strip() for x in dep_str.split(",")]
        if current:
            tasks.append(current)
    return tasks


def next_task_queue_item(tasks):
    status_by_id = {t["id"]: t["status"] for t in tasks}
    for t in tasks:
        if t["status"] != "TODO":
            continue
        unmet = [d for d in t["depends_on"] if status_by_id.get(d) != "DONE"]
        if not unmet:
            return t
    return None


def main():
    cfg = load_yaml(os.path.join(SKILL_ROOT, "assets", "config.yaml"))
    task_queue_path = cfg.get("task_queue_file", "TASK_QUEUE.md")

    print("=== Lane A: TASK_QUEUE.md ===")
    tasks = parse_task_queue(task_queue_path)
    if not tasks:
        print(f"No tasks found at {task_queue_path} (or file not found — run from repo root).")
    else:
        todo_count = sum(1 for t in tasks if t["status"] == "TODO")
        done_count = sum(1 for t in tasks if t["status"] == "DONE")
        print(f"{done_count} done, {todo_count} remaining TODO, {len(tasks)} total.")
        nxt = next_task_queue_item(tasks)
        if nxt:
            print(f"NEXT TASK: {nxt['id']} — {nxt['title']}")
        else:
            print("No unblocked TODO task found (either all done, or all TODOs have unmet dependencies).")

    print()
    print("=== Lane B: gauntlet targets (assets/targets.yaml) ===")
    targets_data = load_yaml(os.path.join(SKILL_ROOT, "assets", "targets.yaml"))
    lane_a_status = load_yaml(cfg.get("lane_a_status_file", "")).get("suites", {})
    state_dir = cfg.get("state_dir", "state")

    task_status_by_id = {t["id"]: t["status"] for t in tasks}

    for t in targets_data.get("targets", []):
        prereqs = t.get("lane_a_prerequisite", [])
        unmet = []
        for prereq in prereqs:
            if prereq in task_status_by_id:
                if task_status_by_id[prereq] != "DONE":
                    unmet.append(f"{prereq}(task:{task_status_by_id[prereq]})")
            elif lane_a_status.get(prereq) != "passed":
                unmet.append(f"{prereq}(suite:{lane_a_status.get(prereq, 'not run')})")

        state = load_yaml(os.path.join(state_dir, f"{t['id']}.yaml"),
                           default={"status": "not_started", "rounds": 0})
        label = "OK" if not unmet else f"BLOCKED({','.join(unmet)})"
        print(f"{t['id']:<24} lane_a={label:<40} gauntlet={state.get('status', 'not_started')}")

    print()
    print("Pull the NEXT TASK above if one exists — Lane A work is P0")
    print("(especially the gray-screen epic) before any Lane B gauntlet target can run.")


if __name__ == "__main__":
    main()

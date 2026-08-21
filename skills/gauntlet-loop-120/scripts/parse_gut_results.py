#!/usr/bin/env python3
"""
Parses GUT's -gjunit_xml_file output (standard JUnit XML: <testsuite>
per script, <testcase> per test) into per-script pass/fail, keyed by
script name so targets.yaml's lane_a_prerequisite entries can reference
them directly (e.g. "test_procedural_world_generator").
"""
import argparse
import os
import xml.etree.ElementTree as ET
import yaml


def extract_suite_results(xml_path):
    """Returns {suite_name: 'passed'|'failed'} for every testsuite."""
    results = {}
    if not os.path.exists(xml_path):
        return results
    tree = ET.parse(xml_path)
    root = tree.getroot()
    suites = root.iter("testsuite") if root.tag != "testsuite" else [root]
    for suite in suites:
        name = suite.get("name", "unknown")
        failures = int(suite.get("failures", 0))
        errors = int(suite.get("errors", 0))
        results[name] = "failed" if (failures + errors) > 0 else "passed"
    return results


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--junit", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()

    results = extract_suite_results(args.junit)

    if not results:
        print(f"WARNING: no test suites found in {args.junit}. "
              "Did run_godot_tests.sh's GUT call actually run? Check ./logs/gut_run.log.")

    with open(args.out, "w") as f:
        yaml.safe_dump({"suites": results}, f, default_flow_style=False)

    failed = [k for k, v in results.items() if v == "failed"]
    if failed:
        print(f"FAILED suites: {failed}")
    else:
        print(f"All {len(results)} parsed test suites passed.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Scene Lint: quick checks against the scene index JSON file.
"""
from __future__ import annotations
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
INDEX = ROOT / "godot_project" / "scripts" / "tools" / "scene_index.json"


def main() -> int:
    if not INDEX.exists():
        print(f"[SceneLint] Missing index: {INDEX}")
        return 1
    try:
        data = json.loads(INDEX.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[SceneLint] Failed to parse JSON: {e}")
        return 1
    scenes = data.get("scenes", [])
    if not scenes:
        print("[SceneLint] No scenes listed.")
        return 1
    missing = []
    for s in scenes:
        # Only basic validation here (path format). Godot load checked by smoke runner.
        if not str(s).startswith("res://"):
            missing.append(s)
    if missing:
        print("[SceneLint] Non-res paths found:\n- " + "\n- ".join(map(str, missing)))
        return 1
    print(f"[SceneLint] OK. {len(scenes)} scene references look valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

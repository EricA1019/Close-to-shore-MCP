#!/usr/bin/env python3
"""
API Guard: scans GDScript files for external references to private members (prefixed with `_`).

Heuristics:
- Flags usages like `obj._foo` or `obj._bar()` outside of the class where `_foo` is defined.
- Skips lines that are comments or in the same file and class where the member is declared.
- This is a best-effort static check; false positives are possible.

Exit codes:
- 0: No violations found
- 1: Violations detected
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "godot_project"

PRIVATE_ACCESS_RE = re.compile(r"[^\w]([A-Za-z_][A-Za-z0-9_]*)\._([A-Za-z0-9_]+)")
PRIVATE_DEF_RE = re.compile(r"^\s*(var|const|func)\s+_([A-Za-z0-9_]+)")

# Whitelist common Godot engine callbacks that start with underscore
ENGINE_CALLBACKS = {
    "ready", "process", "physics_process", "input", "unhandled_input", "gui_input",
    "enter_tree", "exit_tree", "notification"
}


def scan_file(path: Path) -> list[tuple[int, str]]:
    text = path.read_text(encoding="utf-8", errors="ignore").splitlines()
    private_defs: set[str] = set()
    for i, line in enumerate(text, 1):
        m = PRIVATE_DEF_RE.search(line)
        if m:
            private_defs.add(m.group(2))
    violations: list[tuple[int, str]] = []
    for i, line in enumerate(text, 1):
        if line.strip().startswith("#"):
            continue
        for m in PRIVATE_ACCESS_RE.finditer(" " + line):
            member = m.group(2)
            # Engine callbacks like _input are allowed anywhere
            if member in ENGINE_CALLBACKS:
                continue
            # If the private is defined in this file, we allow access here (class-internal)
            if member in private_defs:
                continue
            violations.append((i, line.rstrip()))
    return violations


def main(argv: list[str]) -> int:
    gd_files = [p for p in SRC_DIR.rglob("*.gd") if 
                ("/addons/" not in str(p.as_posix()) and 
                 "/tests/" not in str(p.as_posix()))]
    violations_total = 0
    for f in gd_files:
        vio = scan_file(f)
        if vio:
            print(f"[API Guard] {f}")
            for (ln, src) in vio:
                print(f"  L{ln}: {src}")
            violations_total += len(vio)
    if violations_total:
        print(f"[API Guard] Violations: {violations_total}")
        return 1
    print("[API Guard] No violations found")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        sys.exit(130)

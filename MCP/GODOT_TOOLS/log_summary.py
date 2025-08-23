#!/usr/bin/env python3
"""
Summarize latest test runner output and, if present, Godot log files.

Looks for workspace logs in ./logs/run-*-testrunner.out and prints a brief summary.
"""
from __future__ import annotations
import glob
import os
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOG_DIR = ROOT / "logs"


def summarize_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="ignore")
    passed = len(re.findall(r"\bPASSED\b", text))
    failed = len(re.findall(r"\bFAILED\b|\bFAIL\b|✗", text))
    return {"path": str(path), "passed": passed, "failed": failed, "lines": len(text.splitlines())}


def main() -> int:
    matches = sorted(glob.glob(str(LOG_DIR / "run-*-testrunner.out")))
    if not matches:
        print("[LogSummary] No test runner outputs found under logs/")
        return 0
    latest = Path(matches[-1])
    s = summarize_file(latest)
    print(f"[LogSummary] Latest: {s['path']}")
    print(f"[LogSummary] Lines: {s['lines']} | Passed tokens: {s['passed']} | Failed tokens: {s['failed']}")
    # Print tail
    text = latest.read_text(encoding="utf-8", errors="ignore").splitlines()
    tail = "\n".join(text[-40:])
    print("\n[LogSummary] Tail (last 40 lines):\n" + tail)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

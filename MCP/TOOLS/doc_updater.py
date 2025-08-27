#!/usr/bin/env python3
"""
Doc Updater: rule-based Markdown updater for this repo.

Features
- Dry-run by default; apply with --write
- Target files via --files or glob via --include/--exclude
- Rules:
  - std-http: Replace Flask mentions with "Python stdlib HTTP server"
  - resource-db: Prefer "Resource Database (.tres/.res)" over JSON DB phrasing
  - cts-checklists: Ensure checklist template exists under CTS sections
- Skips fenced code blocks (```)

Examples
  python3 MCP/TOOLS/doc_updater.py --include "**/*.md" --exclude "godot_project/addons/**" --dry-run
  python3 MCP/TOOLS/doc_updater.py --rules std-http resource-db --write --verbose
  python3 MCP/TOOLS/doc_updater.py --files rust/README.md godot_project/docs/RESOURCE_DB.md --write

Exit codes
  0: success
  1: invalid args
  2: runtime error
"""

from __future__ import annotations

import argparse
import fnmatch
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Tuple


RE_FENCE = re.compile(r"^\s*```")


def iter_repo_files(root: Path, includes: List[str], excludes: List[str]) -> Iterable[Path]:
    for base, _dirs, files in os.walk(root):
        rel_dir = os.path.relpath(base, root)
        for name in files:
            rel = os.path.normpath(os.path.join(rel_dir, name))
            # Always work with forward slashes for matching
            rel_slash = rel.replace(os.sep, "/")
            if includes and not any(fnmatch.fnmatch(rel_slash, pat) for pat in includes):
                continue
            if any(fnmatch.fnmatch(rel_slash, pat) for pat in excludes):
                continue
            yield root / rel


def replace_outside_code_fences(text: str, pattern: re.Pattern, repl: str) -> Tuple[str, int]:
    """Apply regex replacement only outside fenced code blocks.

    Returns (new_text, replacements_count)
    """
    parts = []
    count = 0
    in_fence = False
    for line in text.splitlines(keepends=True):
        if RE_FENCE.match(line):
            in_fence = not in_fence
            parts.append(line)
            continue
        if in_fence:
            parts.append(line)
            continue
        new_line, n = pattern.subn(repl, line)
        parts.append(new_line)
        count += n
    return ("".join(parts), count)


def rule_std_http(text: str) -> Tuple[str, int]:
    # Replace Flask mentions gently; avoid double replacements if already updated.
    patterns = [
        (re.compile(r"\b[Ff]lask\b"), "Python stdlib HTTP server"),
    ]
    total = 0
    for pat, repl in patterns:
        text, n = replace_outside_code_fences(text, pat, repl)
        total += n
    return text, total


def rule_resource_db(text: str) -> Tuple[str, int]:
    total = 0
    # Prefer "Resource Database (.tres/.res)" over various JSON DB phrasings
    replacements = [
        (re.compile(r"\bJSON\s*(?:db|database)s?\b", re.IGNORECASE), "Resource Database (.tres/.res)"),
        (re.compile(r"\bJSON-based\s*(?:db|database)\b", re.IGNORECASE), "Resource Database (.tres/.res)"),
        (re.compile(r"\bdata/layouts/apartment\.json\b"), "data/layouts/apartment.tres"),
    ]
    for pat, repl in replacements:
        text, n = replace_outside_code_fences(text, pat, repl)
        total += n

    # Gentle terminology modernization
    text, n = replace_outside_code_fences(
        text, re.compile(r"\bJSON\s+files?\b", re.IGNORECASE), "Resource files"
    )
    total += n

    return text, total


CHECKLIST_TEMPLATE = (
    "\n### Checklist\n\n"
    "- Requirements\n"
    "  - ...\n"
    "- Contracts (inputs/outputs)\n"
    "  - ...\n"
    "- Tests (happy + edge)\n"
    "  - ...\n"
    "- DoD\n"
    "  - ...\n"
)


def ensure_checklist_under_section(text: str, section: str) -> Tuple[str, int]:
    """Ensure a '### Checklist' exists under the given H2 section until the next H2.

    Returns (new_text, changes_count)
    """
    # Find the section start
    h2_pattern = re.compile(rf"^##\s+{re.escape(section)}\s*$", re.MULTILINE)
    m = h2_pattern.search(text)
    if not m:
        return text, 0
    start = m.end()
    # Find next H2 after start
    next_h2 = re.search(r"^##\s+", text[start:], re.MULTILINE)
    end = start + next_h2.start() if next_h2 else len(text)
    segment = text[start:end]
    if re.search(r"^###\s+Checklist\s*$", segment, re.MULTILINE):
        return text, 0
    # Insert template at the end of the section
    new_text = text[:end] + CHECKLIST_TEMPLATE + text[end:]
    return new_text, 1


def rule_cts_checklists(text: str) -> Tuple[str, int]:
    total = 0
    for sec in [
        "CTS DB (Resource Database)",
        "CTS DB",
        "CTS (Close-to-Shore) Rust Tooling",
    ]:
        text, n = ensure_checklist_under_section(text, sec)
        total += n
    return text, total


RULES_MAP = {
    "std-http": rule_std_http,
    "resource-db": rule_resource_db,
    "cts-checklists": rule_cts_checklists,
}


@dataclass
class UpdateResult:
    path: Path
    changes: int
    bytes_delta: int


def process_file(path: Path, rule_names: List[str], write: bool, verbose: bool) -> UpdateResult:
    try:
        original = path.read_text(encoding="utf-8")
    except Exception as e:
        if verbose:
            print(f"! Skipping {path}: {e}")
        return UpdateResult(path, 0, 0)

    text = original
    total_changes = 0
    for name in rule_names:
        func = RULES_MAP[name]
        text, n = func(text)
        total_changes += n

    if write and total_changes > 0 and text != original:
        path.write_text(text, encoding="utf-8")
    return UpdateResult(path, total_changes, len(text) - len(original))


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(description="Auto-update Markdown docs with safe rules.")
    parser.add_argument("--files", nargs="*", default=[], help="Explicit files to process")
    parser.add_argument(
        "--include",
        nargs="*",
        default=["**/*.md"],
        help="Glob patterns to include (default: **/*.md)",
    )
    parser.add_argument(
        "--exclude",
        nargs="*",
        default=[
            "**/.git/**",
            "**/.tools/**",
            "**/node_modules/**",
            "godot_project/addons/**",
        ],
        help="Glob patterns to exclude",
    )
    parser.add_argument(
        "--rules",
        nargs="*",
        default=["std-http", "resource-db", "cts-checklists"],
        choices=list(RULES_MAP.keys()),
        help="Rules to apply",
    )
    parser.add_argument("--write", action="store_true", help="Write changes to files")
    parser.add_argument("--dry-run", action="store_true", help="Alias for not --write")
    parser.add_argument(
        "--fail-on-changes",
        action="store_true",
        help="Exit with non-zero status if changes would be made (useful for CI)",
    )
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args(argv)

    root = Path(__file__).resolve().parents[2]

    files: List[Path] = []
    if args.files:
        files = [root / Path(p) if not os.path.isabs(p) else Path(p) for p in args.files]
    else:
        files = list(iter_repo_files(root, args.include, args.exclude))

    if not files:
        print("No files matched.")
        return 0

    write = bool(args.write) and not args.dry_run

    results: List[UpdateResult] = []
    total_changes = 0
    for p in files:
        res = process_file(p, args.rules, write, args.verbose)
        total_changes += res.changes
        if args.verbose and res.changes:
            print(f"Changed {p} (+{res.bytes_delta} bytes) with {res.changes} edits")
        results.append(res)

    changed_files = [r for r in results if r.changes > 0]
    print(
        f"Files scanned: {len(results)} | Files with changes: {len(changed_files)} | Total edits: {total_changes} | Write: {write}"
    )

    if not write and changed_files:
        print("Dry-run: no files written. Use --write to apply changes.")
        if args.fail_on_changes:
            return 3

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main(sys.argv[1:]))
    except KeyboardInterrupt:
        print("Interrupted.")
        raise SystemExit(130)

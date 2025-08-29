#!/usr/bin/env python3
"""
Purge Empty Files

Finds zero-byte files under one or more roots and deletes them (optional).

Usage examples:
  - Dry-run, default excludes (.git):
      python3 MCP/TOOLS/purge_empty_files.py --roots .
  - Dry-run with custom excludes:
      python3 MCP/TOOLS/purge_empty_files.py --roots . \
          --exclude '.git/**' --exclude 'rust/target/**' --exclude 'godot_project/.godot/**'
  - Actually delete:
      python3 MCP/TOOLS/purge_empty_files.py --roots godot_project --delete

Notes:
  - Skips symlinks.
  - Skips files named in --ignore-names (default: .gitkeep, .keep).
  - Supports glob patterns with ** for includes/excludes.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import fnmatch
from typing import Iterable, List, Set

DEFAULT_EXCLUDES = [
    ".git/**",
]
DEFAULT_IGNORE_NAMES = [
    ".gitkeep",
    ".keep",
]


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Find and delete zero-byte files.")
    p.add_argument(
        "--roots",
        nargs="+",
        default=["."],
        help="Root directories to scan (default: .)",
    )
    p.add_argument(
        "--include",
        dest="includes",
        action="append",
        default=[],
        help="Glob pattern to include (can be used multiple times). If provided, only matching files are considered.",
    )
    p.add_argument(
        "--exclude",
        dest="excludes",
        action="append",
        default=[],
        help="Glob pattern to exclude (can be used multiple times).",
    )
    p.add_argument(
        "--ignore-names",
        dest="ignore_names",
        action="append",
        default=[],
        help="File basenames to ignore from deletion (can be used multiple times).",
    )
    p.add_argument(
        "--delete",
        action="store_true",
        help="Actually delete files. Without this flag, runs in dry-run mode.",
    )
    p.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Verbose output (list each file).",
    )
    return p.parse_args()


def norm_patterns(patterns: Iterable[str]) -> List[str]:
    out = []
    for p in patterns:
        if not p:
            continue
        out.append(p.replace("\\", "/"))
    return out


def matches_any(rel: str, patterns: Iterable[str]) -> bool:
    for pat in patterns:
        if fnmatch.fnmatch(rel, pat):
            return True
    return False


def should_skip_dir(rel_dir: str, excludes: Iterable[str]) -> bool:
    # If a directory path plus '/**' matches an exclude pattern, skip
    rel_with_glob = rel_dir.rstrip("/") + "/**"
    return matches_any(rel_with_glob, excludes)


def find_empty_files(roots: Iterable[Path], includes: List[str], excludes: List[str], ignore_names: Set[str], verbose: bool = False) -> List[Path]:
    empty: List[Path] = []
    for root in roots:
        if not root.exists():
            if verbose:
                print(f"[warn] Root does not exist: {root}")
            continue
        for dirpath, dirnames, filenames in os.walk(root, topdown=True):
            dir_rel = Path(dirpath).resolve().relative_to(root.resolve()).as_posix() if Path(dirpath) != root else ""
            # Prune excluded directories
            pruned = []
            for d in list(dirnames):
                sub_rel = (Path(dirpath) / d).resolve().relative_to(root.resolve()).as_posix()
                if should_skip_dir(sub_rel, excludes):
                    pruned.append(d)
            for d in pruned:
                dirnames.remove(d)
            # Process files
            for fname in filenames:
                if fname in ignore_names:
                    continue
                fpath = Path(dirpath) / fname
                try:
                    if fpath.is_symlink():
                        continue
                    size = fpath.stat().st_size
                except FileNotFoundError:
                    continue
                if size != 0:
                    continue
                rel = fpath.resolve().relative_to(root.resolve()).as_posix()
                # Include/exclude filtering
                if includes:
                    if not matches_any(rel, includes):
                        continue
                if excludes and matches_any(rel, excludes):
                    continue
                empty.append(fpath)
                if verbose:
                    print(f"[empty] {fpath}")
    return empty


def main() -> int:
    args = parse_args()
    roots = [Path(r) for r in args.roots]
    includes = norm_patterns(args.includes)
    excludes = norm_patterns(args.excludes or DEFAULT_EXCLUDES)
    ignore_names = set(args.ignore_names or DEFAULT_IGNORE_NAMES)

    empty = find_empty_files(roots, includes, excludes, ignore_names, verbose=args.verbose)
    mode = "DELETE" if args.delete else "DRY-RUN"
    print(f"Scan complete: {len(empty)} empty files found. Mode: {mode}")

    if not empty:
        return 0

    if not args.delete:
        # Show up to 50 examples
        for p in empty[:50]:
            print(f"  {p}")
        if len(empty) > 50:
            print(f"  ... and {len(empty) - 50} more")
        print("Run with --delete to remove them.")
        return 0

    # Delete files
    deleted = 0
    for p in empty:
        try:
            p.unlink(missing_ok=True)
            deleted += 1
            if args.verbose:
                print(f"[deleted] {p}")
        except Exception as e:
            print(f"[error] Failed to delete {p}: {e}")
    print(f"Deleted {deleted} files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

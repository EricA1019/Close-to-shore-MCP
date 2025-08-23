#!/usr/bin/env python3
"""
Release Helper (stub): prints commands to tag and push. Extend as needed.
"""
from __future__ import annotations
import argparse


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("tag", help="Semver tag to create, e.g., v0.1.1")
    args = ap.parse_args()
    print("# Next steps:")
    print(f"git tag -a {args.tag} -m 'Release {args.tag}'")
    print("git push --tags")
    print("# Update CHANGELOG.md accordingly.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

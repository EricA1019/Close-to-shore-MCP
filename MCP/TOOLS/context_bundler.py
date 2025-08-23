#!/usr/bin/env python3
"""
Context Bundler: Builds a single .mcp_context/context_bundle.md from key project docs.

Inputs (optional):
- AGENT_PROMPT.md
- MCP/CLOSE_TO_SHORE.md
- MCP/TEST_POLICY.md
- MCP/GODOT_WORKFLOW.md
- MCP/PLUGINS.md
- README.md

Output:
- .mcp_context/context_bundle.md
"""
from __future__ import annotations
import os
import sys
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / ".mcp_context"
OUT_FILE = OUT_DIR / "context_bundle.md"

SOURCES = [
    ROOT / "AGENT_PROMPT.md",
    ROOT / "MCP" / "CLOSE_TO_SHORE.md",
    ROOT / "MCP" / "TEST_POLICY.md",
    ROOT / "MCP" / "GODOT_WORKFLOW.md",
    ROOT / "MCP" / "PLUGINS.md",
    ROOT / "README.md",
]

def read_file(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except Exception as e:
        return f"<!-- Skipped {p} ({e}) -->\n"


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    parts = [
        f"<!-- Context bundle generated: {datetime.utcnow().isoformat()}Z -->\n",
        f"<!-- Sources: -->\n",
    ]
    for src in SOURCES:
        parts.append(f"<!-- - {src.relative_to(ROOT)} -->\n")
    parts.append("\n\n")

    for src in SOURCES:
        if src.exists():
            rel = src.relative_to(ROOT)
            parts.append(f"\n\n---\n\n# {rel}\n\n")
            parts.append(read_file(src))
            parts.append("\n")
        else:
            parts.append(f"\n\n---\n\n# {src.name} (missing)\n\n")
            parts.append(f"<!-- {src} not found -->\n")

    OUT_FILE.write_text("".join(parts), encoding="utf-8")
    print(f"[ContextBundler] Wrote {OUT_FILE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

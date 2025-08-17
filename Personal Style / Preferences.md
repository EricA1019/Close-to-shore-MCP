# Personal Style / Preferences

A concise reference for how I like to structure code, tests, logs, and UI.

---

## Core values

- Lots of prints: verbose, tagged console output to trace flow quickly.
- Data-driven first: content in resources/JSON/DB; systems discover via folder scans.
- Avoid hard-coding: prefer tables, maps, registries over branches.
- Auto-populating UI: containers read data/state and spawn controls.
- Short hops, always green: passing tests and a bootable scene each hop.

---

## Logging style

- Bracketed tags per subsystem: [AbilityReg], [BuffReg], [StatusReg], [TurnMgr], [CombatMgr], [UI], [Entity].
- Concise messages with parameters.
- Never silently fail: use warnings/errors for exceptional conditions.
- TODO markers inline: # TODO(tag): explanation

Tiny helper (example)

```gdscript
# scripts/systems/Log.gd
extends Node
class_name Log

static func p(tag:String, args:Array=[]):
	print("[", tag, "] ", " ".join(args.map(func(a): return str(a))))
```

Usage:

```gdscript
Log.p("UI", ["populate", names])
```

---

## Data-driven conventions

- Use Resources for gameplay-visible data when possible.
- Names/IDs as keys for registries; .resource_name authoritative.
- Recursive folder scans under data roots; skip hidden.
- Tables over branches; dictionary maps for type→effect.

---

## UI principles

- Structured containers drive everything.
- Public API only on UI nodes: populate, clear, bind, show_turn, update_hp.
- Zero hard-wired asset paths (allow safe fallbacks).

---

## Architecture

- Singletons (autoloads): registries, EventBus, optional DamageTable.
- Managers as nodes/services; prefer signals over lookups.
- IDs only when needed; resolve on use.

---

## Testing habits

- Every feature has a test_* beside it in tests folders.
- Public API only; no private peeking.
- Leak hygiene where applicable; assert no new orphans in Godot tests.
- Integration smoke tests for vertical slices.

---

## Code style quick list

- End files with #EOF comment.
- Functions ≤ ~40 lines; split when growing.
- Guard clauses; return early.
- Typing: explicit where it aids clarity; allow untyped Array for heterogeneous results.
- Error handling: assert for programmer errors; warnings for recoverable data issues; errors for critical failures.

---

## VS Code & tasks

- One-key tests tasks and fast slices.
- Ensure engine binary on PATH for CLI runs.

---

## Commit messages

- Format: feat(ui): initiative bar populates from turn order
- Others: fix, test, refactor, perf, chore

---

This document captures preferences; defer to Close-to-Shore Bible for process.

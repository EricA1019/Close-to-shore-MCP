# Close-to-Shore Bible (System-Agnostic)

Short hops, loud logs, data-driven content, always-green tests.

## 0) Core Principles
- Short hops: tiny, runnable vertical slices.
- Always green: tests pass and the program boots without errors.
- Data-driven first: content lives in data files (JSON/DB/resources); systems discover content.
- Avoid hard-coding: prefer tables/registries over branches.
- Auto-populated UI: containers spawn controls based on data/state.
- Traceable logs: tagged logs; never silently fail.

Definition of Done (per hop)
1) Unit + integration + smoke + game-flow tests green
2) Data schemas validated (JSON or DB migrations applied)
3) App boots and demonstrates the hop feature
4) Player test completed and documented
5) Logs clean of unexpected warnings/errors
6) No hard-wired paths (safe fallbacks allowed)
7) Commit + tag; docs updated

## Workflow (6 steps)
1) Planning & Setup: read ROADMAP/INDEX, set scope, baseline tests, boot validation
2) Test-First: write failing tests (unit/integration/game-flow), author schemas
3) Implement: iterate to green, run often
4) Integrate & Validate: full suite, schema checks, manual boot
5) Player Validation: ask human to play; document feedback
6) Docs & Completion: update docs, tag, propose improvements

## Project Layout (example)
- src or res: code and scenes
- data: JSON/resources and SQL migrations
- tests: unit, integration, smoke, game_flow, scratch
- docs: roadmap, index, playtests, technical notes

## Dependencies (example)
- Tests: GUT (Godot) or PyTest (Python) or JUnit (Java)
- Logging: platform logger; tagged prefixes
- Data: JSON schemas and/or DB migrations

## Logging & Observability (example)
- Tag by subsystem: [UI], [DB], [TurnMgr], [CombatMgr]
- Use platform warnings/errors; avoid silent failure

## Data-Driven Conventions
- Resource names/IDs are authoritative
- Recursive discovery under data folders
- Tables over long conditional chains

## Architecture
- Singletons/autoloads for shared registries and event bus
- Managers as scene/service objects, not global
- Prefer signals/events over direct lookups

## UI Principles
- Public API only on UI nodes: populate, bind, show_turn, update
- Zero hard-wired paths in code (use resource/meta)

## Comprehensive Testing Strategy
- Unit: component isolation
- Integration: cross-system workflows
- Smoke: critical end-to-end boot paths
- Game-flow: user journeys
- JSON Schema validation or DB migration checks
- Scratch tests: git-ignored and purged at hop end

## CLI & Tasks (example)
- Makefile or VSCode tasks mirror: run app, run tests, validate data

## File Header (optional)
- Keep a top comment with: Purpose, Last-Updated, Version

## Prompting LLMs
- State constraints, folders, test-first, and logging expectations

Living document — refine as habits evolve.

Local reference docs (offline mirrors)

This repo maintains a small set of local documentation mirrors to support offline development and fast, reliable search for agents and tools.

What gets mirrored (via `cts docs fetch`):
- Rust Book → `docs/rust-book/` (index.html)
- Godot Rust (GDext) API docs → `godot_project/docs/GODOT_RUST_GDEXT/`
- GUT docs → `godot_project/docs/GUT_DOCS/gut.readthedocs.io/`
- Resource Databases wiki → `godot_project/docs/ResourceDatabases/ResourceDatabases.wiki/`

How to manage docs
- Fetch or refresh mirrors:
	- VS Code task: "CTS: Docs Fetch"
	- Or CLI: `./rust/target/release/cts docs fetch`
- List available mirrors:
	- CLI: `./rust/target/release/cts docs list`
- Search locally (simple grep-based):
	- VS Code task: "CTS: Docs Search" (prompts for a query)
	- Or CLI: `./rust/target/release/cts docs search <query>`

Notes
- Mirrors are minimal and may not include every asset (images/indices). For the latest versions, prefer upstream sites.
- HTTP fetching uses ETag caching where possible to avoid redundant downloads.
- The context bundle includes a small manifest pointing at these mirrors to help agents discover them.

Last updated: 2025-08-26

# Godot Rust Extension (GDExtension) — Implementation Checklist

Date: 2025-08-26  
Repo: Close-to-shore-MCP  
Project root: `/home/eric/BrokenDivinityDemo`

Purpose: Add a Rust-based Godot 4 GDExtension to this project, wired into the existing Rust workspace, VS Code tasks, tests, and CI. Start with a minimal “Hello” Node, then grow features.

## Scope and Success Criteria

- [ ] Provide a new Rust crate that builds a Godot GDExtension shared library (cdylib).
- [ ] Load the extension in `godot_project` via a `.gdextension` config and confirm it initializes and logs at runtime (Editor and headless).
- [ ] Expose one Node with at least one exported property and method callable from GDScript.
- [ ] Add VS Code tasks to build and copy the library into `godot_project/bin` for hot-reload.
- [ ] Add a headless test that instantiates the Node and calls a method (pass/fail visible in CI logs).
- [ ] Add CI job/step to build the extension and run the headless test on Linux.
- [ ] Document usage and troubleshooting in `docs/`.

Non-goals (v1):
- No cross-compilation setup beyond Linux. macOS/Windows can be added later.
- No complex API surface; we’ll keep v1 minimal and type-safe.

## Prerequisites

- [ ] Godot 4.5 (beta6 or stable) is available (we already manage via `cts engine`).
- [ ] Rust toolchain stable (already configured in CI).
- [ ] Confirm `godot` Rust crate version compatibility with our Godot version (target latest 0.14+ that supports Godot 4.5).
- [ ] Download/setup template or bindings:
  - [ ] Option A (recommended): `cargo generate` using the official gdextension template (pins crate versions).
  - [ ] Option B: Add `godot = "^0.14"` manually and scaffold from scratch (this repo’s approach).
  - [ ] Verify license and pin exact versions in `Cargo.lock` for reproducibility.

## Plan of Record

### 1) Workspace wiring

- [ ] Add a new member crate `gdext` to `rust/Cargo.toml` (workspace).  
  - Type: `cdylib`.  
  - Dependencies: `godot = "^0.14"` (adjust to latest), `anyhow` (optional), `tracing` (optional), `serde` (optional for config/JSON).
- [ ] Ensure release profile aligns with small shared libs (e.g., `lto = true`, `opt-level = "s"` if desired). Keep defaults initially.
- [ ] Confirm crate builds with `cargo build -p gdext`.

### 2) Crate skeleton

- [ ] `rust/gdext/Cargo.toml` with `crate-type = ["cdylib"]` and `name = "gdext"` (or project-specific).
- [ ] `lib.rs` registers the extension entry points using `godot::prelude::*` and `#[gdextension]` / `init` function.
- [ ] Add a minimal Node class:
  - [ ] `HelloNode` deriving `GodotClass`, base `Node`.
  - [ ] Exported property `greeting: String` with default.
  - [ ] Method `say_hello(name: String) -> String` returning formatted message; log with `godot_print!` or `godot::log!`.

### 3) Godot integration artifacts

- [ ] Create `godot_project/bin/` (if missing) to store platform libs.
- [ ] Add `.gdextension` file, e.g., `godot_project/native/gdext.gdextension` with platform mappings:
  - [ ] `linux.x86_64`: `res://bin/libgdext.so`
  - [ ] (Later) `windows.x86_64`: `res://bin/gdext.dll`
  - [ ] (Later) `macos.universal`: `res://bin/libgdext.dylib`
- [ ] Add `configuration` block with `entry_symbol` from `godot-rust` (e.g., `GDExtensionInit`).
- [ ] Ensure extension is allowed/trusted by Godot/OS:
  - [ ] Linux: place `.so` under `res://bin/` (noexec mounts can block loading; ensure repo path is on an executable filesystem).
  - [ ] macOS (later): remove quarantine attribute `xattr -d com.apple.quarantine` on `.dylib` if downloaded.
  - [ ] Windows (later): unblock DLL if downloaded from the internet (file properties > Unblock).
  - [ ] In Godot 4 Editor: if prompted about loading native code, click Allow/Trust for this extension.
  - [ ] If prompt doesn’t appear, check Project Settings (enable Advanced) for any security options that block native extensions and ensure they are enabled for development.

### 4) Build and copy workflow

- [ ] VS Code tasks:
  - [ ] "GDExt: Build (debug)" — `cargo build -p gdext` in `rust/`.
  - [ ] "GDExt: Build (release)" — `cargo build -p gdext --release`.
  - [ ] "GDExt: Copy → godot_project/bin" — copies the produced `.so` to `godot_project/bin/` with the expected name (`libgdext.so`).
  - [ ] Optional combo task to build+copy and then run Godot Editor.
- [ ] Ensure file names match the `.gdextension` platform entries.
- [ ] Download-and-allow flow (if consuming prebuilt libs): document where to fetch the `.so`/`.dll`/`.dylib`, how to verify checksum/signature, and how to mark as trusted/unblocked per OS (see above). Prefer building locally for dev.

### 5) Smoke test in Godot

- [ ] Add a small GDScript `res://tests/integration/test_gdext_hello.gd` (or reuse GUT) that:
  - [ ] Creates `HelloNode.new()` via `ClassDB.instantiate("HelloNode")` or scene with the node.
  - [ ] Calls `say_hello("World")` and asserts the expected string.
- [ ] Add a VS Code task to run the headless test (GUT or minimal runner) and fail on assertion failure.

### 6) CI integration

- [ ] In `cts-ci.yml`, add steps:
  - [ ] Build gdext (release) on Linux.
  - [ ] Copy artifact to `godot_project/bin/` and commit as a build step artifact (optional) or just use workspace.
  - [ ] Run headless Godot with the test that loads the extension and asserts behavior.
- [ ] Upload `logs/*.json` and any gdext build logs as artifacts.

### 7) Developer experience & docs

- [ ] Add `docs/GDEXTENSION_SETUP.md` explaining build, copy, hot-reload, and troubleshooting (symbol not found, ABI mismatches, wrong library name).
- [ ] Add a section to top-level `README.md` linking to the new docs and calling out the extension.

### 8) Polishing (optional in v1)

- [ ] Example Signals (emit from Rust to GDScript and subscribe in tests).
- [ ] Example Resources (Rust types exposed as resources).
- [ ] Configurable features via `Cargo.toml` to toggle parts of the extension.

## Edge Cases & Pitfalls

- [ ] Library naming mismatch: Ensure `.gdextension` file matches produced filename and path exactly per platform.
- [ ] Platform differences: `.so` vs `.dll` vs `.dylib` — we’ll start with Linux.
- [ ] Godot version mismatch: Pin `godot` crate compatible with Godot 4.5 (beta/stable) — test in CI using managed engine.
- [ ] Missing library at runtime: Confirm copy task runs before launching Godot; consider cleaning `bin/` on rebuild to avoid stale libs.
- [ ] Editor caching: Restart editor if hot-reload doesn’t pick up changes.

## Concrete File/Path Plan

- New crate: `rust/gdext/`
  - `Cargo.toml` (cdylib), `src/lib.rs`, `src/hello_node.rs`
- Godot config:
  - `godot_project/native/gdext.gdextension`
  - `godot_project/bin/libgdext.so` (Linux dev target output after copy)
- Tests:
  - `godot_project/tests/integration/test_gdext_hello.gd` (or under existing tests structure)
- Docs:
  - `godot_project/docs/GDEXTENSION_SETUP.md`

## VS Code Task Ideas (names)

- GDExt: Build (debug)
- GDExt: Build (release)
- GDExt: Copy → bin
- GDExt: Build+Copy (release)
- GDExt: Run headless hello test

## CI Steps (Linux)

- Build: `cargo build -p gdext --release` (working-directory: `rust/`)
- Copy: move `target/release/libgdext.so` to `godot_project/bin/`
- Test: headless Godot run of the hello test; fail on assertion

## Definition of Done

- [ ] Local: Editor loads `gdext.gdextension` without errors; hello Node logs on project run.
- [ ] Local: Headless test passes calling `say_hello`.
- [ ] CI: GDExt build + headless test step passes on Linux.
- [ ] Docs: Setup guide and README links exist and are accurate.

---

Appendix A — Example `.gdextension` (Linux only, v1)

```
[configuration]
entry_symbol = "gdextension_rust_init"

[libraries]
linux.x86_64 = "res://bin/libgdext.so"
```

Note: `entry_symbol` should match the symbol exported by the `godot` crate’s `#[gdextension]` macro (often `gdextension_rust_init`). We’ll confirm in code.

Appendix B — Minimal Rust class sketch (for reference)

```rust
use godot::prelude::*;

#[derive(GodotClass)]
#[class(base=Node)]
struct HelloNode {
    #[export]
    greeting: GString,
    #[base]
    base: Base<Node>,
}

#[godot_api]
impl HelloNode {
    #[func]
    fn say_hello(&self, name: GString) -> GString {
        let msg = format!("{} {}!", self.greeting.to_string(), name);
        godot_print!("{msg}");
        msg.into()
    }
}

#[gdextension]
unsafe fn init(handle: InitHandle) {
    handle.add_class::<HelloNode>();
}
```

We’ll generate the real code following this sketch.

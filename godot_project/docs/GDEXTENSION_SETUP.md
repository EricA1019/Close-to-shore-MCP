# GDExtension Setup (Rust)

This project ships a Rust-based GDExtension built with `godot-rust`.

## Build

- Debug: run the task “GDExt: Build (debug)”
- Release: run the task “GDExt: Build+Copy (release)”

The shared library is copied to `res://bin/libgdext.so` (Linux).

## Godot config

`res://native/gdext.gdextension` points to `res://bin/libgdext.so` and uses the Rust crate entry.

```
[configuration]
entry_symbol = "gdext_rust_init"
compatibility_minimum = "4.2"

[libraries]
linux.x86_64 = "res://bin/libgdext.so"
```

## Allow/Trust native code

- Linux: ensure this repo is on an executable mount (avoid `noexec`).
- macOS: remove quarantine for downloaded `.dylib`.
- Windows: Unblock downloaded DLLs (file Properties > Unblock).
- In Editor: when prompted to allow native code, select Allow/Trust.

## Smoke test

Run “GDExt: Hello headless test” which executes a GUT test that instantiates `HelloNode` and calls `say_hello`.

If loading fails, check the Godot console for native library errors (path mismatch, missing symbols, trust prompt).

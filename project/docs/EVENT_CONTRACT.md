# Event Contract (Signals + Write APIs)

This document defines the public signals and write APIs that UI and systems should rely on. Follow this for a signals-first architecture and to avoid reaching into private state.

Scope: Autoload stores and core buses. If you add a new store, document it here.

## LocationState (autoload)

- Signals
  - `location_changed(loc_name: String)` — emitted when the current location changes.
- Write API
  - `set_location(loc_name: String) -> void` — updates current location and emits `location_changed` only when `loc_name` differs from the current value (no-op guard).
- Read API
  - `get_location() -> String` — returns the current location.

## PlayerState (autoload)

- Signals
  - `health_changed(current: int, max_hp: int)` — emitted when either current or max health changes.
  - `status_changed(text: String)` — emitted when the status text changes.
- Write API
  - `set_health(cur: int, mx: int) -> void` — updates and emits only on change (no-op guard when both are equal to current values).
  - `set_status(text: String) -> void` — updates and emits only on change.
- Read API
  - `get_health() -> Dictionary` — optional convenience `{current, max}` if added in the future. For now, prefer listening to signals.

## GameClock (autoload)

- Signals
  - `time_changed(time_str: String)` — emitted when the formatted time string changes.
- Write API
  - `set_time_str(s: String) -> void` — updates and emits only on change.

## LogBus (autoload)

- Signals
  - `message(msg: String)` — emitted for each line logged.
- Write API
  - `debug/info/warn/error/log(msg: String)` — per-level logging. Console shows INFO+; file sink captures DEBUG+ to `user://logs/run-<RUN_ID>.log`.
  - `set_run_id(run_id: String)` — establishes the RUN_ID for the file sink.

## Principles

- Signals-first: UI binds to signals; don’t poll stores.
- No privates: External code must not access `_private` members. Add public getters or new signals instead.
- No-op guard: Write APIs should avoid emitting signals when values don’t change.
- Tests target signals and public APIs, not internals.

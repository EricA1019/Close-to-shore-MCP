extends Node

## Lightweight input event bus for tests and automation.
## Provides simple signals and helpers to publish actions/keys/raw events.

signal action(action: String, pressed: bool)
signal key_event(event: InputEventKey)
signal raw_event(event: InputEvent)
signal command(name: String, payload)

var enabled: bool = true

func _ready() -> void:
    # No-op; acts as a signal hub.
    pass

## Emit an input action (e.g., "ui_right").
func emit_action(action_name: String, pressed: bool = true) -> void:
    if not enabled:
        return
    emit_signal("action", action_name, pressed)

## Emit a key event (constructed in tests).
func emit_key(kev: InputEventKey) -> void:
    if not enabled or kev == null:
        return
    emit_signal("key_event", kev)

## Emit a raw input event (InputEventAction, InputEventMouse, etc.).
func emit_raw(event: InputEvent) -> void:
    if not enabled or event == null:
        return
    emit_signal("raw_event", event)

## Emit a higher-level command for systems to react to (optional).
func emit_command(cmd: String, payload = null) -> void:
    if not enabled:
        return
    emit_signal("command", cmd, payload)

extends Node

## Binds a TermLabel's text to LocationState.current_location.
## Usage: attach to a node under TermRoot that has a sibling TermLabel.

@export var target_label_path: NodePath

var _label: Node = null

func _ready() -> void:
    _label = get_node_or_null(target_label_path) if target_label_path != NodePath("") else null
    if _label == null:
        # Try to resolve child named "Title" if not provided
        _label = get_parent().get_node_or_null("Title") if get_parent() else null
    _connect_location_state()
    _apply_initial()

func _connect_location_state() -> void:
    var ls := get_tree().get_root().find_child("LocationState", true, false)
    if ls and not ls.is_connected("location_changed", Callable(self, "_on_location_changed")):
        ls.connect("location_changed", Callable(self, "_on_location_changed"))

func _apply_initial() -> void:
    var ls := get_tree().get_root().find_child("LocationState", true, false)
    if ls and ls.has_method("get_location"):
        var loc: String = ls.call("get_location")
        _update_label(loc)

func _on_location_changed(loc_name: String) -> void:
    _update_label(loc_name)

func _update_label(loc_name: String) -> void:
    if _label:
        # TermLabel exposes 'text' property; set defensively
        if "text" in _label:
            _label.set("text", loc_name)
        else:
            _label.call_deferred("set", "text", loc_name)

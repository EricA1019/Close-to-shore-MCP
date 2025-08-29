extends Node

signal location_changed(loc_name: String)

var current_location: String = ""

func set_location(loc_name: String) -> void:
	# No-op guard: only emit on change
	if loc_name == current_location:
		return
	current_location = loc_name
	if has_node("/root/LogBus"):
		var lb = get_node("/root/LogBus")
		if lb and lb.has_method("info"):
			lb.call("info", "Location -> " + String(loc_name))
	emit_signal("location_changed", loc_name)

func get_location() -> String:
	return current_location

# Backwards-compatible alias used by older tests
func change_location(loc_name: String) -> void:
	set_location(loc_name)

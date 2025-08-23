extends Node

signal location_changed(loc_name: String)

var current_location: String = ""

func set_location(loc_name: String) -> void:
	current_location = loc_name
	emit_signal("location_changed", loc_name)

func get_location() -> String:
	return current_location

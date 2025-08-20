extends Node

signal location_changed(loc_name: String)

func set_location(loc_name: String) -> void:
	emit_signal("location_changed", loc_name)

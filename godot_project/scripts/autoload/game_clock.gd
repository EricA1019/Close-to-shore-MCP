extends Node

signal time_changed(time_str: String)

func set_time_str(s: String) -> void:
	emit_signal("time_changed", s)

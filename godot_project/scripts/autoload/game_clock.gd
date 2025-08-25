extends Node

signal time_changed(time_str: String)

var _time_str: String = ""

func set_time_str(s: String) -> void:
	if s == _time_str:
		return
	_time_str = s
	emit_signal("time_changed", s)

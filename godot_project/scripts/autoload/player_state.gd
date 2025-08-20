extends Node

signal health_changed(current: int, max_hp: int)
signal status_changed(text: String)

var _hp_current: int = 10
var _hp_max: int = 10

func set_health(cur: int, mx: int) -> void:
	_hp_current = cur
	_hp_max = mx
	emit_signal("health_changed", _hp_current, _hp_max)

func set_status(text: String) -> void:
	emit_signal("status_changed", text)

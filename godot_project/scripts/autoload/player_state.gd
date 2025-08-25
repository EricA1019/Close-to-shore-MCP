extends Node

signal health_changed(current: int, max_hp: int)
signal status_changed(text: String)

var _hp_current: int = 10
var _hp_max: int = 10
var _status: String = ""

func set_health(cur: int, mx: int) -> void:
	if cur == _hp_current and mx == _hp_max:
		return
	_hp_current = cur
	_hp_max = mx
	emit_signal("health_changed", _hp_current, _hp_max)

func set_status(text: String) -> void:
	if text == _status:
		return
	_status = text
	emit_signal("status_changed", text)

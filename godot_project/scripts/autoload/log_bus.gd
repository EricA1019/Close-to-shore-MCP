extends Node

signal message(msg: String)

var _queue: Array[String] = []
var max_lines := 200

func log(msg: String) -> void:
	_queue.append(msg)
	if _queue.size() > max_lines:
		_queue.pop_front()
	emit_signal("message", msg)

func get_recent() -> Array[String]:
	return _queue.duplicate()

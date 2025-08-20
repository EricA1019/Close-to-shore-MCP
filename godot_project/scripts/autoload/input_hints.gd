extends Node

var _hints := {}

func _ready() -> void:
	load_hints()

func load_hints() -> void:
	_hints = {}
	var path := "res://data/config/input_hints.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var txt: String = f.get_as_text()
		var data: Variant = JSON.parse_string(txt)
		if typeof(data) == TYPE_DICTIONARY:
			_hints = data as Dictionary

func get_hints(context: String) -> String:
	if _hints.has(context):
		return str(_hints[context])
	return str(_hints.get("default", "[E] Interact · [WASD] Move"))

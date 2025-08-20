extends ColorRect

@onready var _label: Label = Label.new()

func _ready() -> void:
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_label)
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.text = _get_hints_text()

func _get_hints_text() -> String:
	if has_node("/root/InputHints"):
		var ih = get_node("/root/InputHints")
		if ih.has_method("get_hints"):
			return str(ih.call("get_hints", "default"))
	return "[E] Interact · [WASD] Move"

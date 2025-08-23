extends ColorRect

signal action_chosen(id: String)

@onready var _hints: Label = Label.new()
@onready var _box: VBoxContainer = VBoxContainer.new()

func _ready() -> void:
	print("[ActionPanel] _ready")
	# Layout: actions box on top, hints below
	_box.name = "ActionsBox"
	add_child(_box)
	_hints.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hints.name = "Hints"
	add_child(_hints)
	_hints.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hints.text = _get_hints_text()

func _input(event: InputEvent) -> void:
	print("[ActionPanel] _input: ", event)

func _unhandled_input(event: InputEvent) -> void:
	print("[ActionPanel] _unhandled_input: ", event)

func _get_hints_text() -> String:
	if has_node("/root/InputHints"):
		var ih = get_node("/root/InputHints")
		if ih.has_method("get_hints"):
			return str(ih.call("get_hints", "default"))
	return "[E] Interact · [WASD] Move"

func clear_actions() -> void:
	print("[ActionPanel] clear_actions")
	for c in _box.get_children():
		c.queue_free()
	_hints.visible = true

func set_actions(actions: Array) -> void:
	print("[ActionPanel] set_actions count=", actions.size())
	clear_actions()
	for a in actions:
		var id := str(a.get("id", ""))
		var label := str(a.get("label", id))
		var btn := Button.new()
		btn.text = label
		btn.pressed.connect(func(): emit_signal("action_chosen", id))
		_box.add_child(btn)
	_hints.visible = actions.is_empty()

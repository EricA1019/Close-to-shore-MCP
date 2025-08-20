extends ColorRect

@onready var _label: Label = Label.new()

func _ready() -> void:
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_label)
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_process(true)
	_try_connect_logbus()
	get_tree().node_added.connect(Callable(self, "_on_node_added"))

func _process(_delta: float) -> void:
	# Hook up if LogBus appears later (tests add it dynamically)
	_try_connect_logbus()

func _try_connect_logbus() -> void:
	var root := get_tree().get_root()
	var lb: Node = root.find_child("LogBus", true, false)
	if lb and lb.has_signal("message"):
		if not lb.is_connected("message", Callable(self, "_on_log_message")):
			lb.connect("message", Callable(self, "_on_log_message"))
			_refresh_from_existing()

func _on_log_message(msg: String) -> void:
	# Prepend newest first
	if _label.text.is_empty():
		_label.text = msg
	else:
		_label.text = msg + "\n" + _label.text

func _refresh_from_existing() -> void:
	var root := get_tree().get_root()
	var lb: Node = root.find_child("LogBus", true, false)
	if lb and lb.has_method("get_recent"):
		var lines: Array = lb.call("get_recent")
		lines = lines.duplicate()
		lines.reverse()
		_label.text = "\n".join(lines)

func _on_node_added(node: Node) -> void:
	if node.name == "LogBus":
		_try_connect_logbus()

# Public helper for tests
func refresh_now() -> void:
	_try_connect_logbus()

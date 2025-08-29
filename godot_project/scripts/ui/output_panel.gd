extends Panel

@onready var _label: Label = Label.new() # Description label
@onready var _logs_label: Label = Label.new() # Logs feed label
@onready var _container: VBoxContainer = VBoxContainer.new()
var _last_description: String = ""

func _ready() -> void:
	print("[OutputPanel] _ready")
	# Rely on global theme style for Panel
	
	# Layout: Description on top, logs below
	_container.name = "Content"
	add_child(_container)
	_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Add padding around container
	_container.add_theme_constant_override("separation", 12)

	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	# Keep legacy name for compatibility with tests and other code
	_label.name = "Label"
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Improve text formatting for better readability
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_constant_override("line_spacing", 4)
	_container.add_child(_label)

	_logs_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_logs_label.name = "LogsLabel"
	_logs_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_logs_label.modulate = Color(0.8, 0.9, 1.0)
	# Smaller font for logs, but still readable
	_logs_label.add_theme_font_size_override("font_size", 14)
	_logs_label.add_theme_constant_override("line_spacing", 2)
	_container.add_child(_logs_label)
	set_process(true)
	_try_connect_logbus()
	get_tree().node_added.connect(Callable(self, "_on_node_added"))

func _exit_tree() -> void:
	# Disconnect from LogBus if connected
	var root := get_tree().get_root()
	var lb: Node = root.find_child("LogBus", true, false)
	if lb and lb.has_signal("message") and lb.is_connected("message", Callable(self, "_on_log_message")):
		lb.disconnect("message", Callable(self, "_on_log_message"))

func _input(event: InputEvent) -> void:
	print("[OutputPanel] _input: ", event)

func _unhandled_input(event: InputEvent) -> void:
	print("[OutputPanel] _unhandled_input: ", event)

func _process(_delta: float) -> void:
	# Hook up if LogBus appears later (tests add it dynamically)
	_try_connect_logbus()

func _try_connect_logbus() -> void:
	var root := get_tree().get_root()
	var lb: Node = root.find_child("LogBus", true, false)
	if lb and lb.has_signal("message"):
		if not lb.is_connected("message", Callable(self, "_on_log_message")):
			print("[OutputPanel] Connecting to LogBus")
			lb.connect("message", Callable(self, "_on_log_message"))
			_refresh_from_existing()

func _on_log_message(msg: String) -> void:
	# Prepend newest first into logs feed
	if _logs_label.text.is_empty():
		_logs_label.text = msg
	else:
		_logs_label.text = msg + "\n" + _logs_label.text

func _refresh_from_existing() -> void:
	var root := get_tree().get_root()
	var lb: Node = root.find_child("LogBus", true, false)
	if lb and lb.has_method("get_recent"):
		var lines: Array = lb.call("get_recent")
		lines = lines.duplicate()
		lines.reverse()
		_logs_label.text = "\n".join(lines)

func _on_node_added(node: Node) -> void:
	if node.name == "LogBus":
		_try_connect_logbus()

# Public helper for tests
func refresh_now() -> void:
	_try_connect_logbus()

# Public API: show a description (e.g., POI details)
func show_description(text: String) -> void:
	print("[OutputPanel] show_description:", text)
	_last_description = text
	_label.text = text

func get_last_description() -> String:
	return _last_description

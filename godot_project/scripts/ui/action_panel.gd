extends Panel

signal action_chosen(id: String)

@onready var _hints: Label = Label.new()

# Store current actions for keyboard selection
var _current_actions: Array = []

func _ready() -> void:
	print("[ActionPanel] _ready")
	# Use global theme if present; allow local overrides only if needed

	# Layout: actions hints
	_hints.name = "Hints"
	_hints.autowrap_mode = TextServer.AUTOWRAP_WORD
	# Improve text formatting for better readability
	_hints.add_theme_font_size_override("font_size", 16)
	_hints.add_theme_constant_override("line_spacing", 3)
	_hints.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_hints)
	_hints.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hints.text = _get_hints_text()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Handle number keys for action selection
		var key_code = event.keycode
		if key_code >= KEY_1 and key_code <= KEY_9:
			var action_index = key_code - KEY_1  # 0-based index
			if action_index < _current_actions.size():
				var action = _current_actions[action_index]
				var id: String
				
				# Handle both string and dictionary actions
				if typeof(action) == TYPE_STRING:
					id = str(action)
				elif typeof(action) == TYPE_DICTIONARY:
					id = str(action.get("id", str(action)))
				else:
					id = str(action)
				
				print("[ActionPanel] Selected action ", action_index + 1, ": ", id)
				emit_signal("action_chosen", id)

func _unhandled_input(event: InputEvent) -> void:
	print("[ActionPanel] _unhandled_input: ", event)

func _exit_tree() -> void:
	# Ensure no stray children linger
	for c in get_children():
		c.queue_free()

func _get_hints_text() -> String:
	if has_node("/root/InputHints"):
		var ih = get_node("/root/InputHints")
		if ih.has_method("get_hints"):
			return str(ih.call("get_hints", "default"))
	return "[E] Interact · [WASD] Move"

func clear_actions() -> void:
	# Clear the hints text instead of removing button children
	_hints.text = "[E] Interact · [WASD] Move"
	_hints.visible = true

func set_actions(actions: Array) -> void:
	print("[ActionPanel] set_actions count=", actions.size())
	_current_actions = actions  # Store for keyboard selection
	clear_actions()
	
	if actions.is_empty():
		_hints.visible = true
		return
	
	# Create keyboard-friendly action hints instead of buttons
	var action_text = ""
	for i in range(actions.size()):
		var a = actions[i]
		var label: String
		
		# Handle both string and dictionary actions
		if typeof(a) == TYPE_STRING:
			label = str(a)
		elif typeof(a) == TYPE_DICTIONARY:
			label = str(a.get("label", str(a.get("id", ""))))
		else:
			label = str(a)
		
		# Use number keys for actions (1, 2, 3, etc.)
		var key_hint = str(i + 1)
		action_text += "[" + key_hint + "] " + label
		if i < actions.size() - 1:
			action_text += "  " # Use spaces to separate actions horizontally
	
	# Show actions as text in the hints area instead of buttons
	_hints.text = action_text + "  ·  " + _get_hints_text()
	_hints.visible = true

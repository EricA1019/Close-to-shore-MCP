extends Node
## Global state data holder for debugging and development transparency

var debug_mode: bool = false
var current_scene_path: String = ""
var input_mode: String = "unknown"  # "keyboard", "mouse", "gamepad"
var last_input_event: String = ""

func _ready() -> void:
	print("[GlobalStateData] _ready - Debug helper initialized")
	
func set_debug_mode(enabled: bool) -> void:
	debug_mode = enabled
	print("[GlobalStateData] Debug mode: ", enabled)
	
func track_input(event: InputEvent) -> void:
	last_input_event = str(event)
	if event is InputEventKey:
		input_mode = "keyboard"
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		input_mode = "mouse"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		input_mode = "gamepad"
	print("[GlobalStateData] Input tracked: ", input_mode, " - ", event)

func set_current_scene(path: String) -> void:
	current_scene_path = path
	print("[GlobalStateData] Scene changed to: ", path)

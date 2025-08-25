extends Control

@onready var top_status: HBoxContainer = %TopStatus
@onready var output_panel: ColorRect = %OutputPanel
@onready var action_panel: ColorRect = %ActionPanel
@onready var debug_panel: ColorRect = %DebugPanel

const TOGGLE_DEBUG_KEY := "ui_debug_toggle"

func _ready() -> void:
	print("[MainUI] _ready: UI initialized")
	
	# Set default location to show basic room
	if has_node("/root/LocationState"):
		var location_state = get_node("/root/LocationState")
		location_state.set_location("Your Apartment")
	
	# One-shot initial ASCII render to avoid blank first frame in-editor
	var ascii_canvas: Node = get_node_or_null("%MainPanel/AsciiCanvas")
	if ascii_canvas and ascii_canvas.has_method("render"):
		ascii_canvas.call_deferred("render")
		print("[MainUI] requested AsciiCanvas initial render")

func _unhandled_input(event: InputEvent) -> void:
	print("[MainUI] _unhandled_input: ", event)
	if event.is_action_pressed(TOGGLE_DEBUG_KEY):
		print("[MainUI] Debug toggle pressed")
		debug_panel.visible = not debug_panel.visible

func _input(event: InputEvent) -> void:
	print("[MainUI] _input: ", event)

func _gui_input(event: InputEvent) -> void:
	print("[MainUI] _gui_input: ", event)

extends Control

@onready var top_status: HBoxContainer = %TopStatus
@onready var output_panel: ColorRect = %OutputPanel
@onready var action_panel: ColorRect = %ActionPanel
@onready var debug_panel: ColorRect = %DebugPanel

const TOGGLE_DEBUG_KEY := "ui_debug_toggle"

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_DEBUG_KEY):
		debug_panel.visible = not debug_panel.visible

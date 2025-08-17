extends Node
## Interface to read/write general application settings through [PlayerConfig].

const INPUT_SECTION = "InputSettings"
const AUDIO_SECTION = "AudioSettings"
const VIDEO_SECTION = "VideoSettings"
const GAME_SECTION = "GameSettings"
const APPLICATION_SECTION = "ApplicationSettings"
const CUSTOM_SECTION = "CustomSettings"

const FULLSCREEN_ENABLED = "FullscreenEnabled"
const SCREEN_RESOLUTION = "ScreenResolution"
const MUTE_SETTING = "Mute"
const MASTER_BUS_INDEX = 0
const SYSTEM_BUS_NAME_PREFIX = "_"

# Input
var default_action_events : Dictionary
var initial_bus_volumes : Array

func get_config_input_events(action_name : String, default = null) -> Array:
	var player_config_script = load("res://godot_project/scripts/player_config.gd")
	return player_config_script.get_config(INPUT_SECTION, action_name, default)

func set_config_input_events(action_name : String, inputs : Array) -> void:
	var player_config_script = load("res://godot_project/scripts/player_config.gd")
	player_config_script.set_config(INPUT_SECTION, action_name, inputs)

func _clear_config_input_events() -> void:
	var player_config_script = load("res://godot_project/scripts/player_config.gd")
	player_config_script.erase_section(INPUT_SECTION)

extends Node

const SAVE_STATE_PATH = "user://global_state.tres"
const NO_VERSION_NAME = "0.0.0"

static var current
static var current_version : String

static func _log_opened() -> void:
	if current:
		current.last_unix_time_opened = int(Time.get_unix_time_from_system())

static func _log_version() -> void:
	if current:
		current_version = ProjectSettings.get_setting("application/config/version", NO_VERSION_NAME)
		if current_version.is_empty():
			current_version = NO_VERSION_NAME
		if not current.first_version_opened:
			current.first_version_opened = current_version
		current.last_version_opened = current_version

static func _load_current_state() -> void:
	if FileAccess.file_exists(SAVE_STATE_PATH):
		current = ResourceLoader.load(SAVE_STATE_PATH)
	if not current:
		var global_state_data_script = load("res://godot_project/scripts/global_state_data.gd")
		current = global_state_data_script.new()

static func open() -> void:
	_load_current_state()
	_log_opened()
	_log_version()
	save()

static func save() -> void:
	if current:
		ResourceSaver.save(current, SAVE_STATE_PATH)

static func has_state(state_key : String) -> bool:
	if not current: return false
	return current.has_state(state_key)

static func get_or_create_state(state_key : String, state_type_path : String) -> Resource:
	if not current: return null
	return current.get_or_create_state(state_key, state_type_path)

static func reset() -> void:
	if not current: return
	current.states.clear()
	save()

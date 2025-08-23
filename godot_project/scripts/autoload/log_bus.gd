extends Node

signal message(msg: String)

var _queue: Array[String] = []
var max_lines := 200

enum Level { DEBUG, INFO, WARN, ERROR }
var console_level := Level.INFO
var file_level := Level.DEBUG
var _run_id: String = ""
var _file: FileAccess
var _file_path: String = ""

func _ready() -> void:
	# Initialize file sink lazily to avoid permissions issues in editor
	_run_id = OS.get_environment("RUN_ID")
	if _run_id == "":
		_run_id = Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "").replace(" ", "T")
	_setup_file_sink()

func _setup_file_sink() -> void:
	var dir := "user://logs"
	DirAccess.make_dir_recursive_absolute(dir)
	_file_path = dir + "/run-" + _run_id + ".log"
	_file = FileAccess.open(_file_path, FileAccess.WRITE_READ)
	if _file == null:
		push_warning("[LogBus] Failed to open log file: " + _file_path)
	else:
		_file.seek_end()
		_file.store_line("# Log start RUN_ID=" + _run_id)

func set_levels(console: int, file: int) -> void:
	console_level = console as Level
	file_level = file as Level

func set_run_id(id: String) -> void:
	_run_id = id
	_setup_file_sink()

func _should_print(level: int, min_level: int) -> bool:
	return level >= min_level

func _write_file(line: String) -> void:
	if _file != null:
		_file.store_line(line)
		_file.flush()

func _emit(line: String) -> void:
	_queue.append(line)
	if _queue.size() > max_lines:
		_queue.pop_front()
	emit_signal("message", line)

func _fmt(level: String, msg: String) -> String:
	return "[LogBus:" + level + "] " + msg

func debug(msg: String) -> void:
	_log(Level.DEBUG, msg)

func info(msg: String) -> void:
	_log(Level.INFO, msg)

func warn(msg: String) -> void:
	_log(Level.WARN, msg)

func error(msg: String) -> void:
	_log(Level.ERROR, msg)

func log(msg: String) -> void:
	# Backward-compat: treat as INFO
	_log(Level.INFO, msg)

func _log(level: int, msg: String) -> void:
	var level_names := ["DEBUG", "INFO", "WARN", "ERROR"]
	var line := _fmt(level_names[level], msg)
	if _should_print(level, console_level):
		print(line)
	if _should_print(level, file_level):
		_write_file(line)
	_emit(msg)

# Generic logging helper for Close-to-Shore projects
# Prefer the project LogBus (res://scripts/autoload/log_bus.gd) for Godot runtime,
# which writes INFO+ to console and DEBUG+ to user://logs/run-<RUN_ID>.log.
# This helper is a minimal fallback for tools and scripts.

extends Node
class_name Log

# Static logging function with bracketed tags
static func p(tag: String, args: Array = []):
	var message := _join_args(args)
	print("[", tag, "] ", message)

# Logging with different levels
static func debug(tag: String, message: String, args: Array = []):
	if OS.is_debug_build():
		p(tag + ":DEBUG", [message] + args)

static func info(tag: String, message: String, args: Array = []):
	p(tag, [message] + args)

static func warn(tag: String, message: String, args: Array = []):
	var tail := _join_args(args)
	var composed := message + (" " + tail if tail != "" else "")
	push_warning("[" + tag + "] " + composed)
	p(tag + ":WARN", [message] + args)

static func error(tag: String, message: String, args: Array = []):
	var tail := _join_args(args)
	var composed := message + (" " + tail if tail != "" else "")
	push_error("[" + tag + "] " + composed)
	p(tag + ":ERROR", [message] + args)

# Helper: Join args into a single string separated by spaces
static func _join_args(args: Array) -> String:
	if args.is_empty():
		return ""
	var parts: Array = []
	for a in args:
		parts.append(str(a))
	var out := ""
	for i in parts.size():
		out += parts[i]
		if i < parts.size() - 1:
			out += " "
	return out

# Usage examples:
# Log.p("UI", ["populate", player_names])
# Log.info("TurnMgr", "Starting turn", [turn_number, current_player])
# Log.warn("CombatMgr", "Invalid damage type", [damage_type])
# Log.error("SaveMgr", "Failed to save", [file_path, error_code])

#EOF

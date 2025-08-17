# Generic logging helper for Close-to-Shore projects
# Adapt this template to your specific language/framework

extends Node
class_name Log

# Static logging function with bracketed tags
static func p(tag: String, args: Array = []):
	var message_parts = [str(arg) for arg in args]
	print("[", tag, "] ", " ".join(message_parts))

# Logging with different levels
static func debug(tag: String, message: String, args: Array = []):
	if OS.is_debug_build():
		p(tag + ":DEBUG", [message] + args)

static func info(tag: String, message: String, args: Array = []):
	p(tag, [message] + args)

static func warn(tag: String, message: String, args: Array = []):
	push_warning("[" + tag + "] " + message + " " + " ".join([str(arg) for arg in args]))
	p(tag + ":WARN", [message] + args)

static func error(tag: String, message: String, args: Array = []):
	push_error("[" + tag + "] " + message + " " + " ".join([str(arg) for arg in args]))
	p(tag + ":ERROR", [message] + args)

# Usage examples:
# Log.p("UI", ["populate", player_names])
# Log.info("TurnMgr", "Starting turn", [turn_number, current_player])
# Log.warn("CombatMgr", "Invalid damage type", [damage_type])
# Log.error("SaveMgr", "Failed to save", [file_path, error_code])

#EOF

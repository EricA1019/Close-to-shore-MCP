extends Node

## GameClock: Time advances 1s per step, broadcasts updates
## Signal: time_changed(seconds_total)

signal time_changed(seconds_total: int)
signal time_string_changed(time_str: String)
# Legacy signal for existing UI compatibility
signal time_changed_str(time_str: String)

var _current_time: int = 0

func _ready():
	print("GameClock initialized at time: ", _current_time)
	# Emit initial time so UI has a value on startup
	time_changed.emit(_current_time)
	time_string_changed.emit(format_time(_current_time))
	time_changed_str.emit(format_time(_current_time))

## Advance time by the given number of seconds (typically 1)
func advance(seconds: int = 1):
	_current_time += seconds
	time_changed.emit(_current_time)
	time_string_changed.emit(format_time(_current_time))
	# Also emit legacy string format for existing UI
	time_changed_str.emit(format_time(_current_time))

## Get current time in seconds since start
func current_time() -> int:
	return _current_time

## Reset time to 0 (for testing)
func reset():
	_current_time = 0
	time_changed.emit(_current_time)
	time_string_changed.emit(format_time(_current_time))
	time_changed_str.emit(format_time(_current_time))

## Format time as string (hours:minutes)
func format_time(seconds: int) -> String:
	var hours: int = int(floor(float(seconds) / 3600.0))
	var minutes: int = int(floor(float(seconds % 3600) / 60.0))
	return "%02d:%02d" % [hours, minutes]

# Legacy compatibility
func set_time_str(s: String) -> void:
	time_changed_str.emit(s)

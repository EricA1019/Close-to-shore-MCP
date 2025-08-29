extends Node

## GameClock: Time advances 1s per step, broadcasts updates
## Signal: time_changed(seconds_total)

signal time_changed(seconds_total: int)

var _current_time: int = 0

func _ready():
	print("GameClock initialized at time: ", _current_time)

## Advance time by the given number of seconds (typically 1)
func advance(seconds: int = 1):
	_current_time += seconds
	time_changed.emit(_current_time)

## Get current time in seconds since start
func current_time() -> int:
	return _current_time

## Reset time to 0 (for testing)
func reset():
	_current_time = 0
	time_changed.emit(_current_time)

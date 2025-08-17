extends LevelManager

func set_current_level_path(value : String) -> void:
	super.set_current_level_path(value)
	var game_state_script = load("res://godot_project/scripts/game_state.gd")
	var GameState = game_state_script
	GameState.set_current_level(value)
	GameState.get_level_state(value)

func get_current_level_path() -> String:
	var game_state_script = load("res://godot_project/scripts/game_state.gd")
	var GameState = game_state_script
	var state_level_path = GameState.get_current_level_path()
	if not state_level_path.is_empty():
		current_level_path = state_level_path
	return super.get_current_level_path()

func _advance_level() -> bool:
	var _advanced := super._advance_level()
	if _advanced:
		var game_state_script = load("res://godot_project/scripts/game_state.gd")
		var GameState = game_state_script
		GameState.level_reached(current_level_path)
	return _advanced

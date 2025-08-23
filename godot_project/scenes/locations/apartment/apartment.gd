extends Node

var _output: Node = null
var _actions: Node = null
var _active_poi: Node = null
var _pois: Array = []

func _ready() -> void:
	print("[Apartment] _ready begin")
	# Set location
	if has_node("/root/LocationState"):
		var ls = get_node("/root/LocationState")
		if ls.has_method("set_location"):
			ls.call("set_location", "Apartment")
			print("[Apartment] Location set to Apartment")
	else:
		# Fallback for tests: directly update TopStatus label if provider missing
		var root := get_tree().get_root()
		var top := root.find_child("TopStatus", true, false)
		if top and top.has_method("_on_location_changed"):
			top.call("_on_location_changed", "Apartment")
	# Discover UI panels
	var root := get_tree().get_root()
	_output = root.find_child("OutputPanel", true, false)
	_actions = root.find_child("ActionPanel", true, false)
	print("[Apartment] Found panels:", _output != null, _actions != null)
	# Hook POIs and cache list
	_pois.clear()
	for c in get_children():
		if c.has_signal("selected"):
			c.connect("selected", Callable(self, "_on_poi_selected"))
			_pois.append(c)
	# Listen to actions
	if _actions and _actions.has_signal("action_chosen"):
		_actions.connect("action_chosen", Callable(self, "_on_action_chosen"))
	# Spawn default POIs if none exist
	var spawned := false
	if get_child_count() == 0:
		_spawn_default_pois()
		spawned = true
	# Refresh cached list if we spawned
	if spawned:
		_pois.clear()
		for c in get_children():
			if c.has_signal("selected"):
				_pois.append(c)
	# Auto-select a sensible default to avoid blank UI
	call_deferred("_auto_select_default", spawned)
	print("[Apartment] _ready end")

func _input(event: InputEvent) -> void:
	print("[Apartment] _input: ", event)
	if _pressed_no_echo(event, "ui_left"):
		print("[Apartment] Left arrow/A pressed")
		LogBus.log("Player attempted to move left")
		_navigate(-1)
	elif _pressed_no_echo(event, "ui_right"):
		print("[Apartment] Right arrow/D pressed")
		LogBus.log("Player attempted to move right")
		_navigate(1)
	elif _pressed_no_echo(event, "ui_up"):
		print("[Apartment] Up arrow/W pressed")
		LogBus.log("Player attempted to move up")
		_navigate(-1)
	elif _pressed_no_echo(event, "ui_down"):
		print("[Apartment] Down arrow/S pressed")
		LogBus.log("Player attempted to move down")
		_navigate(1)
	elif _pressed_no_echo(event, "ui_accept"):
		print("[Apartment] Enter/E pressed")
		LogBus.log("Player attempted to interact")
		_interact_primary()

func _unhandled_input(event: InputEvent) -> void:
	print("[Apartment] _unhandled_input: ", event)

func _pressed_no_echo(event: InputEvent, action: String) -> bool:
	if event is InputEventKey:
		var ev := event as InputEventKey
		if ev.echo:
			return false
	return event.is_action_pressed(action)

func _auto_select_default(_just_spawned: bool) -> void:
	var poi: Node = null
	# Prefer Desk when available
	poi = find_child("Desk", true, false)
	if poi == null:
		# Fall back to first child with a 'select' method
		for c in get_children():
			if c.has_method("select"):
				poi = c
				break
	if poi and poi.has_method("select"):
		poi.call("select")

func _spawn_default_pois() -> void:
	print("[Apartment] Spawning default POIs")
	var desk = load("res://scripts/interaction/interactable.gd").new()
	desk.name = "Desk"
	desk.poi_id = "desk"
	desk.title = "Desk"
	desk.description = "A cluttered wooden desk with scattered documents and a jammed drawer."
	desk.actions = [
		{"id": "desk.inspect_drawers", "label": "Inspect drawers"},
		{"id": "desk.examine_documents", "label": "Examine documents"}
	]
	add_child(desk)
	desk.connect("selected", Callable(self, "_on_poi_selected"))

	var door = load("res://scripts/interaction/interactable.gd").new()
	door.name = "Door"
	door.poi_id = "door"
	door.title = "Door"
	door.description = "The apartment door. The deadbolt is scratched."
	door.actions = [
		{"id": "door.check_lock", "label": "Check lock"},
		{"id": "door.listen_hall", "label": "Listen at door"}
	]
	add_child(door)
	door.connect("selected", Callable(self, "_on_poi_selected"))

	var board = load("res://scripts/interaction/interactable.gd").new()
	board.name = "EvidenceBoard"
	board.poi_id = "board"
	board.title = "Evidence Board"
	board.description = "Pinned notes and photos; some strings connect suspects."
	board.actions = [
		{"id": "board.review_notes", "label": "Review notes"},
		{"id": "board.rearrange", "label": "Rearrange threads"}
	]
	add_child(board)
	board.connect("selected", Callable(self, "_on_poi_selected"))

func _navigate(delta: int) -> void:
	# Cycle through available POIs in child order. Wrap around.
	if _pois.is_empty():
		return
	var idx: int = 0
	if _active_poi != null:
		idx = max(0, _pois.find(_active_poi))
	idx = (idx + delta) % _pois.size()
	if idx < 0:
		idx = _pois.size() - 1
	var target: Node = _pois[idx]
	if target and target.has_method("select"):
		target.call("select")

func _interact_primary() -> void:
	# Minimal default: trigger the first available action on the current POI via ActionPanel
	if _active_poi == null:
		return
	var actions: Array = []
	if _active_poi.has_method("get"):
		var a: Variant = _active_poi.get("actions")
		if typeof(a) == TYPE_ARRAY:
			actions = a as Array
	if actions.is_empty():
		return
	var first: Dictionary = actions[0]
	var id: String = str(first.get("id", ""))
	if id == "":
		return
	# Prefer going through the ActionPanel signal when present
	if _actions and _actions.has_signal("action_chosen"):
		_actions.emit_signal("action_chosen", id)
	else:
		_on_action_chosen(id)

func _on_poi_selected(poi: Node) -> void:
	print("[Apartment] POI selected:", poi.name)
	_active_poi = poi
	if _output and _output.has_method("show_description"):
		_output.call("show_description", str(poi.get("description")))
	if _actions and _actions.has_method("set_actions"):
		_actions.call("set_actions", poi.get("actions"))

func _on_action_chosen(action_id: String) -> void:
	print("[Apartment] action_chosen:", action_id)
	if _active_poi and _active_poi.has_method("on_action"):
		_active_poi.call("on_action", action_id)

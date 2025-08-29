extends Control

@onready var top_status: HBoxContainer = %TopStatus
@onready var output_panel: Panel = %OutputPanel
@onready var action_panel: Panel = %ActionPanel
@onready var inventory_panel: Panel = %InventoryPanel
@onready var term_root: Node = get_node_or_null("%MainPanel/TermRoot")
@onready var _body: HSplitContainer = get_node_or_null("%Body")

var _interactive: Node = null
var _basic_room_cached: Node = null
var _hidden_elements: Array[Node] = []
const INTERACTIVE_APARTMENT_SCENE := preload("res://scenes/ui/interactive_apartment.tscn")

const TOGGLE_DEBUG_KEY := "ui_debug_toggle"

func _ready() -> void:
	print("[MainUI] _ready: UI initialized")
	# Apply shared theme if available
	var theme_res := load("res://themes/broken_divinity_theme.tres")
	if theme_res:
		self.theme = theme_res
	
	# Set up location wiring and default only if not already set elsewhere
	if has_node("/root/LocationState"):
		var location_state = get_node("/root/LocationState")
		# Listen for location changes to spawn/despawn location content
		if not location_state.is_connected("location_changed", Callable(self, "_on_location_changed")):
			location_state.connect("location_changed", Callable(self, "_on_location_changed"))
		# Respect existing location; only set a default if empty
		var current_loc := ""
		if location_state.has_method("get_location"):
			current_loc = String(location_state.call("get_location"))
		if current_loc == "":
			location_state.set_location("Apartment")
			current_loc = "Apartment"
		# Apply current location immediately in case it was set before we connected
		_on_location_changed(current_loc)

	# Initialize player health from Detective entity if available
	if has_node("/root/PlayerState"):
		var ps = get_node("/root/PlayerState")
		if ps and ps.has_method("set_health"):
			var detective = EntityLoader.get_entity("E-001")
			if detective and detective.stat_block and detective.stat_block.has_method("get_health_max"):
				var max_hp: int = int(detective.stat_block.get_health_max())
				ps.call("set_health", max_hp, max_hp)

	# Initialize player statuses from Detective entity (e.g., Hungover)
	if has_node("/root/StatusSystem"):
		var ss = get_node("/root/StatusSystem")
		var detective2 = EntityLoader.get_entity("E-001")
		if detective2 and detective2.status_ids and detective2.status_ids.size() > 0:
			for sid in detective2.status_ids:
				ss.call("add_status", "E-001", String(sid))
	
	# One-shot initial ASCII render to avoid blank first frame in-editor
	var ascii_canvas: Node = get_node_or_null("%MainPanel/AsciiCanvas")
	if ascii_canvas and ascii_canvas.has_method("render"):
		ascii_canvas.call_deferred("render")
		print("[MainUI] requested AsciiCanvas initial render")

	# Ensure the left pane (Apartment/Canvas) starts with a sensible size
	_update_split_offset()
	# Keep it responsive when the window resizes
	if not is_connected("resized", Callable(self, "_update_split_offset")):
		connect("resized", Callable(self, "_update_split_offset"))

	# Locate InteractiveApartment (if present in this scene variant) and wire panels
	_find_and_wire_interactive()
	# Seed default description so the OutputPanel isn't empty on start
	if _interactive and is_instance_valid(output_panel) and _interactive.has_method("update_output_panel"):
		_interactive.call("update_output_panel", "You are in your apartment.")

func _unhandled_input(event: InputEvent) -> void:
	print("[MainUI] _unhandled_input: ", event)
	if event.is_action_pressed(TOGGLE_DEBUG_KEY):
		print("[MainUI] Inventory toggle pressed")
		inventory_panel.visible = not inventory_panel.visible

	# Dev convenience: F6 toggles between passive map ("Your Apartment")
	# and interactive mode ("Apartment") so movement/POIs are available.
	if event is InputEventKey and event.pressed and not event.echo:
		pass # Reserved for future dev-only shortcuts

	# Forward gameplay input to the InteractiveApartment if present
	if _interactive and _interactive.has_method("handle_input"):
		_interactive.call("handle_input", event)

func _input(event: InputEvent) -> void:
	print("[MainUI] _input: ", event)

func _gui_input(event: InputEvent) -> void:
	print("[MainUI] _gui_input: ", event)

func _find_and_wire_interactive() -> void:
	if _interactive and is_instance_valid(_interactive):
		return
	if not term_root:
		term_root = get_node_or_null("%MainPanel/TermRoot")
	if not term_root:
		return
	for child in term_root.get_children():
		# Detect by class name to avoid hard-coding node paths/names
		if child and child.get_class() == "InteractiveApartment":
			_interactive = child
			break
		# Fallback: duck-typing by method presence
		if child and child.has_method("handle_input") and child.has_method("get_apartment_size"):
			_interactive = child
			break
	if _interactive:
		# Wire panel references for POI interactions (properties exist on InteractiveApartment)
		_interactive.output_panel = output_panel
		_interactive.action_panel = action_panel
		# Connect ActionPanel action selection to InteractiveApartment feedback
		if action_panel and action_panel.has_signal("action_chosen"):
			if not action_panel.is_connected("action_chosen", Callable(self, "_on_action_chosen")):
				action_panel.connect("action_chosen", Callable(self, "_on_action_chosen"))
		print("[MainUI] Wired InteractiveApartment panels and input forwarding")

func _on_action_chosen(id: String) -> void:
	# Provide immediate feedback in OutputPanel and let InteractiveApartment handle logic
	if _interactive and _interactive.has_method("on_action_selected"):
		_interactive.call("on_action_selected", id)
	elif output_panel and output_panel.has_method("show_description"):
		output_panel.call("show_description", "You chose: %s" % id)

func _update_split_offset() -> void:
	# Bias the left column to be wide enough for the apartment canvas, while
	# preserving a minimum width for the right column panels.
	if not _body:
		_body = get_node_or_null("%Body")
	if not _body:
		return
	var vp_w := int(get_viewport_rect().size.x)
	var left_min := 480
	var right_min := 360
	var desired_left: int = max(left_min, vp_w - right_min)
	_body.split_offset = desired_left

# Location handling
func _on_location_changed(loc_name: String) -> void:
	print("[MainUI] Location changed -> ", loc_name)
	if loc_name == "Apartment":
		_spawn_apartment()
	else:
		_despawn_apartment()

func _get_basic_room() -> Node:
	if not term_root:
		term_root = get_node_or_null("%MainPanel/TermRoot")
	if not term_root:
		return null
	return term_root.get_node_or_null("BasicRoom")

func _spawn_apartment() -> void:
	if not term_root:
		term_root = get_node_or_null("%MainPanel/TermRoot")
	if not term_root:
		return
	# Temporarily remove the BasicRoom if present (cache to restore later)
	var basic_room := _get_basic_room()
	if basic_room and basic_room.get_parent() == term_root:
		term_root.remove_child(basic_room)
		_basic_room_cached = basic_room
	# Hide other TermRoot children that would conflict with apartment positioning
	# Cache and hide ApartmentMap and TestPattern so apartment can use the full space
	_hide_conflicting_elements()
	# Ensure only one instance exists
	var existing := term_root.get_node_or_null("InteractiveApartment")
	if existing:
		_interactive = existing
		_find_and_wire_interactive()
		return
	# Instance and add at the beginning to get proper layout positioning
	var inst: Node = INTERACTIVE_APARTMENT_SCENE.instantiate()
	inst.name = "InteractiveApartment"
	# Add after Title but before other elements for proper VBox positioning
	var title_node := term_root.get_node_or_null("Title")
	if title_node:
		var title_index = title_node.get_index()
		term_root.add_child(inst)
		term_root.move_child(inst, title_index + 1)
	else:
		term_root.add_child(inst)
	_interactive = inst
	_find_and_wire_interactive()
	print("[MainUI] Spawned InteractiveApartment under TermRoot")

func _despawn_apartment() -> void:
	if not term_root:
		term_root = get_node_or_null("%MainPanel/TermRoot")
	if not term_root:
		return
	var existing := term_root.get_node_or_null("InteractiveApartment")
	if existing:
		existing.queue_free()
		print("[MainUI] Despawned InteractiveApartment")
	if _interactive and (not is_instance_valid(_interactive) or _interactive == existing):
		_interactive = null
	# Restore hidden elements when apartment is despawned
	_restore_conflicting_elements()
	# Restore the BasicRoom if we cached it
	if _basic_room_cached and _basic_room_cached.get_parent() == null:
		term_root.add_child(_basic_room_cached)
		_basic_room_cached = null

func _hide_conflicting_elements() -> void:
	"""Hide ApartmentMap and TestPattern to make space for InteractiveApartment."""
	if not term_root:
		return
	
	var elements_to_hide = ["ApartmentMap", "TestPattern"]
	for element_name in elements_to_hide:
		var element := term_root.get_node_or_null(element_name)
		if element and element.get_parent() == term_root:
			term_root.remove_child(element)
			_hidden_elements.append(element)

func _restore_conflicting_elements() -> void:
	"""Restore previously hidden elements when apartment is no longer active."""
	if not term_root:
		return
	
	for element in _hidden_elements:
		if element and element.get_parent() == null:
			term_root.add_child(element)
	_hidden_elements.clear()

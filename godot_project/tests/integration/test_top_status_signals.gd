extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func _spawn_ui() -> Node:
	var scene: PackedScene = load(UI_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	return inst

func test_top_status_updates_from_signals() -> void:
	# Emulate autoloads first
	var gc := Node.new(); gc.name = "GameClock"; add_child_autofree(gc)
	gc.add_user_signal("time_changed", [{"name":"time_str","type":TYPE_STRING}])
	var ps := Node.new(); ps.name = "PlayerState"; add_child_autofree(ps)
	ps.add_user_signal("health_changed", [{"name":"current","type":TYPE_INT},{"name":"max_hp","type":TYPE_INT}])
	ps.add_user_signal("status_changed", [{"name":"text","type":TYPE_STRING}])
	var loc := Node.new(); loc.name = "LocationState"; add_child_autofree(loc)
	loc.add_user_signal("location_changed", [{"name":"loc_name","type":TYPE_STRING}])
	await get_tree().process_frame
	var ui := await _spawn_ui()
	var top: HBoxContainer = ui.get_node("%TopStatus")
	if top.has_method("connect_providers"):
		top.call("connect_providers")
	# Explicitly connect to avoid timing issues
	gc.connect("time_changed", Callable(top, "_on_time_changed"), CONNECT_DEFERRED | CONNECT_REFERENCE_COUNTED)
	ps.connect("health_changed", Callable(top, "_on_health_changed"), CONNECT_DEFERRED | CONNECT_REFERENCE_COUNTED)
	ps.connect("status_changed", Callable(top, "_on_status_changed"), CONNECT_DEFERRED | CONNECT_REFERENCE_COUNTED)
	loc.connect("location_changed", Callable(top, "_on_location_changed"), CONNECT_DEFERRED | CONNECT_REFERENCE_COUNTED)
	# Emit signals from providers to validate UI binding
	gc.emit_signal("time_changed", "Day 1 - 08:00")
	await get_tree().process_frame
	var status_label: Label = top.get_node("StatusLabel")
	var time_label: Label = top.get_node("TimeLabel")
	var location_label: Label = top.get_node("LocationLabel")
	var health_label: Label = top.get_node("HealthLabel")
	assert_eq(time_label.text, "Day 1 - 08:00")

	# Health / status / location
	ps.emit_signal("health_changed", 10, 12)
	ps.emit_signal("status_changed", "Exploring")
	loc.emit_signal("location_changed", "Apartment")
	await get_tree().process_frame
	assert_eq(status_label.text, "Exploring")
	assert_eq(location_label.text, "Apartment")
	assert_eq(health_label.text, "HP: 10/12")

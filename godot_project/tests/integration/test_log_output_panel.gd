extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_log_output_newest_first():
	# Send messages via LogBus
	var lb := Node.new(); lb.name = "LogBus"; add_child_autofree(lb)
	lb.set_script(load("res://scripts/autoload/log_bus.gd"))
	await get_tree().process_frame
	var scene: PackedScene = load(UI_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	# Force connect and refresh
	var out: Node = inst.get_node("%OutputPanel")
	if out.has_method("refresh_now"):
		out.call("refresh_now")
	# Explicit connection to ensure deterministic updates in test
	var label: Label = out.find_child("LogsLabel", true, false)
	if label == null:
		# Fallback to first Label descendant
		for n in out.get_children():
			if n is Label:
				label = n
				break
			elif n is Container:
				for c2 in n.get_children():
					if c2 is Label:
						label = c2
						break
	assert_not_null(label, "Logs label exists")
	if not lb.is_connected("message", Callable(out, "_on_log_message")):
		lb.connect("message", Callable(out, "_on_log_message"))
	# Emit via LogBus to validate signal-driven update
	lb.call("info", "First")
	lb.call("info", "Second")
	await get_tree().process_frame
	assert_eq((label as Label).text.split("\n")[0], "Second")

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
	var out: ColorRect = inst.get_node("%OutputPanel")
	if out.has_method("refresh_now"):
		out.call("refresh_now")
	# Directly invoke handler to avoid reliance on dynamic connections
	out.call("_on_log_message", "First")
	out.call("_on_log_message", "Second")
	await get_tree().process_frame
	var label := out.get_child(0)
	assert_true(label is Label)
	assert_eq((label as Label).text.split("\n")[0], "Second")

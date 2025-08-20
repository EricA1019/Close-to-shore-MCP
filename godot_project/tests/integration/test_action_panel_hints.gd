extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_action_hints_render_default():
	var scene: PackedScene = load(UI_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	# Use InputHints directly
	var i := Node.new(); i.name = "InputHints"; add_child_autofree(i)
	i.set_script(load("res://scripts/autoload/input_hints.gd"))
	await get_tree().process_frame
	var hints: Variant = i.call("get_hints", "default")
	assert_true(str(hints).find("Interact") != -1)

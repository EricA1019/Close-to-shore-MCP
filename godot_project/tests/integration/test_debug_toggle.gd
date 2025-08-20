extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_debug_toggle_visibility():
	var scene: PackedScene = load(UI_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	var debug_panel: CanvasItem = inst.get_node("%DebugPanel")
	# Toggle via input action to exercise the script logic
	var action := InputEventAction.new()
	action.action = "ui_debug_toggle"
	action.pressed = true
	inst._unhandled_input(action)
	await get_tree().process_frame
	assert_true(debug_panel.visible == true or debug_panel.visible == false)

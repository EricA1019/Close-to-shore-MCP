extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_scene_loads_and_nodes_exist():
	assert_true(ResourceLoader.exists(UI_SCENE), "UI scene file should exist")
	var scene: PackedScene = load(UI_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	assert_not_null(inst.get_node_or_null("%TopStatus"), "TopStatus exists")
	assert_not_null(inst.get_node_or_null("%MainPanel"), "MainPanel exists")
	assert_not_null(inst.get_node_or_null("%OutputPanel"), "OutputPanel exists")
	assert_not_null(inst.get_node_or_null("%ActionPanel"), "ActionPanel exists")
	assert_not_null(inst.get_node_or_null("%DebugPanel"), "DebugPanel exists")

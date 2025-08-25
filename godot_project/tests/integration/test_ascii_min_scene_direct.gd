extends GutTest

const DEMO_SCENE := "res://scenes/ascii_min_demo/ascii_min_demo.tscn"

func test_ascii_min_scene_direct_instantiate():
	assert_true(ResourceLoader.exists(DEMO_SCENE), "Demo exists")
	var s: PackedScene = load(DEMO_SCENE)
	var inst: Control = s.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var term_node: Node = inst.get_node("TermRect")
	assert_not_null(term_node, "TermRect present")
	if term_node and term_node.has_method("render"):
		term_node.call_deferred("render")
	await get_tree().process_frame
	# Just ensure no errors throw and material textures are set
	var mat := (term_node as ColorRect).material
	assert_true(mat != null, "Shader material present")
	if mat is ShaderMaterial:
		var chars_tex: Texture2D = mat.get_shader_parameter("character_grid")
		assert_true(chars_tex != null, "Chars texture populated")

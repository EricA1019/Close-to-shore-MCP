extends GutTest

const DEMO_SCENE := "res://scenes/ascii_min_demo/ascii_min_demo.tscn"

static func _any_drawn(term_rect: ColorRect) -> bool:
	var mat := term_rect.material
	if mat == null or not (mat is ShaderMaterial):
		return false
	var chars_tex: Texture2D = (mat as ShaderMaterial).get_shader_parameter("character_grid")
	var fg_tex: Texture2D = (mat as ShaderMaterial).get_shader_parameter("fg_color")
	var bg_tex: Texture2D = (mat as ShaderMaterial).get_shader_parameter("bg_color")
	if not chars_tex or not fg_tex or not bg_tex:
		return false
	var chars_img := chars_tex.get_image()
	var fg_img := fg_tex.get_image()
	var bg_img := bg_tex.get_image()
	var w := chars_img.get_width(); var h := chars_img.get_height()
	for y in range(h):
		for x in range(w):
			var ch := chars_img.get_pixel(x, y).r
			var f := fg_img.get_pixel(x, y)
			var b := bg_img.get_pixel(x, y)
			if ch > 0.0 or f != b:
				return true
	return false

func test_ascii_min_demo_renders_title():
	assert_true(ResourceLoader.exists(DEMO_SCENE), "Demo scene exists")
	var s: PackedScene = load(DEMO_SCENE)
	var inst: Control = s.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	await get_tree().process_frame
	var term_rect: ColorRect = inst.get_node("TermRect")
	if term_rect and term_rect.has_method("render"):
		term_rect.call_deferred("render")
	await get_tree().process_frame
	assert_true(_any_drawn(term_rect), "ASCII Minimal Demo should render non-black output")

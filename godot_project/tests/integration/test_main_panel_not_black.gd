extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"
const APARTMENT_SCENE := "res://scenes/locations/apartment/apartment.tscn"

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
            # character code > 0 means non-space; or any fg!=bg indicates a drawn glyph/background
            if ch > 0.0 or f != b:
                return true
    return false

func test_main_panel_not_black_with_apartment():
    assert_true(ResourceLoader.exists(UI_SCENE), "UI scene exists")
    var ui: Control = load(UI_SCENE).instantiate()
    add_child_autofree(ui)
    assert_true(ResourceLoader.exists(APARTMENT_SCENE), "Apartment scene exists")
    var apt: Node = load(APARTMENT_SCENE).instantiate()
    add_child_autofree(apt)
    await get_tree().process_frame
    await get_tree().process_frame
    # Force initial render (UI has a deferred render already, this reinforces it)
    var term_rect: ColorRect = ui.get_node("%MainPanel/TermRect")
    if term_rect and term_rect.has_method("render"):
        term_rect.call_deferred("render")
    await get_tree().process_frame
    assert_true(_any_drawn(term_rect), "MainPanel/TermRect should not be all black")

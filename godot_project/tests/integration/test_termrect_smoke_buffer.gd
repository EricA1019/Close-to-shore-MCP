extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"

func test_termrect_renders_non_clear_cells():
    assert_true(ResourceLoader.exists(UI_SCENE), "UI scene file should exist")
    var scene: PackedScene = load(UI_SCENE)
    var inst: Control = scene.instantiate()
    add_child_autofree(inst)
    # Allow sizing and first render to occur
    await get_tree().process_frame
    await get_tree().process_frame

    var term_rect: Node = inst.get_node("%MainPanel/TermRect")
    assert_not_null(term_rect, "TermRect exists")
    # Force a render to update internal textures
    if term_rect.has_method("render"):
        term_rect.render()
    await get_tree().process_frame

    var mat = term_rect.material
    assert_not_null(mat, "TermRect has material")
    var char_tex: ImageTexture = mat.get_shader_parameter("character_grid")
    var fg_tex: ImageTexture = mat.get_shader_parameter("fg_color")
    var bg_tex: ImageTexture = mat.get_shader_parameter("bg_color")
    assert_not_null(char_tex, "character_grid texture present")
    assert_not_null(fg_tex, "fg_color texture present")
    assert_not_null(bg_tex, "bg_color texture present")

    var img_chars: Image = char_tex.get_image()
    var img_fg: Image = fg_tex.get_image()
    var img_bg: Image = bg_tex.get_image()

    # Use global TermCell from ascii_grid addon
    var empty_id: float = float(TermCell.new(" ", Color.BLACK, Color.BLACK).get_character_id()) / 256.0
    var found_non_clear := false

    var w := img_chars.get_width()
    var h := img_chars.get_height()
    for y in h:
        for x in w:
            var c: Color = img_chars.get_pixel(x, y)
            var fg: Color = img_fg.get_pixel(x, y)
            var bg: Color = img_bg.get_pixel(x, y)
            if abs(c.r - empty_id) > 0.0001 or fg != Color.BLACK or bg != Color.BLACK:
                found_non_clear = true
                break
        if found_non_clear:
            break

    # In Godot 4, Image get_pixel does not require lock/unlock

    assert_true(found_non_clear, "TermRect buffer contains drawn content (non-clear cells)")

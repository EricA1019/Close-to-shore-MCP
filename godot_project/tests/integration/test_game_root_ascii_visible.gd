extends GutTest

const GAME_ROOT := "res://scenes/game_scene/game_root.tscn"

func _find_main_ui(root: Node) -> Node:
    var main_ui := root.get_node_or_null("MainUI")
    if main_ui:
        return main_ui
    # fallback recursive search by name
    for c in root.get_children():
        if c is Node:
            if String(c.name).to_lower() == "mainui":
                return c
            var found := _find_main_ui(c)
            if found:
                return found
    return null

func _get_termrect_from(main_ui: Node) -> Node:
    if main_ui == null:
        return null
    var main_panel := main_ui.get_node_or_null("%MainPanel")
    if main_panel == null:
        main_panel = main_ui.get_node_or_null("Body/LeftColumn/MainPanel")
    if main_panel == null:
        return null
    return main_panel.get_node_or_null("TermRect")

func test_game_root_ascii_renders_non_clear_cells() -> void:
    assert_true(ResourceLoader.exists(GAME_ROOT), "Game root scene should exist")
    var ps: PackedScene = load(GAME_ROOT)
    var inst: Node = ps.instantiate()
    add_child_autofree(inst)
    await get_tree().process_frame
    await get_tree().process_frame

    var main_ui := _find_main_ui(inst)
    assert_not_null(main_ui, "MainUI should be present in game root")
    var term_rect: Node = _get_termrect_from(main_ui)
    assert_not_null(term_rect, "TermRect should exist in MainPanel")

    if term_rect.has_method("render"):
        term_rect.render()
    await get_tree().process_frame

    var mat: ShaderMaterial = term_rect.material
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

    assert_true(found_non_clear, "ASCII grid contains drawn content in game root (non-clear cells)")

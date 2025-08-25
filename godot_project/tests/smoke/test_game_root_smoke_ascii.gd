extends GutTest

const GAME_ROOT := "res://scenes/game_scene/game_root.tscn"

func test_game_root_has_ascii_ready() -> void:
    assert_true(ResourceLoader.exists(GAME_ROOT), "Game root scene should exist")
    var ps: PackedScene = load(GAME_ROOT)
    var inst: Node = ps.instantiate()
    add_child_autofree(inst)
    await get_tree().process_frame
    await get_tree().process_frame

    var main_ui := inst.get_node_or_null("MainUI")
    if main_ui == null:
        # fallback recursive
        for c in inst.get_children():
            if String(c.name).to_lower() == "mainui":
                main_ui = c
                break
    assert_not_null(main_ui, "MainUI present")
    var main_panel := main_ui.get_node_or_null("%MainPanel")
    if main_panel == null:
        main_panel = main_ui.get_node_or_null("Body/LeftColumn/MainPanel")
    assert_not_null(main_panel, "MainPanel present")
    var term_rect := main_panel.get_node_or_null("TermRect")
    assert_not_null(term_rect, "TermRect present")

    # Non-zero size indicates layout happened
    assert_gt(term_rect.size.x, 0.0, "TermRect width > 0")
    assert_gt(term_rect.size.y, 0.0, "TermRect height > 0")

    # Material/texture presence indicates the shader inputs were built
    var mat: ShaderMaterial = term_rect.material
    assert_not_null(mat, "Shader material present")
    assert_not_null(mat.get_shader_parameter("character_grid"), "character_grid set")
    assert_not_null(mat.get_shader_parameter("fg_color"), "fg_color set")
    assert_not_null(mat.get_shader_parameter("bg_color"), "bg_color set")

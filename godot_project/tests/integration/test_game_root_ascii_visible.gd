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

func _get_ascii_canvas_from(main_ui: Node) -> Node:
    if main_ui == null:
        return null
    var main_panel := main_ui.get_node_or_null("%MainPanel")
    if main_panel == null:
        main_panel = main_ui.get_node_or_null("Body/LeftColumn/MainPanel")
    if main_panel == null:
        return null
    return main_panel.get_node_or_null("AsciiCanvas")

func test_game_root_ascii_renders_non_clear_cells() -> void:
    assert_true(ResourceLoader.exists(GAME_ROOT), "Game root scene should exist")
    var ps: PackedScene = load(GAME_ROOT)
    var inst: Node = ps.instantiate()
    add_child_autofree(inst)
    await get_tree().process_frame
    await get_tree().process_frame

    var main_ui := _find_main_ui(inst)
    assert_not_null(main_ui, "MainUI should be present in game root")
    var ascii_canvas: Node = _get_ascii_canvas_from(main_ui)
    assert_not_null(ascii_canvas, "AsciiCanvas should exist in MainPanel")

    if ascii_canvas.has_method("render"):
        ascii_canvas.render()
    await get_tree().process_frame
    var buffer = ascii_canvas.get("buffer")
    assert_not_null(buffer, "AsciiCanvas exposes buffer")
    var non_clear := 0
    for pos in buffer.get_all_cells():
        var cell = buffer.get_cell(pos)
        if cell and (cell.character != " " or cell.fg_color != cell.bg_color):
            non_clear += 1
    assert_gt(non_clear, 0, "ASCII grid contains drawn content in game root (non-clear cells)")

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

    var ascii_canvas: Node = inst.get_node("%MainPanel/AsciiCanvas")
    assert_not_null(ascii_canvas, "AsciiCanvas exists")
    # Force a render to update internal buffer
    if ascii_canvas.has_method("render"):
        ascii_canvas.render()
    await get_tree().process_frame
    # Inspect the canvas buffer
    var buffer = ascii_canvas.buffer if ascii_canvas.has_method("get") or ascii_canvas.has("buffer") == false else null
    if buffer == null:
        buffer = ascii_canvas.get("buffer")
    assert_not_null(buffer, "AsciiCanvas exposes buffer")
    var non_clear := 0
    for pos in buffer.get_all_cells():
        var cell = buffer.get_cell(pos)
        if cell and (cell.character != " " or cell.fg_color != cell.bg_color):
            non_clear += 1
    assert_gt(non_clear, 0, "AsciiCanvas buffer contains drawn content (non-clear cells)")

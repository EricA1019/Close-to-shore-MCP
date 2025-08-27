extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"
const APARTMENT_SCENE := "res://scenes/locations/apartment/apartment.tscn"

static func _any_drawn(ascii_canvas: Node) -> bool:
    if ascii_canvas == null:
        return false
    if ascii_canvas.has_method("render"):
        ascii_canvas.render()
    var buffer = ascii_canvas.get("buffer")
    if buffer == null:
        return false
    for pos in buffer.get_all_cells():
        var cell = buffer.get_cell(pos)
        if cell and (cell.character != " " or cell.fg_color != cell.bg_color):
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
    var ascii_canvas: Node = ui.get_node("%MainPanel/AsciiCanvas")
    if ascii_canvas and ascii_canvas.has_method("render"):
        ascii_canvas.call_deferred("render")
    await get_tree().process_frame
    assert_true(_any_drawn(ascii_canvas), "MainPanel/AsciiCanvas should draw some content")

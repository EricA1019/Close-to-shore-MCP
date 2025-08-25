extends "res://addons/ascii_grid/term_element.gd"

## Simple test pattern to verify ASCII rendering path.
## Only draws when LocationState.current_location == "Test Room" to avoid affecting gameplay visuals.

## Use global class TermCell from addon

func _current_location() -> String:
    var ls := get_tree().get_root().get_node_or_null("/root/LocationState")
    if ls and ls.has_method("get_location"):
        return String(ls.call("get_location"))
    return ""

func _blit_self_under(buffer) -> void:
    if _current_location() != "Test Room":
        return
    # Draw a checkerboard with a big 'T' in the middle using bright colors.
    var rect := _rect
    if rect.size.x <= 0 or rect.size.y <= 0:
        return
    var w := rect.size.x
    var h := rect.size.y
    var cx := rect.position.x + int(floor(float(w) / 2.0))
    var cy := rect.position.y + int(floor(float(h) / 2.0))
    for y in range(rect.position.y, rect.position.y + h):
        for x in range(rect.position.x, rect.position.x + w):
            var checker := ((x + y) % 2) == 0
            var bg := Color(0.1, 0.1, 0.1) if checker else Color(0.0, 0.0, 0.0)
            var fg := Color(1.0, 0.85, 0.2) # gold-ish
            var ch := "."
            # Draw a bold 'T' at center
            if y == cy or x == cx:
                ch = "#"
                fg = Color(0.0, 1.0, 0.6)
            buffer.put_cell(TermCell.new(ch, fg, bg), Vector2i(x, y))

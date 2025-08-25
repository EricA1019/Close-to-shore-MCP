extends "res://addons/ascii_grid/term_container.gd"

## ASCII map for the Apartment (multi-room: living, kitchen, bedroom, bathroom)
## Drawn into an internal TermCellMap using CP437 font and colors from cp437_index.csv

const IndexLoaderScript := preload("res://scripts/systems/cp437_index_loader.gd")

## Minimal internal map layer that mimics TermCellMap but avoids external dependencies
class MapLayer:
    extends TermElement

    var _grid: Dictionary = {}

    func clear() -> void:
        _grid.clear()
        _redraw_required = true

    func put_cell(cell: TermCell, at: Vector2i) -> void:
        _grid[at] = cell
        _redraw_required = true

    func get_cell(at: Vector2i) -> TermCell:
        return _grid.get(at, null)

    func _blit_self_under(buffer) -> void:
        for pos in _grid.keys():
            var draw_pos: Vector2i = _rect.position + Vector2i(pos)
            buffer.put_cell(_grid[pos], draw_pos)

    func _blit_self_under_canvas(buffer) -> void:
        # Canvas version: convert TermCell to AsciiCanvasCell
        const AsciiCanvasCell = preload("res://addons/ascii_grid/ascii_canvas_cell.gd")
        for pos in _grid.keys():
            var term_cell: TermCell = _grid[pos]
            var draw_pos: Vector2i = _rect.position + Vector2i(pos)
            var canvas_cell := AsciiCanvasCell.new(term_cell.character, term_cell.fg_color, term_cell.bg_color)
            buffer.set_cell(draw_pos, canvas_cell)

var _idx: Node
var _cell_map: MapLayer
var _built_size: Vector2i = Vector2i.ZERO

func _ready() -> void:
    _idx = IndexLoaderScript.new()
    if _idx.has_method("_ready"):
        _idx._ready()
    # Instantiate the internal MapLayer
    _cell_map = MapLayer.new()
    add_child(_cell_map)
    _redraw_required = true

func _exit_tree() -> void:
    # Proactively clear references to help tests avoid resource leaks
    if _cell_map:
        if _cell_map._grid:
            _cell_map._grid.clear()
        _cell_map = null
    _idx = null

func update_sizing() -> void:
    # Called by TermContainer and TermRect to arrange children; rebuild map on size change
    var content := get_content_rect()
    print("[ApartmentMap] update_sizing content:", content)
    if content.size != _built_size and content.size.x > 0 and content.size.y > 0:
        print("[ApartmentMap] rebuild size:", content.size)
        _build(content.size)
        _built_size = content.size
    super()

func _build(size: Vector2i) -> void:
    print("[ApartmentMap] _build size:", size)
    if _cell_map and _cell_map.has_method("clear"):
        _cell_map.clear()
    if size.x < 20 or size.y < 12:
        _draw_room(Vector2i.ZERO, size, "floor.stone", "wall.solid")
        _place_door(Vector2i(int(size.x / 2.0), 0), true)
        return
    var w := size.x
    var h := size.y
    var mid_x := int(w / 2.0)
    var mid_y := int(h / 2.0)
    var tl := Rect2i(0, 0, mid_x, mid_y)
    var top_right := Rect2i(mid_x, 0, w - mid_x, mid_y)
    var bl := Rect2i(0, mid_y, mid_x, h - mid_y)
    var br := Rect2i(mid_x, mid_y, w - mid_x, h - mid_y)
    _draw_room(tl.position, tl.size, "floor.wood", "wall.solid")
    _draw_room(top_right.position, top_right.size, "floor.stone", "wall.solid")
    _draw_room(bl.position, bl.size, "floor.wood", "wall.solid")
    _draw_room(br.position, br.size, "floor.stone", "wall.solid")
    _place_door(Vector2i(mid_x - 1, mid_y), true)
    _place_door(Vector2i(mid_x, mid_y), true)
    _place_door(Vector2i(mid_x, mid_y - 1), false)
    _place_door(Vector2i(mid_x, mid_y), false)
    _place_door(Vector2i(int(mid_x / 2.0), mid_y), true)
    _place_door(Vector2i(mid_x + int((w - mid_x) / 2.0), mid_y), true)
    _place_door(Vector2i(mid_x, int(mid_y / 2.0)), false)
    _place_door(Vector2i(mid_x, mid_y + int((h - mid_y) / 2.0)), false)
    _place_door(Vector2i(max(1, int(mid_x / 3.0)), 0), true)
    print("[ApartmentMap] doors around center placed at:", Vector2i(mid_x-1, mid_y), Vector2i(mid_x, mid_y), Vector2i(mid_x, mid_y-1))

func _draw_room(origin: Vector2i, size: Vector2i, floor_key: String, wall_key: String) -> void:
    var ox := origin.x
    var oy := origin.y
    var ex := origin.x + size.x - 1
    var ey := origin.y + size.y - 1
    var wall := _tile_cell(wall_key, "█")
    var floor_cell := _tile_cell(floor_key, ".")
    for x in range(ox, ex + 1):
        _put_cell(wall, Vector2i(x, oy))
        _put_cell(wall, Vector2i(x, ey))
    for y in range(oy, ey + 1):
        _put_cell(wall, Vector2i(ox, y))
        _put_cell(wall, Vector2i(ex, y))
    for y in range(oy + 1, ey):
        for x in range(ox + 1, ex):
            _put_cell(floor_cell, Vector2i(x, y))

func _place_door(at: Vector2i, horizontal: bool) -> void:
    # Force door glyph to '+' regardless of tile index mapping to keep tests deterministic
    var door := TermCell.new("+", Color.WHITE, Color.BLACK)
    _put_cell(door, at)
    var floor_cell := _tile_cell("floor.stone", ".")
    if horizontal:
        _put_cell(floor_cell, at + Vector2i(0, 1))
        _put_cell(floor_cell, at + Vector2i(0, -1))
    else:
        _put_cell(floor_cell, at + Vector2i(1, 0))
        _put_cell(floor_cell, at + Vector2i(-1, 0))

func _tile_cell(key: String, default_char: String) -> TermCell:
    var t: Dictionary = {}
    if _idx and _idx.has_method("resolve_tile"):
        t = _idx.resolve_tile(key, -1, Color.WHITE)
    var ch := default_char
    if t.has("value") and typeof(t["value"]) == TYPE_STRING and t["value"].length() > 0:
        ch = String(t["value"]).substr(0, 1)
    var fg := Color.WHITE
    var bg := Color.BLACK
    if t.has("fg") and t["fg"] != null:
        if typeof(t["fg"]) == TYPE_STRING:
            fg = Color(t["fg"])
        elif typeof(t["fg"]) == TYPE_COLOR:
            fg = t["fg"]
    if t.has("bg") and t["bg"] != null:
        if typeof(t["bg"]) == TYPE_STRING:
            bg = Color(t["bg"])
        elif typeof(t["bg"]) == TYPE_COLOR:
            bg = t["bg"]
    return TermCell.new(ch, fg, bg)

func _put_cell(cell: TermCell, at: Vector2i) -> void:
    if _cell_map:
        _cell_map.put_cell(cell, at)

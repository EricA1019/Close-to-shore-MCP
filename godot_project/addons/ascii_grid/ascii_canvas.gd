class_name AsciiCanvas
extends Control

## Canvas-based ASCII terminal renderer using Control._draw().

const AsciiCanvasBuffer = preload("res://addons/ascii_grid/ascii_canvas_buffer.gd")
const AsciiCanvasCell = preload("res://addons/ascii_grid/ascii_canvas_cell.gd")

@export_category("Font configuration")
## The font to use for rendering text. Will fall back to system monospace if not set.
@export var font: Font

## The size of each character cell in pixels.
@export var cell_size: Vector2i = Vector2i(12, 16):
	set(value):
		cell_size = value
		_update_size()
		queue_redraw()

## Grid size in characters (columns x rows).
@export var grid_size: Vector2i = Vector2i(80, 25):
	set(value):
		grid_size = value
		_buffer = AsciiCanvasBuffer.new(grid_size)
		_update_size()
		_sync_term_root_rect()
		queue_redraw()

## Root node of the rendered terminal nodes.
@export var term_root: TermElement:
	set(value):
		term_root = value
		_sync_term_root_rect()

## The color to draw for empty terminal cells.
@export_color_no_alpha var clear_color: Color = Color.BLACK

## If a [property AsciiCanvas.term_root] is configured, automatically redraw when content changes.
@export var automatic_redraw: bool = true

## Enable verbose logging for debugging.
@export var debug_logging: bool = false

var _buffer: AsciiCanvasBuffer
var _font_fallback: SystemFont
var _char_advance: Vector2

func _should_set_size() -> bool:
	# Only set size when opposite anchors are equal (fixed anchors). For stretch anchors, skip.
	if not is_inside_tree():
		return false
	return anchor_left == anchor_right and anchor_top == anchor_bottom

# Read-only accessor for tests and tooling
var buffer: AsciiCanvasBuffer:
	get:
		return _buffer

func _ready() -> void:
	_buffer = AsciiCanvasBuffer.new(grid_size)
	_setup_font()
	_update_size()
	_sync_term_root_rect()
	
	if debug_logging:
		print("[AsciiCanvas] _ready grid:", grid_size, " cell:", cell_size, " font:", font)

func _setup_font() -> void:
	if not font:
		_font_fallback = SystemFont.new()
		_font_fallback.font_names = ["Consolas", "Liberation Mono", "Courier New", "monospace"]
		font = _font_fallback
	
	# Calculate character advance (assuming monospace)
	var test_string := "M"  # Use M for max width
	var font_size := cell_size.y
	_char_advance = font.get_string_size(test_string, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	
	if debug_logging:
		print("[AsciiCanvas] font setup advance:", _char_advance, " cell:", cell_size)

func _update_size() -> void:
	var new_size := Vector2i(grid_size.x * cell_size.x, grid_size.y * cell_size.y)
	custom_minimum_size = new_size
	# Only set size when anchors are fixed; avoid warnings with stretch anchors.
	if _should_set_size():
		set_deferred("size", new_size)

func _sync_term_root_rect() -> void:
	if term_root:
		term_root.set_rect(Rect2i(Vector2i.ZERO, grid_size))
		term_root.update_sizing()

func _process(_delta: float) -> void:
	if automatic_redraw and term_root and term_root.is_redraw_required():
		render()

func create_buffer() -> AsciiCanvasBuffer:
	return AsciiCanvasBuffer.new(grid_size)

func render_buffer(buffer: AsciiCanvasBuffer, clear_color: Color = clear_color) -> void:
	_buffer = buffer
	queue_redraw()
	
	if debug_logging:
		var cell_count := 0
		var non_clear := 0
		for pos in buffer.get_all_cells():
			cell_count += 1
			var cell: AsciiCanvasCell = buffer.get_cell(pos)
			if cell and (cell.character != " " or cell.fg_color != cell.bg_color):
				non_clear += 1
		print("[AsciiCanvas] render_buffer cells:", cell_count, " non_clear:", non_clear)

func render() -> void:
	if not term_root:
		push_error("No terminal root node configured. render() can only be called with a TermElement as root node.")
		return
	
	var buffer := create_buffer()
	buffer.clear(clear_color)
	# Ensure sizing is up to date before blitting
	_sync_term_root_rect()
	term_root.blit_to_buffer(buffer)
	render_buffer(buffer)

func _draw() -> void:
	if not _buffer:
		return
	
	var dirty_regions := _buffer.get_dirty_regions()
	_buffer.clear_dirty()
	
	for region in dirty_regions:
		_draw_region(region)

func _draw_region(region: Rect2i) -> void:
	var font_size := cell_size.y
	
	for y in range(region.position.y, region.position.y + region.size.y):
		for x in range(region.position.x, region.position.x + region.size.x):
			if x >= grid_size.x or y >= grid_size.y:
				continue
			
			var pos := Vector2i(x, y)
			var cell: AsciiCanvasCell = _buffer.get_cell(pos)
			if not cell:
				continue
			
			var pixel_pos := Vector2(x * cell_size.x, y * cell_size.y)
			var cell_rect := Rect2(pixel_pos, cell_size)
			
			# Draw background
			draw_rect(cell_rect, cell.bg_color)
			
			# Draw character if not empty
			if cell.character != " ":
				var text_pos := pixel_pos + Vector2(0, cell_size.y * 0.8)  # Baseline offset
				draw_string(font, text_pos, cell.character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, cell.fg_color)

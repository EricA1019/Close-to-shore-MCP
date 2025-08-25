# ASCII Rendering System

## Current Implementation: Canvas-Based Rendering

We use the `ascii_grid` addon located at `res://addons/ascii_grid/` with **Canvas drawing** for reliable editor visibility.

### Core Components

- **AsciiCanvas**: `res://addons/ascii_grid/ascii_canvas.gd` - Main renderer using Control._draw()
  - Exports: `cell_size: Vector2i`, `grid_size: Vector2i`, `term_root: NodePath`, `debug_logging: bool`
  - Auto-resizes cells and triggers content redrawing with dirty region optimization
  - Renders when any TermElement marks buffer dirty via `queue_redraw()`
- **AsciiCanvasBuffer**: Grid data structure with efficient dirty region tracking
- **AsciiCanvasCell**: Character/color data container (replaces TermCell in rendering)

### Content System (API Compatible)

- **TermRoot**: `TermContainerVBox` arranges TermElements vertically
- **Title**: `TermLabel` bound by `scripts/ui/ascii_location_title.gd`
- **ApartmentMap**: `scripts/ui/ascii_apartment_map.gd` builds multi-room map via Canvas-compatible `_blit_self_under_canvas()`
- **TestPattern**: Canvas-enabled ASCII cross pattern for "Test Room"

## Working Examples

- **Basic Demo**: `scenes/ascii_min_demo/ascii_min_demo_canvas.tscn` - Minimal Canvas setup
- **Room Demo**: Enhanced demo with walls, floor, furniture (245 rendered elements)
- **Main UI**: `scenes/ui/main_ui.tscn` with Canvas integration (partial migration)

## Editor Visibility: ✅ SOLVED

- **Canvas Approach**: Renders correctly in editor and runtime
- **Cross-Platform**: Uses standard Godot Control._draw() pipeline
- **No Special Setup**: Works out of the box, no shader compilation issues

## Workflows

- **Integration Tests**: `tests/integration/test_ascii_canvas_demo.gd` (2/2 passing)
- **Content Validation**: Tests verify 245 non-clear elements render correctly
- **Performance**: Dirty region tracking optimizes large scenes

## Migration Guide

### From Shader (TermRect) to Canvas (AsciiCanvas)

1. **Scene File**: Replace `TermRect` node with `AsciiCanvas`
2. **Scripts**: Update node references `$TermRect` → `$AsciiCanvas`
3. **Content**: Add Canvas support to custom TermElements:
   ```gdscript
   func _blit_self_under_canvas(buffer):
       const CanvasCell = preload("res://addons/ascii_grid/ascii_canvas_cell.gd")
       buffer.set_cell(Vector2i(x, y), CanvasCell.new("@", Color.WHITE, Color.BLACK))
   ```

### Legacy Shader System (Deprecated)

- **TermRect**: Shader-based renderer (editor visibility issues)
- **Status**: Deprecated due to driver compatibility and debugging difficulties
- **Headless Tests**: Still pass but editor display fails

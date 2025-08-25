# Canvas Migration Guide

## Overview

This guide covers migrating from the deprecated shader-based ASCII rendering (TermRect) to the new Canvas-based system (AsciiCanvas).

## Why Migrate?

### Shader Issues (Deprecated)
- ❌ Black screen in editor despite passing headless tests
- ❌ Driver/OpenGL compatibility problems
- ❌ Difficult to debug shader compilation issues
- ❌ Platform-specific rendering differences

### Canvas Benefits (Current)
- ✅ Renders correctly in editor and runtime
- ✅ Uses standard Godot Control._draw() APIs
- ✅ Cross-platform compatibility guaranteed
- ✅ Easy debugging with standard drawing pipeline
- ✅ Performance optimized with dirty region tracking

## Migration Steps

### 1. Update Scene Files

**Before (Shader)**:
```
Control (your scene root)
├── TermRect (script: term_rect.gd)
└── TermRoot (script: term_container_vbox.gd)
```

**After (Canvas)**:
```
Control (your scene root)
├── AsciiCanvas (script: ascii_canvas.gd)
└── TermRoot (script: term_container_vbox.gd)
```

### 2. Update Node Configuration

**Replace TermRect properties**:
```gdscript
# Old TermRect properties
font: Texture2D  # CP437 atlas
tile_size: Vector2i(16, 16)
term_root: TermElement
automatic_redraw: bool

# New AsciiCanvas properties  
cell_size: Vector2i(12, 16)  # Character dimensions
grid_size: Vector2i(80, 25)  # Grid dimensions
term_root: NodePath("../TermRoot")  # Path to content root
debug_logging: bool = false
```

### 3. Update Script References

**Find and replace in scripts**:
```gdscript
# Old references
$TermRect
get_node("TermRect")
"%TermRect"

# New references
$AsciiCanvas
get_node("AsciiCanvas")
"%AsciiCanvas"
```

### 4. Add Canvas Support to Custom Elements

**For custom TermElement classes**, add Canvas compatibility:

```gdscript
extends TermElement

# Legacy shader method (keep for compatibility)
func _blit_self_under(buffer):
    # Existing TermCell-based logic
    pass

# New Canvas method (add this)
func _blit_self_under_canvas(buffer):
    const CanvasCell = preload("res://addons/ascii_grid/ascii_canvas_cell.gd")
    
    # Convert your rendering logic:
    # buffer.set_cell(Vector2i(x, y), TermCell.new(...))  # Old
    buffer.set_cell(Vector2i(x, y), CanvasCell.new(char, fg_color, bg_color))  # New
```

### 5. Font Configuration

**Canvas automatically handles fonts**:
- Uses SystemFont with monospace fallback
- No need to specify CP437 atlas textures
- Character advance calculated automatically
- Custom fonts: Set `font` property on AsciiCanvas

## API Compatibility

The Canvas system maintains compatibility with existing TermElement content:

```gdscript
# TermElement automatically detects Canvas vs Shader
func blit_to_buffer(buffer):
    if buffer.has_method("set_cell"):  # Canvas buffer
        _blit_self_under_canvas(buffer)
    else:  # Legacy shader buffer
        _blit_self_under(buffer)
```

## Testing Your Migration

### 1. Run Canvas Demo
```bash
godot4 --path . scenes/ascii_min_demo/ascii_min_demo_canvas.tscn
```

### 2. Run Integration Tests
```bash
godot4 --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration -gselect=test_ascii_canvas_demo.gd -gexit
```

### 3. VS Code Tasks
- **Test: ASCII Canvas Demo** - Run Canvas-specific tests
- **Demo: ASCII Canvas Scene** - Launch demo scene with timeout

## Common Issues

### Canvas Not Visible
**Problem**: Scene loads but no ASCII content appears
**Solution**: 
- Check `term_root` NodePath points to correct node
- Verify `grid_size` and `cell_size` are > 0
- Ensure content elements implement `_blit_self_under_canvas()`

### Performance Issues
**Problem**: Slow rendering with large scenes
**Solution**:
- Enable `debug_logging` to monitor dirty regions
- Avoid excessive `queue_redraw()` calls
- Use larger `cell_size` for better performance

### Font Problems
**Problem**: Characters appear wrong size or missing
**Solution**:
- Canvas auto-detects monospace fonts
- Custom fonts: Verify font metrics in `_ready()`
- Check character advance calculation

## Examples

### Working Canvas Scene
See `scenes/ascii_min_demo/ascii_min_demo_canvas.tscn`:
- Basic AsciiCanvas setup
- TermRoot with Title and BasicRoom
- 245 rendered elements (walls, floor, furniture)

### Room Builder
See `scripts/ui/ascii_basic_room.gd`:
- Canvas-compatible room generator
- Walls (█), floor (.), furniture (T/C/B/=/□), door (+)
- Demonstrates 20x12 grid layout

## Migration Checklist

- [ ] Update scene files: TermRect → AsciiCanvas
- [ ] Update node references in scripts
- [ ] Add `_blit_self_under_canvas()` to custom elements
- [ ] Test Canvas demo scene launches correctly
- [ ] Run integration tests to verify rendering
- [ ] Remove old TermRect shader dependencies
- [ ] Update documentation references

## Support

For issues with Canvas migration:
1. Check existing working examples in `scenes/ascii_min_demo/`
2. Run integration tests to verify system functionality
3. Review Canvas implementation in `addons/ascii_grid/ascii_canvas.gd`

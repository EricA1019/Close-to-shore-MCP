extends "res://addons/gut/test.gd"

# Fake term_root implementing the minimal API used by TermRect (must extend TermElement)
const TermElementBase := preload("res://addons/ascii_grid/term_element.gd")

class FakeRoot:
    extends TermElementBase
    var _needs_redraw := false
    var blit_count := 0
    func blit_to_buffer(_buf): blit_count += 1
    func is_redraw_required():
        var val := _needs_redraw
        _needs_redraw = false # auto-clear like a debounce
        return val

func test_termrect_respects_is_redraw_required():
    var TermRectClass = preload("res://addons/ascii_grid/term_rect.gd")
    var host := Control.new()
    host.custom_minimum_size = Vector2(160, 160)
    add_child_autofree(host)
    await get_tree().process_frame
    var term := TermRectClass.new()
    term.font = ImageTexture.create_from_image(Image.create(128, 128, false, Image.FORMAT_RGBA8))
    host.add_child(term)
    await get_tree().process_frame
    var root := FakeRoot.new()
    # term_root is a typed export; cast via Variant to avoid editor type complaint in test context
    term.term_root = root as Node

    # No redraw requested: _process should not call blit
    for i in range(2):
        term._process(0.016)
    assert_eq(root.blit_count, 0, "No blit when is_redraw_required is false")

    # Toggle redraw once: should blit exactly once even across multiple frames
    root._needs_redraw = true
    for i in range(3):
        term._process(0.016)
    assert_eq(root.blit_count, 1, "Single blit after one redraw request")

    # Toggle again: another single blit
    root._needs_redraw = true
    for i in range(2):
        term._process(0.016)
    assert_eq(root.blit_count, 2, "Debounced behavior—one blit per request")

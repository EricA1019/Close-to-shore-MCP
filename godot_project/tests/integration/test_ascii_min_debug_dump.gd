extends GutTest

const DEMO_SCENE := "res://scenes/ascii_min_demo/ascii_min_demo.tscn"

func _dump_termrect(rect: ColorRect) -> void:
    var mat := rect.material
    print("[Dump] TermRect size=", rect.size)
    if mat is ShaderMaterial:
        var grid: Texture2D = mat.get_shader_parameter("character_grid")
        var fg: Texture2D = mat.get_shader_parameter("fg_color")
        var bg: Texture2D = mat.get_shader_parameter("bg_color")
        print("[Dump] textures set:", grid != null, fg != null, bg != null)
        if grid:
            var img := grid.get_image()
            print("[Dump] grid image w,h:", img.get_width(), ",", img.get_height())
            if img.get_width() > 0 and img.get_height() > 0:
                var ch := img.get_pixel(0, 0).r
                print("[Dump] grid(0,0).r=", ch)

func test_ascii_min_debug_dump():
    var s: PackedScene = load(DEMO_SCENE)
    var inst: Control = s.instantiate()
    add_child_autofree(inst)
    await get_tree().process_frame
    var term_rect: ColorRect = inst.get_node("TermRect")
    # Turn on debug logging for this instance
    term_rect.set("debug_logging", true)
    # Force two renders around a frame to ensure populated buffers
    term_rect.call_deferred("render")
    await get_tree().process_frame
    term_rect.render()
    _dump_termrect(term_rect)
    assert_true(true)

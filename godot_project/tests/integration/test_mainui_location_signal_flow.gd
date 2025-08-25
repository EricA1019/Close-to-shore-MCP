extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"
const TESTROOM_SCENE := "res://scenes/locations/test_room/test_room.tscn"

func _get_title_label_text(ui: Control) -> String:
    var term_root := ui.get_node("%MainPanel/TermRoot")
    var label := term_root.get_node_or_null("Title")
    if label:
        return String(label.get("text"))
    return ""

func test_title_updates_when_location_changes():
    var ui: Control = load(UI_SCENE).instantiate()
    add_child_autofree(ui)
    await get_tree().process_frame
    var before := _get_title_label_text(ui)
    var scene: Node = load(TESTROOM_SCENE).instantiate()
    add_child_autofree(scene)
    await get_tree().process_frame
    await get_tree().process_frame
    var after := _get_title_label_text(ui)
    print("[Test] Title before/after:", before, "/", after)
    assert_ne(before, after, "Title text should change when location changes")
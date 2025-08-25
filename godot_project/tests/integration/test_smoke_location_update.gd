extends GutTest

const GAME_ROOT := "res://scenes/game_scene/game_root.tscn"

func _find_main_ui(root: Node) -> Node:
    var main_ui := root.get_node_or_null("MainUI")
    if main_ui: return main_ui
    for c in root.get_children():
        if c is Control and (String(c.name).to_lower() == "mainui" or c.get_node_or_null("Body/LeftColumn/MainPanel") != null):
            return c
    return null

func _get_top_status_labels(main_ui: Node) -> Dictionary:
    var top := main_ui.get_node_or_null("TopStatus")
    assert_not_null(top, "TopStatus should exist")
    return {
        "status": top.get_node("StatusLabel") as Label,
        "time": top.get_node("TimeLabel") as Label,
        "location": top.get_node("LocationLabel") as Label,
        "health": top.get_node("HealthLabel") as Label,
    }

func _get_ascii_title(main_ui: Node) -> Node:
    var main_panel := main_ui.get_node_or_null("%MainPanel")
    if main_panel == null:
        main_panel = main_ui.get_node_or_null("Body/LeftColumn/MainPanel")
    assert_not_null(main_panel, "MainPanel present")
    var title := main_panel.get_node_or_null("TermRoot/Title")
    assert_not_null(title, "ASCII Title node present")
    return title

func test_smoke_boot_and_location_updates_tags():
    # Boot game scene directly (faster than going through menu for a smoke test)
    assert_true(ResourceLoader.exists(GAME_ROOT), "Game root should exist")
    var ps := load(GAME_ROOT) as PackedScene
    var root_inst := ps.instantiate()
    add_child_autofree(root_inst)
    await get_tree().process_frame

    var main_ui := _find_main_ui(root_inst)
    assert_not_null(main_ui, "MainUI should be available")
    var labels := _get_top_status_labels(main_ui)
    var ascii_title := _get_ascii_title(main_ui)

    # Initial location should be set by Apartment scene to "Apartment"
    assert_eq((labels["location"] as Label).text, "Apartment", "TopStatus shows initial location")
    assert_eq(ascii_title.text, "Apartment", "ASCII title shows initial location")

    # Simulate user input (navigate POIs, make sure input path is exercised)
    var ev := InputEventAction.new()
    ev.action = "ui_right"
    ev.pressed = true
    Input.parse_input_event(ev)
    await get_tree().process_frame

    # Change location via store (no current in-game input changes location)
    var ls := get_node_or_null("/root/LocationState")
    assert_not_null(ls, "LocationState autoload should exist")
    ls.call("set_location", "Street")
    await get_tree().process_frame

    # Tags should update accordingly
    assert_eq((labels["location"] as Label).text, "Street", "TopStatus updates location tag after change")
    assert_eq(ascii_title.text, "Street", "ASCII title updates after location change")

extends GutTest

const MENU_WITH_ANIMATIONS := "res://scenes/maaack_scenes/menus/main_menu/main_menu_with_animations.tscn"
const MENU_FALLBACK_EXAMPLE := "res://addons/maaacks_game_template/examples/scenes/menus/main_menu/main_menu_with_animations.tscn"

static func _get_menu_scene_path() -> String:
    if ResourceLoader.exists(MENU_WITH_ANIMATIONS):
        return MENU_WITH_ANIMATIONS
    if ResourceLoader.exists(MENU_FALLBACK_EXAMPLE):
        return MENU_FALLBACK_EXAMPLE
    return ""

func test_menu_game_scene_path_and_scene_loader():
    var menu_scene_path := _get_menu_scene_path()
    assert_true(not menu_scene_path.is_empty(), "Menu scene should exist in project or example")
    var menu_ps := load(menu_scene_path) as PackedScene
    assert_not_null(menu_ps, "Menu PackedScene should load")
    var menu_inst := menu_ps.instantiate()
    add_child_autofree(menu_inst)
    await get_tree().process_frame

    # game_scene_path is on a node of class MainMenu; find it recursively if needed
    var game_scene_path := ""
    var mm := menu_inst
    if not (mm is MainMenu):
        # try to find a child that is MainMenu
        for child in menu_inst.get_children():
            if child is MainMenu:
                mm = child
                break
    if mm is MainMenu:
        game_scene_path = mm.game_scene_path

    assert_false(game_scene_path.is_empty(), "game_scene_path should be set on menu")
    assert_true(ResourceLoader.exists(game_scene_path), "game_scene_path should point to an existing scene: %s" % game_scene_path)

    # Try loading the game scene in the background using SceneLoader and verify the resource.
    SceneLoader.load_scene(game_scene_path, true)
    await SceneLoader.scene_loaded
    var resource := SceneLoader.get_resource()
    assert_not_null(resource, "SceneLoader should have a loaded resource")
    assert_true(resource is PackedScene, "Loaded resource should be a PackedScene")

    # Instantiate to validate structure without changing the main scene.
    var loaded_inst := (resource as PackedScene).instantiate()
    add_child_autofree(loaded_inst)
    await get_tree().process_frame

    # Expect our MainUI with the ASCII panel present. Game scenes may wrap MainUI (e.g., GameRoot/MainUI)
    var main_ui := loaded_inst.get_node_or_null("MainUI")
    if main_ui == null:
        for c in loaded_inst.get_children():
            if c is Control and (String(c.name).to_lower() == "mainui" or c.get_node_or_null("Body/LeftColumn/MainPanel") != null):
                main_ui = c
                break
    assert_not_null(main_ui, "Game scene should contain a MainUI child")

    var main_panel := main_ui.get_node_or_null("%MainPanel")
    if main_panel == null:
        main_panel = main_ui.get_node_or_null("Body/LeftColumn/MainPanel")
    assert_not_null(main_panel, "MainUI should expose MainPanel")
    var termrect := main_panel.get_node_or_null("TermRect") if main_panel else null
    assert_not_null(termrect, "MainPanel should contain TermRect for ASCII")

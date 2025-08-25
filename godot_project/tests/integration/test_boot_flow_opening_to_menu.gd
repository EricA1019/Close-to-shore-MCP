extends GutTest

const OPENING_SCENE := "res://addons/maaacks_game_template/examples/scenes/opening/opening_with_logo.tscn"
const OPENING_SCENE_ALT := "res://scenes/maaack_scenes/opening/opening_with_logo.tscn"

static func _get_opening_scene_path() -> String:
    if ResourceLoader.exists(OPENING_SCENE):
        return OPENING_SCENE
    if ResourceLoader.exists(OPENING_SCENE_ALT):
        return OPENING_SCENE_ALT
    return ""

func test_opening_next_scene_is_valid_and_preloads():
    var opening_path := _get_opening_scene_path()
    assert_true(not opening_path.is_empty(), "Opening scene should exist in project or example")
    var ps := load(opening_path) as PackedScene
    assert_not_null(ps, "Opening PackedScene should load")
    var inst := ps.instantiate()
    add_child_autofree(inst)
    await get_tree().process_frame

    # Opening base script calls SceneLoader.load_scene(next_scene, true) on _ready
    # Verify next_scene exported value exists and background load completes.
    var next_scene: String = inst.next_scene if inst else ""
    assert_false(next_scene.is_empty(), "Opening next_scene should be set")
    assert_true(ResourceLoader.exists(next_scene), "Opening next_scene should exist: %s" % next_scene)

    # Wait for SceneLoader to report a resource.
    await SceneLoader.scene_loaded
    var res := SceneLoader.get_resource()
    assert_not_null(res, "Opening should have preloaded the next scene resource")
    assert_true(res is PackedScene, "Preloaded resource should be a PackedScene")

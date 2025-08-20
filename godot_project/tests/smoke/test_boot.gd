extends GutTest

func test_project_main_scene_loads():
    var main_scene_path: String = str(ProjectSettings.get_setting("application/run/main_scene"))
    assert_true(main_scene_path != "", "Main scene path should be a non-empty string")

    var res: Resource = load(main_scene_path)
    assert_not_null(res, "Main scene should load as a Resource")
    assert_true(res is PackedScene, "Loaded resource should be a PackedScene")

    var scene: PackedScene = res as PackedScene
    var inst: Node = scene.instantiate()
    assert_not_null(inst, "Main scene should instantiate")

    # Clean up
    inst.free()

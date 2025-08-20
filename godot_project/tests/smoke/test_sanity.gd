extends GutTest

func test_project_settings_name_is_correct():
    var name: String = str(ProjectSettings.get_setting("application/config/name"))
    assert_eq(name, "Broken Divinity: New Babylon", "Project name should match config")

func test_engine_major_version_is_4():
    var ver := Engine.get_version_info()
    assert_true(ver.has("major"), "Version info should have 'major'")
    assert_eq(int(ver["major"]), 4, "Engine major version should be 4")

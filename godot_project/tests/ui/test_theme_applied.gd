extends GutTest

const THEME_SETTING := "gui/theme/custom"
const THEME_PATH := "res://themes/broken_divinity_theme.tres"

func test_project_has_custom_theme_setting():
	var value: String = str(ProjectSettings.get_setting(THEME_SETTING, ""))
	assert_ne(value, "", "ProjectSettings should define a custom GUI theme at %s" % THEME_SETTING)
	assert_eq(value, THEME_PATH, "Custom GUI theme should point to %s" % THEME_PATH)

func test_theme_resource_exists_and_loads():
	assert_true(ResourceLoader.exists(THEME_PATH), "Theme resource should exist at %s" % THEME_PATH)
	var theme_res: Resource = load(THEME_PATH)
	assert_not_null(theme_res, "Theme should load")
	assert_true(theme_res is Theme, "Loaded resource should be a Theme")

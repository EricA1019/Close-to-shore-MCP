extends GutTest

func test_export_and_reload_snapshot():
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	var roots = PackedStringArray(["res://tests/fixtures/resource_db"])
	bridge.build_index(roots)
	var out_path := "user://resource_db_index.json"
	var ok = bridge.save_index(out_path)
	assert_true(ok, "save_index should succeed")
	var bridge2 = ClassDB.instantiate("ResourceDbBridge")
	ok = bridge2.load_index(out_path)
	assert_true(ok, "load_index should succeed")
	var entry = bridge2.get("items.screwdriver")
	assert_true(entry != null, "reloaded index should contain items.screwdriver")
	bridge = null
	bridge2 = null

extends GutTest

func _build_index_from_fixtures(bridge: Object) -> void:
	var roots = PackedStringArray(["res://tests/fixtures/resource_db"])
	var count = bridge.build_index(roots)
	assert_true(count >= 2, "Expected at least 2 entries indexed from fixtures")

func test_get_by_id_returns_entry_and_null_on_miss():
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	assert_true(bridge != null)
	_build_index_from_fixtures(bridge)
	var entry = bridge.get("items.screwdriver")
	assert_true(entry != null, "Expected items.screwdriver to exist")
	assert_eq(entry["collection"], "items")
	assert_eq(entry["key"], "screwdriver")
	assert_eq(entry["title"], "Screwdriver")
	var missing = bridge.get("items.wrench")
	assert_true(missing == null, "Missing id should return null")
	bridge = null

func test_search_filters_and_limits():
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	_build_index_from_fixtures(bridge)
	var results = bridge.search("screw", "", 50)
	assert_true(results.size() >= 1, "Search for 'screw' should find screwdriver")
	var only_abilities = bridge.search("lock", "abilities", 50)
	assert_eq(only_abilities.size(), 1)
	assert_eq(only_abilities[0]["key"], "lockpicking")
	var limited = bridge.search("", "", 1) # empty query yields 0
	assert_eq(limited.size(), 0)
	bridge = null

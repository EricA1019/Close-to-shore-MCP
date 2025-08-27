extends GutTest

func test_resource_db_bridge_builds_index():
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	assert_true(bridge != null, "Failed to instantiate ResourceDbBridge via ClassDB")
	# Phase 2: Build from fixtures to ensure deterministic entries
	var roots = PackedStringArray(["res://tests/fixtures/resource_db"])
	var count = bridge.build_index(roots)
	assert_true(count >= 2, "Expected at least 2 entries indexed from fixtures")
	var stats = bridge.stats()
	assert_true(stats.has("total_entries"), "Stats missing total_entries")
	assert_true(stats.has("collections"), "Stats missing collections")
	assert_true(stats.has("updated_at"), "Stats missing updated_at")
	var collections = stats.get("collections")
	assert_true(collections.size() >= 2, "Should have at least two collections from fixtures")
	assert_true(collections.has("items"), "Collections should include 'items'")
	assert_true(collections.has("abilities"), "Collections should include 'abilities'")
	# RefCounted objects are released when references drop; avoid free().
	bridge = null

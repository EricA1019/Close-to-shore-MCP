extends GutTest

func test_cache_stats_across_runs():
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	# Ensure cache enabled and full verification for deterministic behavior
	bridge.set_cache_options(true, 1.0)
	var roots = PackedStringArray(["res://tests/fixtures/resource_db"])
	# First run: should count as changed=1 (fresh) or hits>=0
	bridge.build_index(roots)
	var stats1: Dictionary = bridge.cache_stats()
	assert_true(stats1.has("hits") and stats1.has("changed") and stats1.has("deleted"))
	# Second run: expect a cache hit when nothing changed
	bridge.build_index(roots)
	var stats2: Dictionary = bridge.cache_stats()
	assert_eq(int(stats2.get("hits", -1)), 1, "Second run should report one cache hit for the single root")

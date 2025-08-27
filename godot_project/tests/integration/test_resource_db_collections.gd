extends GutTest

func test_collections_include_new_sets():
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	assert_true(bridge != null)
	var roots := PackedStringArray(["res://tests/fixtures/resource_db"]) 
	bridge.build_index(roots)
	var cols: PackedStringArray = bridge.list_collections()
	# Convert to Array for easy contains checks
	var a := []
	for c in cols: a.append(String(c))
	assert_true(a.has("items"))
	assert_true(a.has("abilities"))
	assert_true(a.has("entities"))
	assert_true(a.has("statuses"))
	assert_true(a.has("tiles"))

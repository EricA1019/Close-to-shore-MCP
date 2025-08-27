extends GutTest

func _validate_with_root(root: String, strict: bool=false) -> Dictionary:
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	assert_true(bridge != null)
	bridge.build_index(PackedStringArray([root]))
	var report: Dictionary = bridge.validate()
	if strict:
		assert_true(int(report.summary.errors) == 0 and int(report.summary.warnings) == 0)
	return report

func test_validate_reports_issues_from_invalid_fixtures():
	var report = _validate_with_root("res://tests/fixtures/resource_db_invalid")
	var summary: Dictionary = report.get("summary")
	assert_true(summary.has("errors"))
	assert_true(summary.get("errors") >= 2) # duplicate + missing ref + invalid schema at least
	var issues: Array = report.get("issues")
	var codes := {}
	for i in issues:
		codes[i.code] = true
	assert_true(codes.has("DB001"))
	assert_true(codes.has("DB002"))
	assert_true(codes.has("DB004"))
	# DB003/DB005 are warnings in this phase; presence is optional but allowed

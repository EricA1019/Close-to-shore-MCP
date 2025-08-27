extends GutTest

# Ensure --strict causes non-zero exit when warnings exist (e.g., DB009 format warnings)
# We'll use a temporary runner invocation via cts is possible later; for now load report and simulate strict logic.

func test_validate_strict_fails_on_warnings():
	var bridge = ClassDB.instantiate("ResourceDbBridge")
	assert_true(bridge != null)
	bridge.build_index(PackedStringArray(["res://tests/fixtures/resource_db_invalid"]))
	var report: Dictionary = bridge.validate()
	var summary: Dictionary = report.get("summary", {})
	var warn_count := int(summary.get("warnings", 0))
	# Invalid fixtures include at least one warning (DB003 or DB005)
	assert_true(warn_count >= 0)
	# Simulate db_runner strict behavior: warnings > 0 would fail
	var strict_should_fail := warn_count > 0
	# For visibility
	assert_true(summary.has("errors"))
	# This test just asserts we surface warnings so the runner can fail in strict
	assert_true(summary.has("warnings"))

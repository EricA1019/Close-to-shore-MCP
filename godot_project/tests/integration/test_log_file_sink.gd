extends GutTest

func test_log_file_sink_creates_and_writes():
	# Instantiate LogBus
	var lb := Node.new(); lb.name = "LogBus"; add_child_autofree(lb)
	lb.set_script(load("res://scripts/autoload/log_bus.gd"))
	await get_tree().process_frame
	# Set a deterministic RUN_ID
	var rid := "TEST-RUN-ID"
	if lb.has_method("set_run_id"):
		lb.call("set_run_id", rid)
	await get_tree().process_frame
	# Log messages
	lb.call("debug", "dbg")
	lb.call("info", "info")
	lb.call("warn", "warn")
	lb.call("error", "err")
	await get_tree().process_frame
	# Check file exists in user://logs
	var fpath := "user://logs/run-" + rid + ".log"
	var f := FileAccess.open(fpath, FileAccess.READ)
	assert_not_null(f)
	var text := f.get_as_text()
	assert_true(text.find("Log start RUN_ID=") != -1)
	assert_true(text.find("[LogBus:DEBUG] dbg") != -1)
	assert_true(text.find("[LogBus:INFO] info") != -1)
	assert_true(text.find("[LogBus:WARN] warn") != -1)
	assert_true(text.find("[LogBus:ERROR] err") != -1)

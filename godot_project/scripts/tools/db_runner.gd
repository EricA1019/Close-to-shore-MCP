extends SceneTree

## Headless runner for ResourceDbBridge (Phase 1 scaffold).
## Usage (example):
##   godot4 --headless --path godot_project -s res://scripts/tools/db_runner.gd -- build_index
## Prints JSON-like dictionaries to stdout for CLI consumption later.

func _initialize():
	var args: PackedStringArray = OS.get_cmdline_args()
	# Only consider custom args after the `--` separator to avoid capturing the script path or engine flags.
	var user_args := PackedStringArray()
	var sep_idx := args.find("--")
	if sep_idx != -1 and sep_idx < args.size() - 1:
		for i in range(sep_idx + 1, args.size()):
			user_args.append(args[i])
	else:
		# Fallback: detect subcommand anywhere in args (Godot may not pass `--` through).
		var known := ["build_index", "list", "get", "search", "export", "validate"]
		var detected_mode := ""
		for a in args:
			if known.has(a):
				detected_mode = a
				break
		if detected_mode != "":
			user_args.append(detected_mode)
			# Also capture any flags like --roots=..., --id=..., etc.
			for a in args:
				if a.begins_with("--"):
					user_args.append(a)
		else:
			# Last resort: pick non-flag, non-script args as user args.
			for a in args:
				if a.begins_with("-"):
					continue
				if a.ends_with(".gd") or a.begins_with("res://"):
					continue
				user_args.append(a)

	var mode := "build_index"
	if user_args.size() > 0:
		mode = String(user_args[0])

	# Defaults; allow override with --roots=path1,path2
	var roots := PackedStringArray(["res://data", "res://addons/resource_databases"])
	var use_cache := true
	var verify_hash := 0.0
	for a in user_args:
		if a.begins_with("--roots="):
			var list = a.substr(8).split(",", false)
			roots = PackedStringArray(list)
		elif a == "--no-cache":
			use_cache = false
		elif a == "--use-cache":
			use_cache = true
		elif a.begins_with("--verify-hash="):
			verify_hash = float(a.substr(14))

	var bridge = ClassDB.instantiate("ResourceDbBridge")
	if bridge == null:
		push_error("ResourceDbBridge class not found; ensure gdext built and loaded")
		quit(1)
		return

	# Configure cache options
	bridge.set_cache_options(use_cache, verify_hash)

	match mode:
		"build_index":
			var t0 := Time.get_ticks_usec()
			var count = bridge.build_index(roots)
			var elapsed_ms := float(Time.get_ticks_usec() - t0) / 1000.0
			var stats = bridge.stats()
			var cstats = bridge.cache_stats()
			var tstats = bridge.timings()
			# Enrich cache stats with verify_rate for visibility
			cstats["verify_rate"] = verify_hash
			var timings := {"total_ms": elapsed_ms}
			# Merge more detailed timings if available
			for k in tstats.keys():
				timings[k] = tstats[k]
			print(JSON.stringify({"ok": true, "count": count, "collections": stats["collections"], "cache": cstats, "timings": timings}))
		"list":
			bridge.build_index(roots)
			print(JSON.stringify({"collections": bridge.list_collections()}))
		"get":
			bridge.build_index(roots)
			var id := ""
			for a in user_args:
				if a.begins_with("--id="):
					id = a.substr(5)
			var entry = bridge.get(id)
			var out = {"entry": entry}
			print(JSON.stringify(out))
		"search":
			bridge.build_index(roots)
			var q := ""
			var coll := ""
			var limit := 50
			for a in user_args:
				if a.begins_with("--q="):
					q = a.substr(4)
				elif a.begins_with("--collection="):
					coll = a.substr(13)
				elif a.begins_with("--limit="):
					limit = int(a.substr(8))
			var results = bridge.search(q, coll, limit)
			print(JSON.stringify({"results": results}))
		"export":
			var t0e := Time.get_ticks_usec()
			bridge.build_index(roots)
			var elapsed_ms_e := float(Time.get_ticks_usec() - t0e) / 1000.0
			var out_path := "user://resource_db_index.json"
			for a in user_args:
				if a.begins_with("--out="):
					out_path = a.substr(6)
			var ok = bridge.save_index(out_path)
			var cstats = bridge.cache_stats()
			var tstats = bridge.timings()
			cstats["verify_rate"] = verify_hash
			var timings := {"total_ms": elapsed_ms_e}
			for k in tstats.keys():
				timings[k] = tstats[k]
			print(JSON.stringify({"ok": ok, "out": out_path, "cache": cstats, "timings": timings}))
		"validate":
			# Build index first; allow custom roots.
			var t0v := Time.get_ticks_usec()
			bridge.build_index(roots)
			var _elapsed_ms_v := float(Time.get_ticks_usec() - t0v) / 1000.0
			var strict := false
			for a in user_args:
				if a == "--strict":
					strict = true
			var report: Dictionary = bridge.validate()
			var tstats = bridge.timings()
			var summary: Dictionary = report.get("summary", {}) as Dictionary
			var errors := int(summary.get("errors", 0))
			var warnings := int(summary.get("warnings", 0))
			var ok := errors == 0
			var out := {
				"ok": ok,
				"summary": summary,
				"issues": report.get("issues", []),
				"timings": tstats
			}
			print(JSON.stringify(out))
			if not ok:
				quit(1)
				return
			elif strict and warnings > 0:
				quit(1)
				return
		_:
			push_warning("Unknown db_runner mode: %s" % mode)

	quit()

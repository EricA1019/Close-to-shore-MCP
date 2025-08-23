extends SceneTree

# Usage (headless):
# godot4 --headless --path godot_project -s res://scripts/tools/scene_smoke_runner.gd -- --index res://scripts/tools/scene_index.json
# Optional: --filter "apartment" to only run scenes whose path contains the filter.

var _index_path: String = "res://scripts/tools/scene_index.json"
var _filter: String = ""
var _out_path: String = ""

func _initialize() -> void:
	# Parse CLI after "--"
	var args := OS.get_cmdline_user_args()
	for i in range(0, args.size()):
		if args[i] == "--index" and i + 1 < args.size():
			_index_path = args[i + 1]
		elif args[i] == "--filter" and i + 1 < args.size():
			_filter = args[i + 1]
		elif args[i] == "--out" and i + 1 < args.size():
			_out_path = args[i + 1]

	var list: Array = _load_index(_index_path)
	if list.is_empty():
		printerr("[SMOKE] No scenes to run. index=", _index_path)
		quit(1)
	var summary: Dictionary = await _run_all(list)
	if _out_path != "":
		_write_summary(_out_path, summary)
	# Exit non-zero if any failures
	var failed: int = int(summary.get("failed", 0))
	quit(0 if failed == 0 else 1)

func _load_index(path: String) -> Array:
	if not ResourceLoader.exists(path):
		printerr("[SMOKE] Index not found: ", path)
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("[SMOKE] Index JSON invalid: ", path)
		return []
	var dict: Dictionary = parsed
	var arr: Array = dict.get("scenes", [])
	if _filter != "":
		arr = arr.filter(func(p): return str(p).findn(_filter) != -1)
	return arr

func _run_scene(path: String) -> bool:
	print("[SMOKE] Loading: ", path)
	if not ResourceLoader.exists(path):
		printerr("[SMOKE] Missing: ", path)
		return false
	var baseline := _snapshot_root_children()
	var ps: PackedScene = load(path)
	if ps == null:
		printerr("[SMOKE] Failed load: ", path)
		return false
	var inst := ps.instantiate()
	get_root().add_child(inst)
	await process_frame
	# Simple ready check: Scene instanced and one frame processed
	print("[SMOKE] OK: ", path)
	inst.queue_free()
	# Allow queued frees and timers to settle
	for i in 3:
		await process_frame
	_cleanup_new_children(baseline)
	return true

func _run_all(paths: Array) -> Dictionary:
	var ok: int = 0
	var results: Array = []
	for p in paths:
		var path := str(p)
		var res := await _run_scene(path)
		if res:
			ok += 1
		results.append({"path": path, "ok": res})
	var total := paths.size()
	var failed := total - ok
	print("[SMOKE] Summary: ", ok, "/", total, " scenes OK")
	return {
		"total": total,
		"passed": ok,
		"failed": failed,
		"results": results
	}

func _snapshot_root_children() -> Dictionary:
	var ids := {}
	for c in get_root().get_children():
		ids[c.get_instance_id()] = true
	return ids

func _cleanup_new_children(baseline: Dictionary) -> void:
	var removed := 0
	for c in get_root().get_children():
		var id := c.get_instance_id()
		if not baseline.has(id):
			c.queue_free()
			removed += 1
	if removed > 0:
		for i in 2:
			await process_frame

func _write_summary(out_path: String, data: Dictionary) -> void:
	var dir_path := out_path.get_base_dir()
	var abs_dir := ProjectSettings.globalize_path(dir_path)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var fa := FileAccess.open(out_path, FileAccess.WRITE)
	if fa == null:
		printerr("[SMOKE] Failed to open summary for write: ", out_path)
		return
	fa.store_string(JSON.stringify(data))
	fa.close()
	print("[SMOKE] JSON summary written: ", out_path)

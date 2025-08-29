extends SceneTree

# Usage (headless):
# godot4 --headless --path godot_project -s res://scripts/tools/scene_smoke_runner.gd -- --index res://scripts/tools/scene_index.json
# Optional: --filter "apartment" to only run scenes whose path contains the filter.

var _index_path: String = "res://scripts/tools/scene_index.json"
var _filter: String = ""
var _out_path: String = ""

# Skip lists to avoid loading plugin/editor scenes that are unsafe headless
const SKIP_PREFIXES := [
	"res://addons/gut/gui/",                        # GUT editor UI scenes
	"res://addons/gut/gut_loader_the_scene.tscn",   # references missing script in headless
	"res://addons/imgui-godot/",                   # ImGui registers singletons; unsafe to load repeatedly in smoke
	"res://addons/resource_databases/editor_only/", # Editor-only plugin UI
	"res://addons/maaacks_game_template/installer/", # Template installer dialogs
	"res://addons/maaacks_game_template/utilities/", # Network/util scenes
	# Project template/example groups that aren't part of core gameplay and often fail in headless
	"res://scenes/maaack_scenes/",
	"res://scenes/overlaid_menus/",
	"res://scenes/opening/",
	"res://scenes/loading_screen/",
	"res://scenes/main_menu/",
	# Incomplete or editor-import-dependent subtrees under game_scene
	"res://scenes/game_scene/levels/",
	"res://scenes/game_scene/tutorials/",
	"res://scenes/game_scene/game_ui.tscn",
	# Some addon examples reference missing demo scripts outside our repo
	"res://addons/ascii_grid/examples/UI_Mockup/"
]

# Allowed roots; when non-empty, paths must start with at least one of these
const ALLOWED_ROOTS := [
	"res://scenes/ui/",                         # Core UI
	"res://scenes/locations/",                  # Locations / rooms
	"res://scenes/ascii_min_demo/",             # Minimal ASCII demos we include
	"res://scenes/game_scene/",                 # The main game scene(s)
	"res://scenes/credits/",                    # Credits screens
	"res://addons/ascii_grid/examples/"          # Selected ASCII examples (further trimmed by SKIP_PREFIXES)
]

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
	# Apply CLI filter first if provided
	if _filter != "":
		arr = arr.filter(func(p): return str(p).findn(_filter) != -1)
	# Skip known-unsafe plugin/editor scenes
	arr = arr.filter(func(p):
		var _p := str(p)
		for skip in SKIP_PREFIXES:
			if _p.begins_with(skip):
				print("[SMOKE] Skipping (prefix): ", _p)
				return false
		# If allowed roots are defined, require at least one match
		if ALLOWED_ROOTS.size() > 0:
			for allowed_root in ALLOWED_ROOTS:
				if _p.begins_with(allowed_root):
					return true
			# Not in allowed roots, skip silently to reduce noise
			return false
		return true
	)
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
	# Optional ASCII diagnostics if scene includes MainUI/TermRect
	_var_ascii_diagnostics(inst)
	# Simple ready check: Scene instanced and one frame processed
	print("[SMOKE] OK: ", path)
	inst.queue_free()
	# Allow queued frees and timers to settle
	for i in 3:
		await process_frame
	_cleanup_new_children(baseline)
	return true

func _var_ascii_diagnostics(scene_root: Node) -> void:
	var main_ui := scene_root.get_node_or_null("MainUI")
	if main_ui == null:
		main_ui = _find_node_recursive(scene_root, func(n): return String(n.name).to_lower() == "mainui")
	if main_ui == null:
		return
	var main_panel := main_ui.get_node_or_null("%MainPanel")
	if main_panel == null:
		main_panel = main_ui.get_node_or_null("Body/LeftColumn/MainPanel")
	if main_panel == null:
		return
	var termrect := main_panel.get_node_or_null("TermRect")
	if termrect == null:
		return
	# Pull shader textures and print a tiny summary
	var mat: ShaderMaterial = termrect.material
	if mat == null:
		printerr("[SMOKE][ASCII] TermRect missing material")
		return
	var char_tex: ImageTexture = mat.get_shader_parameter("character_grid")
	var fg_tex: ImageTexture = mat.get_shader_parameter("fg_color")
	var bg_tex: ImageTexture = mat.get_shader_parameter("bg_color")
	if char_tex == null or fg_tex == null or bg_tex == null:
		printerr("[SMOKE][ASCII] Missing one or more textures: chars=", char_tex != null, ", fg=", fg_tex != null, ", bg=", bg_tex != null)
		return
	var img_chars: Image = char_tex.get_image()
	var w := img_chars.get_width()
	var h := img_chars.get_height()
	print("[SMOKE][ASCII] grid:", w, "x", h, " px TermRect:", termrect.size)
	# Sample the four corners and center red channel for quick sanity
	var cx := int(floor(float(w) / 2.0))
	var cy := int(floor(float(h) / 2.0))
	var points := [Vector2i(0,0), Vector2i(max(0,w-1),0), Vector2i(0,max(0,h-1)), Vector2i(max(0,w-1),max(0,h-1)), Vector2i(max(0,cx), max(0,cy))]
	var samples := []
	for p in points:
		if w > 0 and h > 0:
			samples.append(img_chars.get_pixel(p.x, p.y).r)
	print("[SMOKE][ASCII] samples:", samples)

func _find_node_recursive(scene_root: Node, predicate: Callable) -> Node:
	for c in scene_root.get_children():
		if predicate.call(c):
			return c
		var inner := _find_node_recursive(c, predicate)
		if inner:
			return inner
	return null

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

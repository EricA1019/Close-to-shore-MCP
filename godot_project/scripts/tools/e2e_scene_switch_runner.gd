extends SceneTree

# End-to-end scene switch check using the SceneLoader autoload.
# Usage:
#   godot4 --headless --path godot_project -s res://scripts/tools/e2e_scene_switch_runner.gd [-- --game <scene_path>]

var _game_path: String = ""

func _initialize() -> void:
	# Parse optional user args after "--"
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == "--game" and i + 1 < args.size():
			_game_path = args[i + 1]

	if _game_path == "":
		_game_path = await _derive_game_scene_path()

	if _game_path == "" or not ResourceLoader.exists(_game_path):
		printerr("[E2E] Invalid or missing game scene path: ", _game_path)
		quit(2)

	print("[E2E] Switching to:", _game_path)
	# Trigger foreground load; SceneLoader will show loading screen (configured) and swap when ready.
	var loader := get_root().get_node_or_null("/root/SceneLoader")
	if loader == null:
		printerr("[E2E] SceneLoader autoload not found at /root/SceneLoader")
		quit(7)
	loader.call("load_scene", _game_path, false)
	await loader.scene_loaded
	# Allow the autoload to call change_scene_to_resource and the new scene to process.
	for i in 2:
		await process_frame

	var current := get_current_scene()
	if current == null:
		printerr("[E2E] No current scene after switch")
		quit(3)

	# Find MainUI and ASCII TermRect
	var main_ui := current.get_node_or_null("MainUI")
	if main_ui == null:
		# Try to find anywhere in the current scene
		main_ui = _find_node_recursive(current, func(n): return String(n.name).to_lower() == "mainui")
	if main_ui == null:
		printerr("[E2E] MainUI not found in current scene: ", current.name)
		quit(4)

	var main_panel := main_ui.get_node_or_null("%MainPanel")
	if main_panel == null:
		main_panel = main_ui.get_node_or_null("Body/LeftColumn/MainPanel")
	if main_panel == null:
		printerr("[E2E] MainPanel not found under MainUI")
		quit(5)

	var termrect := main_panel.get_node_or_null("TermRect")
	if termrect == null:
		printerr("[E2E] TermRect not found in MainPanel")
		quit(6)

	print("[E2E] OK: MainUI + TermRect present after scene switch")
	quit(0)

func _derive_game_scene_path() -> String:
	# Prefer configured menu scene's game_scene_path if available; fallback to known path.
	var menu_paths := [
		"res://scenes/maaack_scenes/menus/main_menu/main_menu_with_animations.tscn",
		"res://addons/maaacks_game_template/examples/scenes/menus/main_menu/main_menu_with_animations.tscn"
	]
	for p in menu_paths:
		if ResourceLoader.exists(p):
			var ps := load(p) as PackedScene
			if ps:
				var inst := ps.instantiate()
				get_root().add_child(inst)
				await process_frame
				var mm := inst
				# Try to find a node with a 'game_scene_path' exported property
				if not _node_has_property(mm, "game_scene_path"):
					mm = _find_node_recursive(inst, func(n): return _node_has_property(n, "game_scene_path"))
				var path := ""
				if mm and _node_has_property(mm, "game_scene_path"):
					path = str(mm.get("game_scene_path"))
				inst.queue_free()
				await process_frame
				if path != "" and ResourceLoader.exists(path):
					return path
	# Fallback to project’s GameRoot
	var fallback := "res://scenes/game_scene/game_root.tscn"
	return fallback if ResourceLoader.exists(fallback) else ""


func _find_node_recursive(r: Node, pred: Callable) -> Node:
	if pred.call(r):
		return r
	for c in r.get_children():
		var found := _find_node_recursive(c, pred)
		if found:
			return found
	return null

func _node_has_property(n: Object, prop: String) -> bool:
	if n == null:
		return false
	var list := n.get_property_list()
	for d in list:
		if typeof(d) == TYPE_DICTIONARY and String(d.get("name", "")) == prop:
			return true
	return false

@tool
extends EditorPlugin

const CP437Exporter := preload("res://addons/cp437_tools/exporter.gd")

const CSV_PATH := "res://data/config/cp437_index.csv"
const JSON_PATH := "res://data/config/cp437_index.json"

var _menu_items := [
	"CP437: Export JSON from CSV",
	"CP437: Validate CSV",
	"CP437: Scratch Test"
]

func _enter_tree() -> void:
	add_tool_menu_item(_menu_items[0], _on_export_pressed)
	add_tool_menu_item(_menu_items[1], _on_validate_pressed)
	add_tool_menu_item(_menu_items[2], _on_scratch_pressed)

func _exit_tree() -> void:
	for item in _menu_items:
		remove_tool_menu_item(item)

func _on_export_pressed() -> void:
	var res: Array = CP437Exporter.load_csv_to_dict(CSV_PATH)
	var ok: bool = bool(res[0])
	var payload: Variant = res[1]
	if not ok:
		OS.alert("CSV parse failed:\n" + str(payload), "CP437 Export")
		return
	var d: Dictionary = (payload as Dictionary)
	var err: int = CP437Exporter.save_dict_to_json(d, JSON_PATH)
	if err != OK:
		OS.alert("Failed to write JSON: " + str(err), "CP437 Export")
	else:
		OS.alert("Exported to " + JSON_PATH, "CP437 Export")

func _on_validate_pressed() -> void:
	var res: Array = CP437Exporter.load_csv_to_dict(CSV_PATH)
	var ok: bool = bool(res[0])
	var payload: Variant = res[1]
	if not ok:
		OS.alert("CSV parse failed:\n" + str(payload), "CP437 Validate")
		return
	var issues: Array = []
	var d: Dictionary = (payload as Dictionary)
	var rules: Dictionary = d.get("rules", {})
	var reserved: Dictionary = rules.get("reserved", {})
	if not reserved.has("player"):
		issues.append("Rule reserved.player missing")
	if issues.size() == 0:
		OS.alert("CSV validation passed.", "CP437 Validate")
	else:
		OS.alert("CSV validation issues:\n- " + "\n- ".join(issues), "CP437 Validate")

func _on_scratch_pressed() -> void:
	# 1) Validate CSV thoroughly
	var v := CP437Exporter.validate_csv(CSV_PATH)
	var v_ok: bool = bool(v[0])
	var v_issues: Array = v[1]
	if not v_ok:
		OS.alert("Scratch: CSV validation failed:\n- " + "\n- ".join(v_issues), "CP437 Scratch Test")
		return
	# 2) Export JSON
	var res: Array = CP437Exporter.load_csv_to_dict(CSV_PATH)
	var ok: bool = bool(res[0])
	var payload: Variant = res[1]
	if not ok:
		OS.alert("Scratch: CSV parse failed:\n" + str(payload), "CP437 Scratch Test")
		return
	var d: Dictionary = (payload as Dictionary)
	var err: int = CP437Exporter.save_dict_to_json(d, JSON_PATH)
	if err != OK:
		OS.alert("Scratch: Failed to write JSON: " + str(err), "CP437 Scratch Test")
		return
	# 3) Exercise runtime loader resolve_tile
	var tmp_loader := Node.new()
	tmp_loader.set_script(load("res://scripts/systems/cp437_index_loader.gd"))
	if tmp_loader.has_method("_ready"):
		tmp_loader.call("_ready")
	var samples := {
		"entities": ["player", "angel", "demon"],
		"terrain": [
			"floor.wood", "floor.stone",
			"wall.solid", "wall.medium", "wall.light",
			"door.closed", "door.open",
			"stairs.up", "stairs.down",
			"ramp.up", "ramp.down",
			"channel.edge", "channel.floor",
			"track.vert", "track.horiz", "track.cross",
			"grate", "coffin", "stockpile",
			"workshop.frame.bracket", "workshop.frame.slash",
			"bed", "statue", "table", "chair", "cabinet", "chest",
			"weapon_rack", "armor_stand", "anvil", "restraint", "cage",
			"barrel", "bin", "hatch_cover", "floodgate",
			"lever.inactive", "lever.active"
		]
	}
	var failures: Array = []
	for group in samples.keys():
		for key in samples[group]:
			var tile := tmp_loader.call("resolve_tile", key, 0, Color.WHITE)
			if typeof(tile) != TYPE_DICTIONARY or not tile.has("codepoint"):
				failures.append("Key '%s' from %s did not resolve" % [key, group])
	if failures.size() == 0:
		OS.alert("Scratch: Passed. CSV validated, JSON exported, tiles resolved.", "CP437 Scratch Test")
	else:
		OS.alert("Scratch: Failures:\n- " + "\n- ".join(failures), "CP437 Scratch Test")

func _self_plugin_path_check() -> String:
	# Reads our own plugin.cfg to verify the script path is relative.
	# Returns empty string when OK, otherwise an error message.
	var cfg_path := "res://addons/cp437_tools/plugin.cfg"
	if not FileAccess.file_exists(cfg_path):
		return "plugin.cfg not found at " + cfg_path
	var f := FileAccess.open(cfg_path, FileAccess.READ)
	if f == null:
		return "Unable to open plugin.cfg"
	var content := f.get_as_text()
	f.close()
	var lines := content.split("\n", false)
	for ln in lines:
		if ln.strip_edges(true, true).begins_with("script="):
			var val := ln.split("=", false)
			if val.size() >= 2:
				var script_val := val[1].strip_edges().trim_prefix('"').trim_suffix('"')
				if script_val.begins_with("res://"):
					return "Invalid script path in plugin.cfg: use relative path 'plugin.gd' instead of '" + script_val + "'"
				if script_val != "plugin.gd":
					return "Unexpected script path: '" + script_val + "' (expected 'plugin.gd')"
				return ""
	return "No script= entry found in plugin.cfg"

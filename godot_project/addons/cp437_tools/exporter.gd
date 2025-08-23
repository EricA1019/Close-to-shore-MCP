extends RefCounted
class_name CP437Exporter

static func load_csv_to_dict(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return [false, "File not found: %s" % path]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return [false, "Unable to open file: %s" % path]
	var txt := f.get_as_text()
	f.close()
	var dict := _parse_csv(txt)
	return [true, dict]

static func save_dict_to_json(d: Dictionary, path: String) -> int:
	var json := JSON.stringify(d, "\t")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_OPEN
	f.store_string(json)
	f.close()
	return OK

static func _parse_csv(text: String) -> Dictionary:
	var result: Dictionary = {
		"entities": {},
		"materials": {},
		"terrain": {},
		"rules": {}
	}
	var lines := text.split("\n", false)
	if lines.size() == 0:
		return result
	for i in range(1, lines.size()):
		var line: String = lines[i].strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var cols := _split_csv_line(line)
		if cols.size() < 2:
			continue
		var category := cols[0]
		var key := cols[1]
		var codepoint_val: Variant = null
		if cols.size() > 2 and cols[2] != "":
			codepoint_val = int(cols[2])
		var fg_str: String = ""
		if cols.size() > 3:
			fg_str = cols[3]
		var bg_str: String = ""
		if cols.size() > 4:
			bg_str = cols[4]
		var style_str: String = ""
		if cols.size() > 5:
			style_str = cols[5]
		var fg_from_material_str: String = ""
		if cols.size() > 6:
			fg_from_material_str = cols[6]
		var value_str: String = ""
		if cols.size() > 7:
			value_str = cols[7]

		match category:
			"entities":
				var e: Dictionary = {}
				if codepoint_val != null:
					e["codepoint"] = int(codepoint_val)
				if fg_str != "":
					e["fg"] = fg_str
				if bg_str != "":
					e["bg"] = bg_str
				var style: Array = []
				if style_str != "":
					style = style_str.split("|", false)
				if style.size() > 0:
					e["style"] = style
				result["entities"][key] = e
			"materials":
				if fg_str != "":
					result["materials"][key] = { "fg": fg_str }
			"terrain":
				var t: Dictionary = {}
				if codepoint_val != null:
					t["codepoint"] = int(codepoint_val)
				if fg_str != "":
					t["fg"] = fg_str
				if bg_str != "":
					t["bg"] = bg_str
				if fg_from_material_str != "":
					t["fg_from_material"] = fg_from_material_str
				result["terrain"][key] = t
			"rules":
				if key == "fallback_to_defaults" and value_str != "":
					var s := value_str.strip_edges().to_lower()
					var bool_val: bool = (s == "true" or s == "1" or s == "yes" or s == "y")
					result["rules"]["fallback_to_defaults"] = bool_val
				elif key.begins_with("reserved."):
					var res_key := key.substr("reserved.".length())
					if not result["rules"].has("reserved"):
						result["rules"]["reserved"] = {}
					var reserved: Dictionary = result["rules"]["reserved"]
					if codepoint_val != null:
						reserved[res_key] = int(codepoint_val)
	return result

static func _split_csv_line(line: String) -> PackedStringArray:
	var cols: PackedStringArray = []
	var current := ""
	var in_quotes := false
	var i := 0
	while i < line.length():
		var ch := line[i]
		if ch == "\"":
			if in_quotes and i + 1 < line.length() and line[i + 1] == "\"":
				current += "\""
				i += 1
			else:
				in_quotes = not in_quotes
		elif ch == "," and not in_quotes:
			cols.append(current)
			current = ""
		else:
			current += ch
		i += 1
	cols.append(current)
	return cols

static func validate_csv(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return [false, ["File not found: %s" % path]]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return [false, ["Unable to open file: %s" % path]]
	var text := f.get_as_text()
	f.close()
	var issues: Array = []
	var lines := text.split("\n", false)
	if lines.size() == 0:
		return [false, ["CSV empty"]]
	var seen_entities: Dictionary = {}
	var seen_materials: Dictionary = {}
	var seen_terrain: Dictionary = {}
	var materials_catalog: Dictionary = {}
	var allowed_styles := ["overlay", "active_invert_allowed", "effect"]
	# Start from 1 to skip header
	for i in range(1, lines.size()):
		var raw := lines[i]
		var line := raw.strip_edges()
		if line == "" or line.begins_with("#"):
			continue
		var cols := _split_csv_line(line)
		if cols.size() < 2:
			issues.append("Line %d: too few columns" % i)
			continue
		var category := cols[0]
		var key := cols[1]
		var codepoint_str := (cols[2] if cols.size() > 2 else "")
		var fg := (cols[3] if cols.size() > 3 else "")
		var bg := (cols[4] if cols.size() > 4 else "")
		var style_str := (cols[5] if cols.size() > 5 else "")
		var fg_from_material := (cols[6] if cols.size() > 6 else "")
		var value_str := (cols[7] if cols.size() > 7 else "")

		# Helpers
		var has_codepoint := codepoint_str != ""
		var codepoint := -1
		if has_codepoint:
			if not _is_int(codepoint_str):
				issues.append("Line %d: codepoint '%s' is not an integer" % [i, codepoint_str])
			else:
				codepoint = int(codepoint_str)
				if codepoint < 0 or codepoint > 255:
					issues.append("Line %d: codepoint %d out of 0..255" % [i, codepoint])
		if fg != "" and not _is_hex_color(fg):
			issues.append("Line %d: fg '%s' is not a valid hex color (#RRGGBB)" % [i, fg])
		if bg != "" and not _is_hex_color(bg):
			issues.append("Line %d: bg '%s' is not a valid hex color (#RRGGBB)" % [i, bg])
		if style_str != "":
			for token in style_str.split("|", false):
				if token not in allowed_styles:
					issues.append("Line %d: WARN unknown style '%s'" % [i, token])

		match category:
			"materials":
				if key in seen_materials:
					issues.append("Line %d: duplicate material key '%s'" % [i, key])
				else:
					seen_materials[key] = true
					materials_catalog[key] = true
			"entities":
				if key in seen_entities:
					issues.append("Line %d: duplicate entity key '%s'" % [i, key])
				else:
					seen_entities[key] = true
				if not has_codepoint:
					issues.append("Line %d: entity '%s' missing codepoint" % [i, key])
			"terrain":
				if key in seen_terrain:
					issues.append("Line %d: duplicate terrain key '%s'" % [i, key])
				else:
					seen_terrain[key] = true
				if not has_codepoint:
					issues.append("Line %d: terrain '%s' missing codepoint" % [i, key])
				if fg == "" and fg_from_material == "":
					issues.append("Line %d: terrain '%s' must have fg or fg_from_material" % [i, key])
				if fg_from_material != "" and not materials_catalog.has(fg_from_material):
					issues.append("Line %d: terrain '%s' references unknown material '%s'" % [i, key, fg_from_material])
			"rules":
				# Will validate reserved below after full pass
				pass
			_:
				issues.append("Line %d: unknown category '%s'" % [i, category])

	# Additional semantic checks
	if not seen_entities.has("player"):
		issues.append("Entity 'player' missing")
	else:
		# Check that in CSV text there's a player with codepoint 64
		# (We can't easily look back up its codepoint now; ensure presence by parsing dict)
		var dict_res := load_csv_to_dict(path)
		if bool(dict_res[0]):
			var d: Dictionary = dict_res[1]
			var pe: Dictionary = d.get("entities", {}).get("player", {})
			if not pe.has("codepoint") or int(pe["codepoint"]) != 64:
				issues.append("Entity 'player' must use codepoint 64 (@)")
			var rules: Dictionary = d.get("rules", {})
			var reserved: Dictionary = rules.get("reserved", {})
			if not reserved.has("player"):
				issues.append("Rule 'reserved.player' missing")
			else:
				if int(reserved["player"]) != 64:
					issues.append("Rule 'reserved.player' must be 64 (@)")

	var ok := true
	# Consider WARN as non-fatal; anything not starting with 'WARN' is fatal
	for msg in issues:
		if not (str(msg).find("WARN") == 0):
			ok = false
	return [ok, issues]

static func _is_int(s: String) -> bool:
	for c in s:
		if c < '0' or c > '9':
			return false
	return s.length() > 0

static func _is_hex_color(s: String) -> bool:
	if s.length() != 7:
		return false
	if s[0] != '#':
		return false
	for i in range(1, 7):
		var ch := s[i]
		var ok := (ch >= '0' and ch <= '9') or (ch >= 'a' and ch <= 'f') or (ch >= 'A' and ch <= 'F')
		if not ok:
			return false
	return true

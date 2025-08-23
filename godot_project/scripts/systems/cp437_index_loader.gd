extends Node
## CP437 Index Loader
## Loads mapping from CSV (preferred) at res://data/config/cp437_index.csv
## falls back to JSON at res://data/config/cp437_index.json

const INDEX_PATH_JSON := "res://data/config/cp437_index.json"
const INDEX_PATH_CSV := "res://data/config/cp437_index.csv"

var _index: Dictionary = {}

func _ready() -> void:
    _index = _load_index()

func _load_index() -> Dictionary:
    var d: Dictionary = {}
    # Try CSV first
    if FileAccess.file_exists(INDEX_PATH_CSV):
        var csv := FileAccess.open(INDEX_PATH_CSV, FileAccess.READ)
        if csv:
            var csv_text := csv.get_as_text()
            csv.close()
            var parsed_csv := _parse_csv(csv_text)
            if parsed_csv.size() > 0:
                return parsed_csv
    # Fallback to JSON
    if FileAccess.file_exists(INDEX_PATH_JSON):
        var f := FileAccess.open(INDEX_PATH_JSON, FileAccess.READ)
        if f != null:
            var txt: String = f.get_as_text()
            f.close()
            var parsed: Variant = JSON.parse_string(txt)
            if typeof(parsed) == TYPE_DICTIONARY:
                return parsed as Dictionary
    return d

func _parse_csv(text: String) -> Dictionary:
    # CSV schema: category,key,codepoint,fg,bg,style,fg_from_material,value,notes
    var result: Dictionary = {
        "entities": {},
        "materials": {},
        "terrain": {},
        "rules": {}
    }
    var lines := text.split("\n", false)
    if lines.size() == 0:
        return result
    # Skip header; handle optional CRLF
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
        # var notes := (cols[8] if cols.size() > 8 else "")

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
                # rules lines: key may be nested with dots, use "value" for scalar
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

func _split_csv_line(line: String) -> PackedStringArray:
    # Simple CSV splitter that supports commas inside quotes and escaped quotes
    var cols: PackedStringArray = []
    var current := ""
    var in_quotes := false
    var i := 0
    while i < line.length():
        var ch := line[i]
        if ch == "\"":
            if in_quotes and i + 1 < line.length() and line[i + 1] == "\"":
                current += "\"" # Escaped quote
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

func get_entity(key: String) -> Dictionary:
    return _index.get("entities", {}).get(key, {})

func get_material(key: String) -> Dictionary:
    return _index.get("materials", {}).get(key, {})

func get_terrain(key: String) -> Dictionary:
    return _index.get("terrain", {}).get(key, {})

func get_rules() -> Dictionary:
    return _index.get("rules", {})

func resolve_tile(key: String, fallback_codepoint: int = -1, fallback_color: Color = Color.WHITE) -> Dictionary:
    # Returns a dictionary: { codepoint: int, fg: Color, bg: Color?, style: Array }
    var e := get_entity(key)
    if e.size() > 0:
        return _as_tile(e)
    var t := get_terrain(key)
    if t.size() > 0:
        return _as_tile(t)
    var rules := get_rules()
    if rules.get("fallback_to_defaults", true) and fallback_codepoint >= 0:
        return { "codepoint": fallback_codepoint, "fg": fallback_color, "bg": null, "style": [] }
    return {}

func _as_tile(src: Dictionary) -> Dictionary:
    var cp: int = int(src.get("codepoint", -1))
    var fg: Variant = src.get("fg", null)
    var bg: Variant = src.get("bg", null)
    var style: Array = src.get("style", [])
    if typeof(fg) == TYPE_STRING:
        fg = Color(fg)
    if typeof(bg) == TYPE_STRING:
        bg = Color(bg)
    if src.has("fg_from_material"):
        var mat: Dictionary = get_material(str(src.get("fg_from_material")))
        if mat.has("fg"):
            fg = Color(mat.get("fg"))
    return { "codepoint": cp, "fg": fg, "bg": bg, "style": style }

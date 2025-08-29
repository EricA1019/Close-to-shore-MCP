extends Node

## ContentDB: thin runtime wrapper around the Resource Databases plugin Database resource.
## Usage:
## - Create a database via the plugin UI and save it (e.g., res://data/content_database.tres)
## - Optionally set ProjectSettings key `resource_databases/content_db_path` to your DB path
## - Access via the autoload: ContentDB.get("items/sword") or ContentDB.fetch("items", "sword")

var database: Database

signal database_loaded(path: String)

const DEFAULT_DB_PATH := "res://data/content_database.tres"
const SETTINGS_KEY := "resource_databases/content_db_path"

func _ready() -> void:
    # Load on boot if possible
    var path := DEFAULT_DB_PATH
    if ProjectSettings.has_setting(SETTINGS_KEY):
        var v: Variant = ProjectSettings.get_setting(SETTINGS_KEY)
        if typeof(v) == TYPE_STRING and String(v) != "":
            path = String(v)
    if ResourceLoader.exists(path):
        load_database(path)
    else:
        push_warning("[ContentDB] Database not found at %s. Set %s or create the DB via the plugin UI." % [path, SETTINGS_KEY])
    # Ensure we have an index available; if not, build one at runtime by scanning data dirs.
    _ensure_runtime_index()

func load_database(path: String) -> void:
    var db := load(path)
    if db and db is Database:
        database = db
        emit_signal("database_loaded", path)
        print("[ContentDB] Loaded database ", path)
    else:
        push_error("[ContentDB] Failed to load Database at %s" % path)
    # Try to build an index if needed (useful when loading a .tres that defines collections but isn't baked).
    _ensure_runtime_index()

func set_database(db: Database) -> void:
    database = db
    emit_signal("database_loaded", "<manual>")
    _ensure_runtime_index()

# Convenience: fetch by string ("collection/entry" or "collection:category")
func get_entry(path_or_tag: String) -> Variant:
    if not database:
        return null
    return database.fetch_data_string(path_or_tag)

func fetch(collection: StringName, id: Variant) -> Resource:
    if not database:
        return null
    # Avoid calling into DB if data not initialized
    if not ("_collections_data" in database) or typeof(database._collections_data) != TYPE_DICTIONARY or database._collections_data.size() == 0:
        return null
    var id_sn: StringName = StringName("")
    if typeof(id) == TYPE_STRING_NAME:
        id_sn = id
    elif typeof(id) == TYPE_STRING:
        id_sn = StringName(id)
    elif typeof(id) == TYPE_INT:
        # Some collections could use ints; cast to StringName to pass validation (DB will accept int too)
        id_sn = StringName(str(id))
    if typeof(id) == TYPE_STRING:
        id_sn = StringName(id)
    return database.fetch_data(StringName(collection), id_sn)

func fetch_collection(collection: StringName) -> Dictionary:
    if not database:
        return {}
    if not ("_collections_data" in database) or typeof(database._collections_data) != TYPE_DICTIONARY or database._collections_data.size() == 0:
        return {}
    return database.fetch_collection_data(StringName(collection))

func fetch_category(collection: StringName, category: StringName) -> Dictionary:
    if not database:
        return {}
    if not ("_collections_data" in database) or typeof(database._collections_data) != TYPE_DICTIONARY or database._collections_data.size() == 0:
        return {}
    return database.fetch_category_data(StringName(collection), StringName(category))

func is_in_category(collection: StringName, id: Variant, category: StringName) -> bool:
    if not database:
        return false
    if not ("_collections_data" in database) or typeof(database._collections_data) != TYPE_DICTIONARY or database._collections_data.size() == 0:
        return false
    var id_sn: StringName = StringName("")
    if typeof(id) == TYPE_STRING_NAME:
        id_sn = id
    elif typeof(id) == TYPE_STRING:
        id_sn = StringName(id)
    elif typeof(id) == TYPE_INT:
        id_sn = StringName(str(id))
    if typeof(id) == TYPE_STRING:
        id_sn = StringName(id)
    return database.is_data_in_category(StringName(collection), id_sn, StringName(category))

# --- Runtime indexing fallback ---
const _DEFAULT_COLLECTION_DIRS := {
    "entities": "res://data/entities",
    "abilities": "res://data/abilities",
    "statuses": "res://data/statuses",
}

func _ensure_runtime_index() -> void:
    if not database:
        return
    # If already indexed, skip.
    if "_collections_data" in database and typeof(database._collections_data) == TYPE_DICTIONARY and database._collections_data.size() > 0:
        return
    # Build an index by scanning known collection folders.
    var built := _build_collections_data()
    if built.size() > 0:
        database._collections_data = built
        var total := 0
        for c in built:
            total += (built[c][&"ints_to_locators"] as Dictionary).size()
        print("[ContentDB] Generated runtime index for ", built.keys(), " entries=", total)

func _build_collections_data() -> Dictionary:
    var data := {}
    for coll in _DEFAULT_COLLECTION_DIRS.keys():
        var dir_path: String = String(_DEFAULT_COLLECTION_DIRS[coll])
        var entry := _scan_collection(String(coll), dir_path)
        if (entry[&"ints_to_locators"] as Dictionary).size() > 0:
            data[StringName(coll)] = entry
    return data

func _scan_collection(coll: String, dir_path: String) -> Dictionary:
    var ints_to_strings := {}
    var strings_to_ints := {}
    var ints_to_locators := {}
    var categories_to_ints := {} # empty by default
    var counter := 0
    if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(dir_path)):
        return {
            &"ints_to_strings": ints_to_strings,
            &"strings_to_ints": strings_to_ints,
            &"ints_to_locators": ints_to_locators,
            &"categories_to_ints": categories_to_ints,
        }
    var da := DirAccess.open(dir_path)
    if not da:
        return {
            &"ints_to_strings": ints_to_strings,
            &"strings_to_ints": strings_to_ints,
            &"ints_to_locators": ints_to_locators,
            &"categories_to_ints": categories_to_ints,
        }
    da.list_dir_begin()
    while true:
        var fname := da.get_next()
        if fname == "":
            break
        if da.current_is_dir():
            continue
        if not (fname.ends_with(".tres") or fname.ends_with(".res")):
            continue
        var path := dir_path.path_join(fname)
        if not ResourceLoader.exists(path):
            continue
        var res: Resource = load(path)
        if res == null:
            continue
        # Filter by expected resource type and ID prefix
        var id_value := ""
        var ok := false
        match coll:
            "entities":
                ok = res is EntityResource
                if ok: id_value = (res as EntityResource).id
            "abilities":
                ok = res is AbilityResource
                if ok: id_value = (res as AbilityResource).id
            "statuses":
                ok = res is StatusResource
                if ok: id_value = (res as StatusResource).id
            _:
                ok = false
        if not ok:
            continue
        if typeof(id_value) != TYPE_STRING or id_value == "":
            continue
        # Assign int ID and mappings
        var int_id := counter
        counter += 1
        ints_to_strings[int_id] = id_value
        strings_to_ints[StringName(id_value)] = int_id
        ints_to_locators[int_id] = path
    da.list_dir_end()
    return {
        &"ints_to_strings": ints_to_strings,
        &"strings_to_ints": strings_to_ints,
        &"ints_to_locators": ints_to_locators,
        &"categories_to_ints": categories_to_ints,
    }

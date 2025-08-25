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

func load_database(path: String) -> void:
    var db := load(path)
    if db and db is Database:
        database = db
        emit_signal("database_loaded", path)
        print("[ContentDB] Loaded database ", path)
    else:
        push_error("[ContentDB] Failed to load Database at %s" % path)

func set_database(db: Database) -> void:
    database = db
    emit_signal("database_loaded", "<manual>")

# Convenience: fetch by string ("collection/entry" or "collection:category")
func get_entry(path_or_tag: String) -> Variant:
    if not database:
        return null
    return database.fetch_data_string(path_or_tag)

func fetch(collection: StringName, id: Variant) -> Resource:
    if not database:
        return null
    return database.fetch_data(collection, id)

func fetch_collection(collection: StringName) -> Dictionary:
    if not database:
        return {}
    return database.fetch_collection_data(collection)

func fetch_category(collection: StringName, category: StringName) -> Dictionary:
    if not database:
        return {}
    return database.fetch_category_data(collection, category)

func is_in_category(collection: StringName, id: Variant, category: StringName) -> bool:
    if not database:
        return false
    return database.is_data_in_category(collection, id, category)

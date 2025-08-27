extends GutTest

# This test creates a temporary copy of the fixtures under user://, then mutates and deletes
# to assert cache stats reflect changed and deleted roots across runs.

func _copy_file(src: String, dst: String) -> void:
    var dir := dst.get_base_dir()
    DirAccess.make_dir_recursive_absolute(dir)
    var data := FileAccess.get_file_as_bytes(src)
    var f := FileAccess.open(dst, FileAccess.WRITE)
    f.store_buffer(data)
    f.close()

func _write_json(path: String, data: Dictionary) -> void:
    var dir := path.get_base_dir()
    DirAccess.make_dir_recursive_absolute(dir)
    var f := FileAccess.open(path, FileAccess.WRITE)
    f.store_string(JSON.stringify(data))
    f.close()

func test_cache_changed_and_deleted_counts():
    var base_src := "res://tests/fixtures/resource_db/index.json"
    var base_dst := "user://tmp_db/a/index.json"
    _copy_file(base_src, base_dst)

    var bridge = ClassDB.instantiate("ResourceDbBridge")
    bridge.set_cache_options(true, 1.0)

    # First run on root A
    var roots = PackedStringArray(["user://tmp_db/a"])
    bridge.build_index(roots)
    var s1: Dictionary = bridge.cache_stats()
    assert_eq(int(s1.get("changed", -1)), 1, "Initial build should mark changed=1 for new root")

    # Second run on same root => should be a hit
    bridge.build_index(roots)
    var s2: Dictionary = bridge.cache_stats()
    assert_eq(int(s2.get("hits", -1)), 1, "Second build should be a cache hit")

    # Mutate the index.json (change title) to force changed
    var json_text := FileAccess.get_file_as_string(base_dst)
    var json = JSON.parse_string(json_text)
    json["entries"][0]["title"] = "Screwdriver X"
    _write_json(base_dst, json)

    bridge.build_index(roots)
    var s3: Dictionary = bridge.cache_stats()
    assert_eq(int(s3.get("changed", -1)), 1, "After mutation, should count as changed=1")

    # Now add a second root B and then remove A to test deleted
    var base_dst_b := "user://tmp_db/b/index.json"
    _copy_file(base_src, base_dst_b)
    var roots_ab = PackedStringArray(["user://tmp_db/a", "user://tmp_db/b"])
    bridge.build_index(roots_ab)
    # Remove A from roots and rebuild
    var roots_b = PackedStringArray(["user://tmp_db/b"])
    bridge.build_index(roots_b)
    var s4: Dictionary = bridge.cache_stats()
    assert_true(int(s4.get("deleted", 0)) >= 1, "Dropping a root should increment deleted count")

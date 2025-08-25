extends "res://addons/gut/test.gd"

class FakeDB:
    func fetch_data_string(s: String):
        if s == "items/sword":
            return Resource.new()
        return null
    func fetch_data(_c, _i): return null
    func fetch_collection_data(_c): return {}
    func fetch_category_data(_c, _t): return {}
    func is_data_in_category(_c, _i, _t): return false

func test_content_db_can_set_and_fetch():
    var svc := get_tree().get_root().get_node_or_null("/root/ContentDB")
    assert_not_null(svc, "ContentDB autoload should exist")
    svc.set_database(FakeDB.new())
    var v = svc.get_entry("items/sword")
    assert_not_null(v, "Fetch via get_entry returns a resource when DB provides it")
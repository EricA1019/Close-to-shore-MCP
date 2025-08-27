extends GutTest

func test_interactive_apartment_loads_from_db():
    var scene := preload("res://scenes/ui/interactive_apartment.tscn")
    var apt = scene.instantiate()
    add_child_autofree(apt)

    await get_tree().process_frame

    assert_true(apt.has_method("is_loaded_from_db"), "Apartment should expose is_loaded_from_db()")
    var from_db: bool = apt.is_loaded_from_db()
    assert_true(from_db, "Apartment layout should be loaded from Resource DB (res://data/layouts/apartment.json)")

    if not from_db:
        print("[Warn] Layout fell back to built-in layout; ensure res://data/layouts/apartment.json and index exist.")

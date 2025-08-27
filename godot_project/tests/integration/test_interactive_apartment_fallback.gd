extends GutTest

# Verifies that when the DB layout is unavailable, InteractiveApartment falls back
# to the built-in layout (we check via is_loaded_from_db == false).

var _orig_res := "res://data/index.json"
var _bak_abs := ""

func before_all():
    if not ResourceLoader.exists(_orig_res):
        return
    var orig_abs := ProjectSettings.globalize_path(_orig_res)
    _bak_abs = orig_abs + ".bak"
    # Best-effort: remove any stale backup
    DirAccess.remove_absolute(_bak_abs)
    var ok := DirAccess.rename_absolute(orig_abs, _bak_abs)
    assert_true(ok == OK, "Should be able to temporarily rename index.json to force fallback")

func after_all():
    if _bak_abs == "":
        return
    var orig_abs := ProjectSettings.globalize_path(_orig_res)
    # Try to restore; ignore errors if already restored
    DirAccess.rename_absolute(_bak_abs, orig_abs)

func test_fallback_when_db_missing():
    var scene := load("res://scenes/ui/interactive_apartment.tscn")
    var inst = scene.instantiate()
    add_child_autofree(inst)
    await wait_frames(1)
    assert_false(inst.is_loaded_from_db(), "Should not be loaded from DB when index is renamed/missing")
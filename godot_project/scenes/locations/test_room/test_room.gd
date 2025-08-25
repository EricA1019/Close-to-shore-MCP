extends Node

func _ready() -> void:
    if has_node("/root/LocationState"):
        var ls = get_node("/root/LocationState")
        if ls.has_method("set_location"):
            ls.call("set_location", "Test Room")
    print("[TestRoom] ready")

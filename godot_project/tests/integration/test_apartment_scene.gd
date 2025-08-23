extends GutTest

const UI_SCENE := "res://scenes/ui/main_ui.tscn"
const APARTMENT_SCENE := "res://scenes/locations/apartment/apartment.tscn"

func _spawn_ui() -> Node:
	var scene: PackedScene = load(UI_SCENE)
	var inst: Node = scene.instantiate()
	add_child_autofree(inst)
	await get_tree().process_frame
	return inst

func test_apartment_sets_location_in_top_status() -> void:
	# Ensure UI is present
	var ui := await _spawn_ui()
	# Apartment scene should set the location via LocationState autoload
	assert_true(ResourceLoader.exists(APARTMENT_SCENE), "Apartment scene should exist at %s" % APARTMENT_SCENE)
	var apt_scene: PackedScene = load(APARTMENT_SCENE)
	var apt := apt_scene.instantiate()
	add_child_autofree(apt)
	await get_tree().process_frame
	var top: HBoxContainer = ui.get_node("%TopStatus")
	var location_label: Label = top.get_node("LocationLabel")
	assert_eq(location_label.text, "Apartment", "Location label should reflect apartment scene tag")

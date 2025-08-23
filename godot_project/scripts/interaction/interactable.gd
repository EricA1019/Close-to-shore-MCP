class_name Interactable
extends Node

signal selected(poi: Interactable)

@export var poi_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var actions: Array = [] # Array of { id: String, label: String }

func select() -> void:
	emit_signal("selected", self)

func on_action(_action_id: String) -> void:
	# Default no-op; POIs can override
	pass

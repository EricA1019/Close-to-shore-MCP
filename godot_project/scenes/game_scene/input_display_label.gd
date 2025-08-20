extends Label

@export var action : String
@export var include_key : bool = true
@export var include_name : bool = true

func update_label() -> void:
	var action_key = InputHelper.get_action_display_event(action)
	var action_name = "" if action.is_empty() else InputHelper.get_action_display_name(action)
	var text_items = []
	if include_name and not action_name.is_empty():
		text_items.append(action_name)
	if include_key and action_key:
		text_items.append(InputHelper.get_event_display_string(action_key))
	text = " - ".join(text_items)

func _ready() -> void:
	update_label()


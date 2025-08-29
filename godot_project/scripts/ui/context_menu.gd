extends Panel
class_name ContextMenu

## Context menu for inventory items with various action buttons

signal action_selected(action: String, item_data: Dictionary)

@onready var item_name_label: Label = $VBoxContainer/ItemName
@onready var examine_button: Button = $VBoxContainer/ButtonContainer/ExamineButton
@onready var use_button: Button = $VBoxContainer/ButtonContainer/UseButton
@onready var equip_button: Button = $VBoxContainer/ButtonContainer/EquipButton
@onready var drop_button: Button = $VBoxContainer/ButtonContainer/DropButton

var current_item: Dictionary = {}

func _ready() -> void:
	# Hide initially
	visible = false
	
	# Connect button signals
	examine_button.pressed.connect(_on_examine_pressed)
	use_button.pressed.connect(_on_use_pressed)
	equip_button.pressed.connect(_on_equip_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	
	# Hide when clicking outside
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var global_rect = get_global_rect()
			if not global_rect.has_point(mouse_event.global_position):
				hide_menu()

func show_menu(item_data: Dictionary, menu_position: Vector2) -> void:
	current_item = item_data
	
	# Update item name
	item_name_label.text = item_data.get("name", "Unknown Item")
	
	# Show/hide buttons based on item type
	var item_type = item_data.get("type", "")
	use_button.visible = item_data.get("consumable", false)
	equip_button.visible = item_type in ["weapon", "armor", "accessory"]
	
	# Position the menu
	global_position = menu_position
	
	# Make sure menu stays on screen
	var viewport_size = get_viewport().get_visible_rect().size
	if global_position.x + size.x > viewport_size.x:
		global_position.x = viewport_size.x - size.x
	if global_position.y + size.y > viewport_size.y:
		global_position.y = viewport_size.y - size.y
	
	# Show the menu
	visible = true
	
	# Focus first button for keyboard navigation
	examine_button.grab_focus()

func hide_menu() -> void:
	visible = false
	current_item.clear()

func _on_examine_pressed() -> void:
	emit_signal("action_selected", "examine", current_item)
	hide_menu()

func _on_use_pressed() -> void:
	emit_signal("action_selected", "use", current_item)
	hide_menu()

func _on_equip_pressed() -> void:
	emit_signal("action_selected", "equip", current_item)
	hide_menu()

func _on_drop_pressed() -> void:
	emit_signal("action_selected", "drop", current_item)
	hide_menu()

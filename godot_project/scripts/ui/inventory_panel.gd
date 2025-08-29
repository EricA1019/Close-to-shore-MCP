extends Panel
class_name InventoryPanel

## Inventory panel showing detective's items with clickable interaction

signal item_clicked(item_data: Dictionary, click_position: Vector2)

@onready var title_label: Label = Label.new()
@onready var scroll_container: ScrollContainer = ScrollContainer.new()
@onready var item_container: VBoxContainer = VBoxContainer.new()

var context_menu: Panel = null

func _ready() -> void:
	print("[InventoryPanel] _ready")
	
	# Set up layout
	_setup_ui()
	
	# Load context menu scene
	var context_menu_scene = preload("res://scenes/ui/context_menu.tscn")
	context_menu = context_menu_scene.instantiate()
	add_child(context_menu)
	context_menu.action_selected.connect(_on_context_action_selected)
	
	# Connect to inventory system when it's available
	_connect_to_inventory()
	
	# Load initial items (mock data for now)
	_load_mock_inventory()

func _setup_ui() -> void:
	# Use shared theme for panel styling

	# Title label
	title_label.text = "Detective's Inventory"
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_label)
	
	# Scroll container for items
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll_container)
	
	# Item container inside scroll
	scroll_container.add_child(item_container)
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Layout the title at top and scroll below
	title_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_label.add_theme_constant_override("margin_top", 8)
	title_label.add_theme_constant_override("margin_bottom", 8)
	
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_container.offset_top = 40  # Space for title

func _connect_to_inventory() -> void:
	# Try to connect to inventory system
	var inventory = get_node_or_null("/root/Inventory")
	if inventory and inventory.has_signal("inventory_changed"):
		inventory.inventory_changed.connect(_on_inventory_changed)
		print("[InventoryPanel] Connected to Inventory system")
		# Load real inventory data
		_load_real_inventory()
	else:
		# Fallback to mock data if no inventory system
		_load_mock_inventory()

func _exit_tree() -> void:
	# Disconnect inventory signal if connected and free context menu
	var inventory = get_node_or_null("/root/Inventory")
	if inventory and inventory.has_signal("inventory_changed") and inventory.is_connected("inventory_changed", _on_inventory_changed):
		inventory.inventory_changed.disconnect(_on_inventory_changed)
	if is_instance_valid(context_menu):
		context_menu.queue_free()

func _load_real_inventory() -> void:
	var inventory = get_node_or_null("/root/Inventory")
	if inventory and inventory.has_method("get_all_items"):
		var items = inventory.get_all_items()
		_display_items(items)
		print("[InventoryPanel] Loaded ", items.size(), " items from inventory system")
	else:
		_load_mock_inventory()

func _load_mock_inventory() -> void:
	# Mock data for testing
	var mock_items = [
		{
			"id": "I-001",
			"name": "Service Pistol", 
			"type": "weapon",
			"description": "A standard-issue detective's sidearm.",
			"equipped": true
		},
		{
			"id": "I-002", 
			"name": "Whiskey Bottle",
			"type": "consumable",
			"description": "Half-empty bottle of bourbon. Helps with the nerves.",
			"consumable": true,
			"uses_remaining": 3
		},
		{
			"id": "I-003",
			"name": "Leather Jacket",
			"type": "armor", 
			"description": "Well-worn detective's jacket. Offers some protection.",
			"equipped": false
		},
		{
			"id": "I-004",
			"name": "Badge",
			"type": "accessory",
			"description": "Your detective badge. Opens doors and earns respect.",
			"equipped": true
		}
	]
	
	_display_items(mock_items)

func _display_items(items: Array) -> void:
	# Clear existing items
	for child in item_container.get_children():
		child.queue_free()
	
	# Add items to the display
	for item in items:
		var item_button = _create_item_button(item)
		item_container.add_child(item_button)

func _create_item_button(item_data: Dictionary) -> Button:
	var button = Button.new()
	
	# Set button text with status indicators
	var display_text = item_data.get("name", "Unknown")
	if item_data.get("equipped", false):
		display_text += " [E]"
	if item_data.has("uses_remaining"):
		display_text += " (" + str(item_data.uses_remaining) + ")"
	
	button.text = display_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 14)
	
	# Store item data with the button
	button.set_meta("item_data", item_data)
	
	# Connect button press
	button.pressed.connect(_on_item_button_pressed.bind(button))
	
	return button

func _on_item_button_pressed(button: Button) -> void:
	var item_data = button.get_meta("item_data", {})
	if item_data.is_empty():
		return
	
	# Get global position for context menu
	var button_global_pos = button.global_position
	var click_position = button_global_pos + Vector2(button.size.x, 0)
	
	# Show context menu
	if context_menu:
		context_menu.show_menu(item_data, click_position)
	
	# Emit signal for external handling
	emit_signal("item_clicked", item_data, click_position)
	print("[InventoryPanel] Item clicked: ", item_data.get("name", "Unknown"))

func _on_context_action_selected(action: String, item_data: Dictionary) -> void:
	print("[InventoryPanel] Context action: ", action, " on ", item_data.get("name", "Unknown"))
	
	# Handle different actions
	match action:
		"examine":
			_examine_item(item_data)
		"use":
			_use_item(item_data)
		"equip":
			_equip_item(item_data)
		"drop":
			_drop_item(item_data)

func _examine_item(item_data: Dictionary) -> void:
	# Show item description in output panel
	var output_panel = get_node_or_null("../OutputPanel")
	if output_panel and output_panel.has_method("show_description"):
		var description = item_data.get("description", "No description available.")
		output_panel.show_description(description)
	print("[InventoryPanel] Examining: ", item_data.get("name", "Unknown"))

func _use_item(item_data: Dictionary) -> void:
	var inventory = get_node_or_null("/root/Inventory")
	if inventory and inventory.has_method("use_item"):
		var item_id = item_data.get("id", "")
		if inventory.use_item(item_id):
			# Show feedback
			var output_panel = get_node_or_null("../OutputPanel")
			if output_panel and output_panel.has_method("show_description"):
				output_panel.show_description("Used " + item_data.get("name", "item"))
	print("[InventoryPanel] Using: ", item_data.get("name", "Unknown"))

func _equip_item(item_data: Dictionary) -> void:
	var inventory = get_node_or_null("/root/Inventory")
	if inventory and inventory.has_method("equip_item"):
		var item_id = item_data.get("id", "")
		var slot = item_data.get("slot", "")
		if inventory.equip_item(item_id, slot):
			# Show feedback
			var output_panel = get_node_or_null("../OutputPanel")
			if output_panel and output_panel.has_method("show_description"):
				output_panel.show_description("Equipped " + item_data.get("name", "item"))
	print("[InventoryPanel] Equipping: ", item_data.get("name", "Unknown"))

func _drop_item(item_data: Dictionary) -> void:
	var inventory = get_node_or_null("/root/Inventory")
	if inventory and inventory.has_method("remove_item"):
		var item_id = item_data.get("id", "")
		if inventory.remove_item(item_id):
			# Show feedback
			var output_panel = get_node_or_null("../OutputPanel")
			if output_panel and output_panel.has_method("show_description"):
				output_panel.show_description("Dropped " + item_data.get("name", "item"))
	print("[InventoryPanel] Dropping: ", item_data.get("name", "Unknown"))

func _on_inventory_changed() -> void:
	# Reload inventory display when inventory changes
	print("[InventoryPanel] Inventory changed, reloading display")
	_load_real_inventory()

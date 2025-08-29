extends SceneTree

## Simple test script to verify inventory UI functionality

func _init():
	print("=== Inventory UI Test ===")
	
	# Load and instantiate the main UI scene
	var main_ui_scene = load("res://scenes/ui/main_ui.tscn")
	var main_ui = main_ui_scene.instantiate()
	
	# Add to scene tree
	root.add_child(main_ui)
	
	# Wait for ready
	await main_ui.ready
	
	# Find the inventory panel
	var inventory_panel = main_ui.get_node("VBoxContainer/HBoxContainer/InventoryPanel")
	
	if inventory_panel:
		print("✓ InventoryPanel found")
		print("✓ InventoryPanel type: ", inventory_panel.get_script())
		
		# Check if it has the scroll container
		var scroll_container = inventory_panel.get_node("ScrollContainer")
		if scroll_container:
			print("✓ ScrollContainer found")
			
			# Check for items
			var item_list = scroll_container.get_node("VBoxContainer")
			if item_list:
				print("✓ Item list container found")
				print("✓ Item count: ", item_list.get_child_count())
				
				# List all items
				for i in range(item_list.get_child_count()):
					var item_button = item_list.get_child(i)
					if item_button is Button:
						print("  - Item: ", item_button.text)
		
		# Check if context menu scene exists
		var context_menu_scene = load("res://scenes/ui/context_menu.tscn")
		if context_menu_scene:
			print("✓ Context menu scene loads successfully")
		else:
			print("✗ Context menu scene not found")
	else:
		print("✗ InventoryPanel not found in main UI")
	
	print("=== Test Complete ===")
	quit()

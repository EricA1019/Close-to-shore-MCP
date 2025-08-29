extends Node
class_name InventorySystem

## Detective's inventory system with equipment slots and bag storage

signal inventory_changed()
signal item_equipped(item_id: String, slot: String)
signal item_unequipped(item_id: String, slot: String)
signal item_used(item_id: String)

# Equipment slots
var equipped_items: Dictionary = {
	"weapon": null,
	"chest": null,
	"accessory": null
}

# Bag inventory (list of item IDs)
var bag_items: Array[String] = []

# Item data cache (loaded from JSON files)
var item_data: Dictionary = {}

func _ready() -> void:
	print("[Inventory] System initialized")
	_load_item_data()
	_load_starting_equipment()

func _load_item_data() -> void:
	# Load item definitions from JSON files
	var item_files = [
		"res://data/items/service_pistol.json",
		"res://data/items/whiskey_bottle.json", 
		"res://data/items/leather_jacket.json",
		"res://data/items/detective_badge.json"
	]
	
	for file_path in item_files:
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var json_text = file.get_as_text()
				file.close()
				
				var json = JSON.new()
				var parse_result = json.parse(json_text)
				if parse_result == OK:
					var item = json.data
					item_data[item.id] = item
					print("[Inventory] Loaded item: ", item.name)
				else:
					print("[Inventory] Failed to parse: ", file_path)

func _load_starting_equipment() -> void:
	# Detective starts with basic equipment
	add_item("I-004")  # Detective Badge
	add_item("I-001")  # Service Pistol
	add_item("I-002")  # Whiskey Bottle
	add_item("I-003")  # Leather Jacket
	
	# Equip some items by default
	equip_item("I-004", "accessory")  # Badge always equipped
	equip_item("I-001", "weapon")     # Pistol equipped

func add_item(item_id: String) -> bool:
	if not item_data.has(item_id):
		print("[Inventory] Unknown item: ", item_id)
		return false
	
	if not bag_items.has(item_id):
		bag_items.append(item_id)
		print("[Inventory] Added item: ", item_data[item_id].name)
		inventory_changed.emit()
		return true
	
	print("[Inventory] Item already in inventory: ", item_id)
	return false

func remove_item(item_id: String) -> bool:
	var index = bag_items.find(item_id)
	if index >= 0:
		bag_items.remove_at(index)
		print("[Inventory] Removed item: ", item_data.get(item_id, {}).get("name", item_id))
		inventory_changed.emit()
		return true
	return false

func equip_item(item_id: String, slot: String) -> bool:
	if not item_data.has(item_id):
		print("[Inventory] Cannot equip unknown item: ", item_id)
		return false
	
	var item = item_data[item_id]
	if item.get("slot", "") != slot:
		print("[Inventory] Item cannot be equipped in slot: ", slot)
		return false
	
	# Unequip current item in slot
	if equipped_items[slot]:
		unequip_item(equipped_items[slot])
	
	# Equip new item
	equipped_items[slot] = item_id
	print("[Inventory] Equipped: ", item.name, " in ", slot)
	item_equipped.emit(item_id, slot)
	inventory_changed.emit()
	return true

func unequip_item(item_id: String) -> bool:
	for slot in equipped_items:
		if equipped_items[slot] == item_id:
			equipped_items[slot] = null
			print("[Inventory] Unequipped: ", item_data.get(item_id, {}).get("name", item_id))
			item_unequipped.emit(item_id, slot)
			inventory_changed.emit()
			return true
	return false

func use_item(item_id: String) -> bool:
	if not item_data.has(item_id):
		return false
	
	var item = item_data[item_id]
	if not item.get("consumable", false):
		print("[Inventory] Item is not consumable: ", item.name)
		return false
	
	# Handle usage count
	var current_uses = item.get("uses_remaining", item.get("max_uses", 1))
	if current_uses <= 0:
		print("[Inventory] No uses remaining for: ", item.name)
		return false
	
	# Decrease uses
	item["uses_remaining"] = current_uses - 1
	print("[Inventory] Used: ", item.name, " (", item.uses_remaining, " uses remaining)")
	
	# Remove if no uses left
	if item.uses_remaining <= 0:
		remove_item(item_id)
	
	item_used.emit(item_id)
	inventory_changed.emit()
	return true

func get_all_items() -> Array:
	var all_items = []
	
	# Add equipped items
	for slot in equipped_items:
		var item_id = equipped_items[slot]
		if item_id and item_data.has(item_id):
			var item_copy = item_data[item_id].duplicate()
			item_copy["equipped"] = true
			item_copy["equipped_slot"] = slot
			all_items.append(item_copy)
	
	# Add bag items (not equipped)
	for item_id in bag_items:
		if item_data.has(item_id):
			var is_equipped = false
			for slot in equipped_items:
				if equipped_items[slot] == item_id:
					is_equipped = true
					break
			
			if not is_equipped:
				var item_copy = item_data[item_id].duplicate()
				item_copy["equipped"] = false
				all_items.append(item_copy)
	
	return all_items

func get_item_data(item_id: String) -> Dictionary:
	return item_data.get(item_id, {})

func has_item(item_id: String) -> bool:
	return bag_items.has(item_id)
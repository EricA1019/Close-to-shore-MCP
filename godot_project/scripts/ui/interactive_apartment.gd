extends TermElement
class_name InteractiveApartment

## Interactive detective apartment with WASD movement and POI system

# Apartment dimensions
const APARTMENT_WIDTH = 28
const APARTMENT_HEIGHT = 16

# Player data
var player_pos: Vector2i = Vector2i(5, 2)
var last_interaction: Dictionary = {}

# Room layout and POIs
var _apartment_cells: Dictionary = {}
var pois: Array = []
var nearby_poi = null

# UI references (will be set by main UI)
var output_panel = null
var action_panel = null

func _ready() -> void:
	super()
	_generate_apartment_layout()
	_setup_pois()
	
	# Check for POIs near starting position
	_check_nearby_pois()
	
	print("[InteractiveApartment] Ready - ", APARTMENT_WIDTH, "x", APARTMENT_HEIGHT)

func get_apartment_size() -> Vector2i:
	return Vector2i(APARTMENT_WIDTH, APARTMENT_HEIGHT)

func get_fixed_width() -> int:
	return APARTMENT_WIDTH

func get_fixed_height() -> int:
	return APARTMENT_HEIGHT

# Handle WASD input for movement
func handle_input(event) -> void:
	# Accept both string action names (for testing) and InputEvent objects
	var action = ""
	var is_pressed = true
	
	if event is String:
		# Testing convenience - convert string to action
		action = event
	elif event is InputEventAction:
		action = event.action
		is_pressed = event.pressed
	else:
		return
	
	if is_pressed:
		var direction = Vector2i.ZERO
		
		if action == "ui_up":      # W key
			direction = Vector2i(0, -1)
		elif action == "ui_down":    # S key
			direction = Vector2i(0, 1)
		elif action == "ui_left":    # A key
			direction = Vector2i(-1, 0)
		elif action == "ui_right":   # D key
			direction = Vector2i(1, 0)
		elif action == "ui_accept":  # E key - interact with nearby POI
			_interact_with_nearby_poi()
			return
		
		if direction != Vector2i.ZERO:
			if _try_move(direction):
				_check_nearby_pois()
				_update_ui_panels()
				_redraw_required = true

func _try_move(direction: Vector2i) -> bool:
	var new_pos = player_pos + direction
	print("[Debug] Trying to move from ", player_pos, " to ", new_pos)
	
	# Check bounds
	if new_pos.x < 0 or new_pos.x >= APARTMENT_WIDTH or new_pos.y < 0 or new_pos.y >= APARTMENT_HEIGHT:
		print("[Debug] Move blocked - out of bounds")
		return false
	
	# Check if position is passable
	if not _is_passable(new_pos):
		print("[Debug] Move blocked - position not passable")
		return false
	
	# Move is valid
	player_pos = new_pos
	print("[Debug] Move successful to ", player_pos)
	
	# Check for nearby POIs after movement
	_check_nearby_pois()
	
	return true

func _is_passable(pos: Vector2i) -> bool:
	var cell = _apartment_cells.get(pos)
	if not cell:
		print("[Debug] No cell at ", pos, " - allowing movement")
		return true  # Empty space is passable
	
	# Only floor tiles are passable, everything else blocks movement
	var passable = cell.character == "."
	# Debug output for testing
	print("[Debug] Cell at ", pos, " has character: '", cell.character, "' - passable: ", passable)
	return passable

func _check_nearby_pois() -> void:
	nearby_poi = null
	var closest_distance = 999.0
	
	# Check all POIs for proximity (within 1 tile) and find the closest one
	for poi in pois:
		var distance = player_pos.distance_to(poi.position)
		if distance <= 1.5 and distance < closest_distance:  # Within 1 tile (allowing diagonal)
			nearby_poi = poi
			closest_distance = distance

func _interact_with_nearby_poi() -> void:
	if nearby_poi:
		var poi_name = nearby_poi.name.to_lower()
		var action_key = poi_name + ".interact"
		
		# Check for specific interaction in last_interaction
		if last_interaction.has("action"):
			action_key = last_interaction.action
		
		# Trigger the interaction
		if output_panel:
			var description = nearby_poi.description
			
			# Add special context for items
			if poi_name == "drawer" and nearby_poi.items.size() > 0:
				description += "\n\nContains: "
				for item in nearby_poi.items:
					description += item.name + ", "
				description = description.trim_suffix(", ")
			
			output_panel.show_description(description)
		
		if action_panel:
			action_panel.set_actions(nearby_poi.actions)
		
		# Store this interaction
		last_interaction = {
			"poi": nearby_poi.name,
			"action": action_key,
			"timestamp": Time.get_unix_time_from_system()
		}

func _update_ui_panels() -> void:
	if nearby_poi:
		if output_panel:
			output_panel.show_description(nearby_poi.description)
		if action_panel:
			action_panel.set_actions(nearby_poi.actions)
	else:
		if output_panel:
			output_panel.show_description("You are in your apartment.")
		if action_panel:
			action_panel.clear_actions()

func _generate_apartment_layout() -> void:
	_apartment_cells.clear()
	
	# Define the 28x16 apartment layout
	var layout_strings = [
		"████████████████████████████",  # 0
		"█.....π.......+..........+.█",  # 1
		"█.......................+..█",  # 2  
		"█..........................█",  # 3
		"█..........................█",  # 4
		"█+...........+.......β.....█",  # 5
		"█............+.............█",  # 6
		"█..........................█",  # 7
		"█..π......+...╤.............█",  # 8
		"█.............Æ.......α....█",  # 9
		"█..........................█",  # 10
		"█..........................█",  # 11
		"█+............+......ε.....█",  # 12
		"█.............+.......δ....█",  # 13
		"█..........................█",  # 14
		"████████████████████████████"   # 15
	]
	
	# Convert strings to TermCells
	for y in range(APARTMENT_HEIGHT):
		for x in range(APARTMENT_WIDTH):
			var character = layout_strings[y][x]
			
			# Debug specific position
			if x == 19 and y == 8:
				print("[Debug] Setting position (19,8) to character: '", character, "'")
			
			var color = Color.WHITE
			
			# Color coding for different elements
			if character == "█":
				color = Color.GRAY
			elif character == ".":
				color = Color.YELLOW
			elif character == "+":
				color = Color.BROWN
			else:
				color = Color.CYAN  # Furniture and POIs
			
			_apartment_cells[Vector2i(x, y)] = TermCell.new(character, color, Color.BLACK)
	
	_redraw_required = true

func _setup_pois() -> void:
	pois.clear()
	
	# Desk POI at position (14, 8) - character ╤
	var desk_poi = ApartmentPOI.new()
	desk_poi.name = "Desk"
	desk_poi.position = Vector2i(14, 8)
	desk_poi.description = "A cluttered wooden desk with scattered documents and a jammed drawer."
	desk_poi.actions = ["Examine papers", "Open drawer"]
	pois.append(desk_poi)
	
	# Desk Drawer POI at position (14, 9) - character Æ  
	var drawer_poi = ApartmentPOI.new()
	drawer_poi.name = "Desk Drawer"
	drawer_poi.position = Vector2i(14, 9)
	drawer_poi.description = "The desk's bottom drawer. It's slightly ajar."
	drawer_poi.actions = ["Search drawer", "Close drawer"]
	
	# Add detective items to drawer
	var pistol = ApartmentItem.new()
	pistol.name = ".38 Service Pistol"
	pistol.description = "An old Model 10 service revolver in .38 Special. Well-maintained despite its age."
	pistol.item_type = "weapon"
	pistol.stats = {"damage": 15, "accuracy": 80, "range": "medium"}
	pistol.effects = {"intimidation": 2}
	pistol.equippable = true
	drawer_poi.items.append(pistol)
	
	var whiskey = ApartmentItem.new()
	whiskey.name = "Bourbon Whiskey"
	whiskey.description = "A mostly empty bottle of Kentucky bourbon. The good stuff."
	whiskey.item_type = "consumable"
	whiskey.stats = {"healing": 5}
	whiskey.effects = {"confidence": 1, "perception": -1}
	whiskey.equippable = false
	drawer_poi.items.append(whiskey)
	
	var jacket = ApartmentItem.new()
	jacket.name = "Brown Leather Jacket"
	jacket.description = "A worn brown leather jacket. It's seen better days but still looks sharp."
	jacket.item_type = "armor"
	jacket.stats = {"protection": 3, "style": 2}
	jacket.effects = {"charisma": 1}
	jacket.equippable = true
	drawer_poi.items.append(jacket)
	
	pois.append(drawer_poi)
	
	# Bed POI at position (25, 9) - character α
	var bed_poi = ApartmentPOI.new()
	bed_poi.name = "Bed"
	bed_poi.position = Vector2i(25, 9)
	bed_poi.description = "An unmade bed with wrinkled sheets. You didn't sleep well last night."
	bed_poi.actions = ["Sleep", "Search under bed"]
	pois.append(bed_poi)
	
	# Kitchen POI at position (22, 12) - character ε
	var kitchen_poi = ApartmentPOI.new()
	kitchen_poi.name = "Kitchen"
	kitchen_poi.position = Vector2i(22, 12)
	kitchen_poi.description = "A small kitchenette with a few dirty dishes in the sink."
	kitchen_poi.actions = ["Check cabinets", "Wash dishes"]
	pois.append(kitchen_poi)
	
	# Fridge POI at position (22, 13) - character δ
	var fridge_poi = ApartmentPOI.new()
	fridge_poi.name = "Fridge"
	fridge_poi.position = Vector2i(22, 13)
	fridge_poi.description = "An old refrigerator humming quietly. A few takeout containers visible inside."
	fridge_poi.actions = ["Open fridge", "Check freezer"]
	pois.append(fridge_poi)
	
	# Bathroom POI at position (21, 5) - character β
	var bathroom_poi = ApartmentPOI.new()
	bathroom_poi.name = "Bathroom"
	bathroom_poi.position = Vector2i(21, 5)
	bathroom_poi.description = "A cramped bathroom with a medicine cabinet mirror that needs cleaning."
	bathroom_poi.actions = ["Use bathroom", "Check medicine cabinet"]
	pois.append(bathroom_poi)
	
	# Closet POI at position (6, 1) - character π
	var closet_poi = ApartmentPOI.new()
	closet_poi.name = "Closet"
	closet_poi.position = Vector2i(6, 1)
	closet_poi.description = "A walk-in closet with some clothes hanging and boxes on the floor."
	closet_poi.actions = ["Search clothes", "Check boxes"]
	pois.append(closet_poi)

# TermElement rendering methods
func _blit_self_under(buffer) -> void:
	# Place apartment cells
	for pos in _apartment_cells:
		var world_pos = _rect.position + pos
		buffer.put_cell(_apartment_cells[pos], world_pos)
	
	# Place player character (overwrites any existing character at that position)
	var player_world_pos = _rect.position + player_pos
	var player_cell = TermCell.new("@", Color.YELLOW, Color.BLACK)
	buffer.put_cell(player_cell, player_world_pos)

func _blit_self_under_canvas(buffer) -> void:
	const CanvasCell = preload("res://addons/ascii_grid/ascii_canvas_cell.gd")
	
	# Place apartment cells
	for pos in _apartment_cells:
		var world_pos = _rect.position + pos
		var term_cell: TermCell = _apartment_cells[pos]
		var canvas_cell := CanvasCell.new(term_cell.character, term_cell.fg_color, term_cell.bg_color)
		buffer.set_cell(world_pos, canvas_cell)
	
	# Place player character (overwrites any existing character at that position)
	var player_world_pos = _rect.position + player_pos
	var player_canvas_cell := CanvasCell.new("@", Color.YELLOW, Color.BLACK)
	buffer.set_cell(player_world_pos, player_canvas_cell)

# Testing methods
func get_player_position() -> Vector2i:
	return player_pos

func set_player_position(pos: Vector2i) -> void:
	player_pos = pos
	_redraw_required = true
	# Check for nearby POIs after position change
	_check_nearby_pois()

func get_cell(pos: Vector2i) -> Dictionary:
	# Check if player is at this position
	if pos == player_pos:
		return {"character": "@", "position": pos}
	
	# Return apartment cell info
	var cell = _apartment_cells.get(pos)
	if cell:
		return {"character": cell.character, "position": pos}
	else:
		return {"character": " ", "position": pos}

func get_poi_by_name(poi_name: String) -> ApartmentPOI:
	for poi in pois:
		if poi.name == poi_name:
			return poi
	return null

func get_poi_at(pos: Vector2i) -> ApartmentPOI:
	for poi in pois:
		if poi.position == pos:
			return poi
	return null

func get_nearby_poi() -> ApartmentPOI:
	return nearby_poi

func get_last_interaction() -> Dictionary:
	return last_interaction

func update_output_panel(text: String) -> void:
	if output_panel and output_panel.has_method("show_description"):
		output_panel.show_description(text)

func update_action_panel(actions: Array) -> void:
	if action_panel and action_panel.has_method("set_actions"):
		action_panel.set_actions(actions)

func get_apartment_grid() -> Dictionary:
	var grid = {}
	for pos in _apartment_cells:
		var cell = _apartment_cells[pos]
		grid[pos] = {"character": cell.character, "position": pos}
	return grid

func get_canvas_cells() -> Array:
	var cells = []
	
	# Add all apartment layout cells
	for pos in _apartment_cells:
		var cell = _apartment_cells[pos]
		cells.append({
			"position": pos,
			"character": cell.character,
			"color": cell.fg_color
		})
	
	# Add player character (overwrites any existing character at that position)
	cells.append({
		"position": player_pos,
		"character": "@",
		"color": Color.YELLOW
	})
	
	return cells

# Helper classes for POI system
class ApartmentPOI:
	var name: String
	var position: Vector2i
	var description: String
	var actions: Array = []
	var items: Array = []
	
	func _init():
		pass
	
	func get_items() -> Array:
		return items

class ApartmentItem:
	var name: String
	var description: String
	var item_type: String  # "weapon", "armor", "consumable", "misc"
	var stats: Dictionary = {}
	var effects: Dictionary = {}
	var equippable: bool = false
	
	func _init():
		pass

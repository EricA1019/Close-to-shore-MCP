extends Node
class_name AdaptiveSceneManager

## GDScript bridge for the Rust-based AdaptiveSceneRenderer
## Provides stable, aspect-ratio-independent scene rendering

signal scene_rendered(scene_id: String, layout: Dictionary)
signal poi_positions_updated(positions: Dictionary)

var _renderer: AdaptiveSceneRenderer
var _current_scene_id: String = ""
var _last_layout: Dictionary = {}

func _ready() -> void:
	# Initialize the Rust renderer
	_renderer = AdaptiveSceneRenderer.new()
	print("[AdaptiveSceneManager] Initialized with Rust renderer")

## Set the target canvas size and update aspect context
func set_canvas_size(width: int, height: int) -> void:
	if _renderer:
		_renderer.set_aspect_context(width, height)
		print("[AdaptiveSceneManager] Canvas size updated: %dx%d" % [width, height])
		
		# Re-render current scene if any
		if _current_scene_id != "":
			render_scene(_current_scene_id)

## Load and register a scene definition from JSON file
func load_scene_definition(scene_path: String) -> bool:
	if not FileAccess.file_exists(scene_path):
		push_error("Scene definition file not found: " + scene_path)
		return false
	
	var file = FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		push_error("Failed to open scene definition: " + scene_path)
		return false
	
	var json_content = file.get_as_text()
	file.close()
	
	var success = _renderer.register_scene(json_content)
	if success:
		print("[AdaptiveSceneManager] Loaded scene definition: ", scene_path)
	else:
		push_error("Failed to register scene from: " + scene_path)
	
	return success

## Render a scene and return the adaptive layout
func render_scene(scene_id: String) -> Dictionary:
	if not _renderer:
		push_error("Renderer not initialized")
		return {}
	
	var layout_variant = _renderer.render_scene(scene_id)
	if layout_variant == null:
		push_error("Failed to render scene: " + scene_id)
		return {}
	
	var layout = layout_variant as Dictionary
	_current_scene_id = scene_id
	_last_layout = layout
	
	# Extract POI positions for easy access
	var poi_positions = layout.get("poi_positions", {})
	
	scene_rendered.emit(scene_id, layout)
	poi_positions_updated.emit(poi_positions)
	
	print("[AdaptiveSceneManager] Rendered scene '%s': %dx%d with %d POIs" % [
		scene_id, layout.get("width", 0), layout.get("height", 0), poi_positions.size()
	])
	
	return layout

## Get the position of a specific POI in the last rendered scene
func get_poi_position(poi_id: String) -> Vector2i:
	var poi_positions = _last_layout.get("poi_positions", {})
	return poi_positions.get(poi_id, Vector2i(-1, -1))

## Get all POI positions from the last rendered scene
func get_all_poi_positions() -> Dictionary:
	return _last_layout.get("poi_positions", {})

## Convert the Rust-generated layout to the format expected by InteractiveApartment
func layout_to_apartment_format(layout: Dictionary) -> Dictionary:
	var apartment_format = {
		"width": layout.get("width", 30),
		"height": layout.get("height", 16),
		"rows": layout.get("rows", [])
	}
	
	return apartment_format

## Example of how to use adaptive scene rendering with different aspect ratios
func demonstrate_adaptive_rendering() -> void:
	# Load the apartment scene
	var scene_loaded = load_scene_definition("res://data/indexes/scenes/apartment_adaptive.json")
	if not scene_loaded:
		return
	
	print("\n=== Adaptive Scene Rendering Demo ===")
	
	# Test different aspect ratios
	var test_sizes = [
		[40, 20],   # Compact mobile
		[80, 25],   # Standard desktop
		[120, 30],  # Ultrawide
		[60, 40],   # Tall/portrait
	]
	
	for size in test_sizes:
		var width = size[0]
		var height = size[1]
		var aspect_ratio = float(width) / float(height)
		
		print("\n--- Testing %dx%d (aspect: %.2f) ---" % [width, height, aspect_ratio])
		
		set_canvas_size(width, height)
		var layout = render_scene("apartment")
		
		if layout.has("poi_positions"):
			var pois = layout["poi_positions"]
			print("POI positions:")
			for poi_id in pois:
				var pos = pois[poi_id]
				print("  %s: (%d, %d)" % [poi_id, pos.x, pos.y])

## Utility function to compare layouts between fixed and adaptive systems
func compare_with_fixed_layout(fixed_layout_path: String) -> void:
	# Load fixed layout
	if not FileAccess.file_exists(fixed_layout_path):
		print("Fixed layout not found: ", fixed_layout_path)
		return
	
	var file = FileAccess.open(fixed_layout_path, FileAccess.READ)
	var fixed_json = JSON.parse_string(file.get_as_text())
	file.close()
	
	print("\n=== Comparison: Fixed vs Adaptive ===")
	print("Fixed layout: %dx%d" % [fixed_json.get("width", 0), fixed_json.get("height", 0)])
	print("Adaptive layout: %dx%d" % [_last_layout.get("width", 0), _last_layout.get("height", 0)])
	
	# Compare POI positions if available
	if fixed_json.has("poi_positions") and _last_layout.has("poi_positions"):
		var fixed_pois = fixed_json["poi_positions"]
		var adaptive_pois = _last_layout["poi_positions"]
		
		print("POI position changes:")
		for poi_id in adaptive_pois:
			if fixed_pois.has(poi_id):
				var fixed_pos = fixed_pois[poi_id]
				var adaptive_pos = adaptive_pois[poi_id]
				var delta = Vector2i(adaptive_pos.x - fixed_pos.x, adaptive_pos.y - fixed_pos.y)
				print("  %s: (%d,%d) -> (%d,%d) [Δ%+d,%+d]" % [
					poi_id, fixed_pos.x, fixed_pos.y, 
					adaptive_pos.x, adaptive_pos.y, delta.x, delta.y
				])
			else:
				print("  %s: NEW at (%d,%d)" % [poi_id, adaptive_pois[poi_id].x, adaptive_pois[poi_id].y])

## Integration point for existing InteractiveApartment
func get_interactive_apartment_layout() -> Dictionary:
	if _last_layout.is_empty():
		# Fallback to rendering with default size
		set_canvas_size(28, 16)
		render_scene("apartment")
	
	return layout_to_apartment_format(_last_layout)

## Advanced: Dynamic scene modification
func modify_scene_constraints(zone_id: String, new_constraints: Dictionary) -> void:
	# This would allow runtime modification of scene constraints
	# Implementation would involve updating the Rust scene definition
	print("[AdaptiveSceneManager] Scene modification not yet implemented")
	# Future: _renderer.modify_zone_constraints(zone_id, new_constraints)

## Debug: Print detailed layout information
func debug_print_layout() -> void:
	if _last_layout.is_empty():
		print("No layout rendered yet")
		return
	
	print("\n=== Layout Debug Info ===")
	print("Size: %dx%d" % [_last_layout.get("width", 0), _last_layout.get("height", 0)])
	
	var rows = _last_layout.get("rows", [])
	print("ASCII Layout:")
	for i in range(rows.size()):
		print("%2d: %s" % [i, rows[i]])
	
	var poi_positions = _last_layout.get("poi_positions", {})
	print("\nPOI Positions:")
	for poi_id in poi_positions:
		var pos = poi_positions[poi_id]
		print("  %s: (%d, %d)" % [poi_id, pos.x, pos.y])

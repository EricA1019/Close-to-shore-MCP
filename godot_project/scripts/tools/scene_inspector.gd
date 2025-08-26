class_name SceneInspector
extends RefCounted

## Scene Tree Exporter - Gives AI agents "eyes" to see the game state
## Usage: SceneInspector.export_scene_tree() or via HTTP endpoint

static func export_scene_tree(root_node: Node = null) -> Dictionary:
	"""Export the entire scene tree to a structured dictionary"""
	if not root_node:
		root_node = Engine.get_main_loop().current_scene
	
	return {
		"timestamp": Time.get_unix_time_from_system(),
		"scene_name": root_node.scene_file_path if root_node.scene_file_path else "Unknown",
		"tree": _export_node_recursive(root_node)
	}

static func export_scene_tree_json(root_node: Node = null) -> String:
	"""Export scene tree as JSON string"""
	return JSON.stringify(export_scene_tree(root_node))

static func save_scene_snapshot(file_path: String, root_node: Node = null) -> void:
	"""Save scene tree snapshot to file"""
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(export_scene_tree_json(root_node))
		file.close()
		print("[SceneInspector] Snapshot saved to: ", file_path)

static func _export_node_recursive(node: Node) -> Dictionary:
	"""Recursively export a node and all its children"""
	var node_data = {
		"name": node.name,
		"type": node.get_class(),
		"script": node.get_script().resource_path if node.get_script() else null,
		"visible": node.visible if node.has_method("set_visible") else null,
		"position": _safe_get_property(node, "position"),
		"size": _safe_get_property(node, "size"),
		"scale": _safe_get_property(node, "scale"),
		"modulate": _safe_get_property(node, "modulate"),
		"text": _safe_get_property(node, "text"),
		"children": []
	}
	
	# Add script variables if script exists
	if node.get_script():
		node_data["script_variables"] = _get_script_variables(node)
	
	# Add children recursively
	for child in node.get_children():
		node_data.children.append(_export_node_recursive(child))
	
	return node_data

static func _safe_get_property(node: Node, property: String) -> Variant:
	"""Safely get a property from a node, returns null if not found"""
	if node.has_method("get_" + property) or property in node:
		return node.get(property)
	return null

static func _get_script_variables(node: Node) -> Dictionary:
	"""Extract exported variables from a node's script"""
	var variables = {}
	var script = node.get_script()
	if not script:
		return variables
	
	# Get all properties from the script
	for prop in script.get_script_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			variables[prop.name] = node.get(prop.name)
	
	return variables

## Global State Inspector
static func export_global_state() -> Dictionary:
	"""Export state of all autoloaded singletons"""
	var global_state = {
		"timestamp": Time.get_unix_time_from_system(),
		"autoloads": {}
	}
	
	# Get all autoloaded nodes
	var tree = Engine.get_main_loop()
	if tree.has_method("get_nodes_in_group"):
		# This is a simplified approach - in practice you'd list known autoloads
		var known_autoloads = ["PlayerState", "LogBus", "GameClock", "ContentDB"]
		for autoload_name in known_autoloads:
			if tree.has_node("/root/" + autoload_name):
				var autoload_node = tree.get_node("/root/" + autoload_name)
				global_state.autoloads[autoload_name] = _get_script_variables(autoload_node)
	
	return global_state

## Node Finder - Search the scene tree
static func find_nodes_by_name(name_pattern: String, root_node: Node = null, case_sensitive: bool = false) -> Array[Node]:
	"""Find all nodes matching a name pattern"""
	if not root_node:
		root_node = Engine.get_main_loop().current_scene
	
	var matches: Array[Node] = []
	_find_nodes_recursive(root_node, name_pattern, matches, case_sensitive)
	return matches

static func _find_nodes_recursive(node: Node, pattern: String, matches: Array[Node], case_sensitive: bool) -> void:
	"""Recursively search for nodes by name"""
	var node_name: String
	var search_pattern: String
	
	if case_sensitive:
		node_name = node.name
		search_pattern = pattern
	else:
		node_name = node.name.to_lower()
		search_pattern = pattern.to_lower()
	
	if node_name.contains(search_pattern):
		matches.append(node)
	
	for child in node.get_children():
		_find_nodes_recursive(child, pattern, matches, case_sensitive)

static func find_nodes_by_type(type_name: String, root_node: Node = null) -> Array[Node]:
	"""Find all nodes of a specific type"""
	if not root_node:
		root_node = Engine.get_main_loop().current_scene
	
	var matches: Array[Node] = []
	_find_nodes_by_type_recursive(root_node, type_name, matches)
	return matches

static func _find_nodes_by_type_recursive(node: Node, type_name: String, matches: Array[Node]) -> void:
	"""Recursively search for nodes by type"""
	if node.get_class() == type_name or node.is_class(type_name):
		matches.append(node)
	
	for child in node.get_children():
		_find_nodes_by_type_recursive(child, type_name, matches)

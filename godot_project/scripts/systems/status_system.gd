extends Node

## StatusSystem: Manages entity statuses (buffs/debuffs)
## Signals: status_changed(entity_id)

signal status_changed(entity_id: String)

# entity_id -> Array[String] of status IDs
var _entity_statuses: Dictionary = {}

func _ready():
	print("StatusSystem initialized")

## Add a status to an entity
func add_status(entity_id: String, status_id: String):
	if not _entity_statuses.has(entity_id):
		_entity_statuses[entity_id] = []
	var statuses: Array = _entity_statuses[entity_id]
	if not statuses.has(status_id):
		statuses.append(status_id)
		status_changed.emit(entity_id)

## Remove a status from an entity
func remove_status(entity_id: String, status_id: String):
	if not _entity_statuses.has(entity_id):
		return
	var statuses: Array = _entity_statuses[entity_id]
	var idx = statuses.find(status_id)
	if idx >= 0:
		statuses.remove_at(idx)
		status_changed.emit(entity_id)

## Check if an entity has a specific status
func has_status(entity_id: String, status_id: String) -> bool:
	if not _entity_statuses.has(entity_id):
		return false
	var statuses: Array = _entity_statuses[entity_id]
	return statuses.has(status_id)

## Get all status IDs for an entity
func get_statuses(entity_id: String) -> Array[String]:
	if not _entity_statuses.has(entity_id):
		return []
	var statuses: Array = _entity_statuses[entity_id]
	var result: Array[String] = []
	for s in statuses:
		result.append(s)
	return result

## Get effective stat modifications from all active statuses
## Returns Dictionary with stat names as keys and total modifier as values
func get_mods(entity_id: String) -> Dictionary:
	var mods = {}
	
	# Apply all status effects for this entity
	if _entity_statuses.has(entity_id):
		for status_id in _entity_statuses[entity_id]:
			# TODO: Load status resource and apply mods
			# For now, use placeholder values based on status ID
			match status_id:
				"S-001": # Hungover
					mods["accuracy"] = mods.get("accuracy", 0) - 2
					mods["dexterity"] = mods.get("dexterity", 0) - 1
				"S-002": # Steady Nerves
					mods["accuracy"] = mods.get("accuracy", 0) + 1
	
	return mods

## Clear all statuses for an entity (for testing)
func clear_statuses(entity_id: String):
	if _entity_statuses.has(entity_id):
		_entity_statuses[entity_id] = []
		status_changed.emit(entity_id)

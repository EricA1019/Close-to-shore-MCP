class_name EntityResource
extends Resource

## Entity definition with stats, abilities, and equipment

@export var id: String
@export var name: String
@export var char: String = "@"  # ASCII character for display
@export var stat_block: StatBlockResource
@export var ability_ids: Array[String] = []  # References to AbilityResource IDs
@export var status_ids: Array[String] = []   # Starting status effect IDs
@export var equipment_slots: Dictionary = {} # slot_name -> item_id
@export var affixes: Array[String] = []      # Modifier tags like "veteran", "novice"

## Derived stats with equipment and status modifiers
func get_effective_stats() -> Dictionary:
	var base_stats = {
		"strength": stat_block.strength,
		"dexterity": stat_block.dexterity, 
		"constitution": stat_block.constitution,
		"intelligence": stat_block.intelligence,
		"wisdom": stat_block.wisdom,
		"charisma": stat_block.charisma,
		"accuracy": stat_block.get_accuracy(),
		"health_max": stat_block.get_health_max(),
		"defense": stat_block.get_defense()
	}
	
	# TODO: Apply equipment modifiers
	# TODO: Apply status effect modifiers via StatusSystem
	
	return base_stats

## Helper methods
func has_ability(ability_id: String) -> bool:
	return ability_ids.has(ability_id)

func has_affix(affix: String) -> bool:
	return affixes.has(affix)

## Validation
func _validate_property(property: Dictionary) -> void:
	# property = { "name": StringName, ... }
	var prop_name := String(property.get("name", ""))
	if prop_name == "id" and id != null and id != "" and not String(id).begins_with("E-"):
		push_warning("EntityResource ID should start with 'E-': " + String(id))

class_name AbilityResource
extends Resource

## Ability definition with targeting and rules

@export var id: String
@export var name: String
@export var target: String  # "self", "other", "any"
@export var description: String

## Rules for ability usage
@export var requires_status: String = ""  # Required status to use (e.g., "S-001")
@export var removes_status: String = ""   # Status to remove when used (e.g., "S-001") 
@export var adds_status: String = ""      # Status to add when used (e.g., "S-002")
@export var cooldown_turns: int = 0       # Turns before can use again

## Validation
func _validate_property(property: Dictionary) -> void:
	var prop_name := String(property.get("name", ""))
	if prop_name == "id" and id != null and id != "" and not String(id).begins_with("A-"):
		push_warning("AbilityResource ID should start with 'A-': " + String(id))

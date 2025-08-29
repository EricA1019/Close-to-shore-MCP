class_name StatusResource
extends Resource

## Status effect definition with stat modifications

@export var id: String
@export var name: String
@export var description: String
@export var mods: Dictionary = {}  # stat_name -> modifier value
@export var tags: Array[String] = []  # "debuff", "buff", "mental", etc.
@export var duration_turns: int = -1  # -1 = permanent until removed

## Helper methods
func is_buff() -> bool:
	return tags.has("buff")

func is_debuff() -> bool:
	return tags.has("debuff")

func get_mod(stat_name: String) -> int:
	return mods.get(stat_name, 0)

## Validation
func _validate_property(property: Dictionary) -> void:
	var prop_name := String(property.get("name", ""))
	if prop_name == "id" and id != null and id != "" and not String(id).begins_with("S-"):
		push_warning("StatusResource ID should start with 'S-': " + String(id))

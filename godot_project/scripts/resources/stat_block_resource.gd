class_name StatBlockResource
extends Resource

## D&D-ish stat block with derived getters

@export var strength: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10
@export var intelligence: int = 10
@export var wisdom: int = 10
@export var charisma: int = 10

## Derived getters (modifiers follow D&D convention: (stat - 10) / 2)
func get_str_mod() -> int:
	return (strength - 10) / 2

func get_dex_mod() -> int:
	return (dexterity - 10) / 2

func get_con_mod() -> int:
	return (constitution - 10) / 2

func get_int_mod() -> int:
	return (intelligence - 10) / 2

func get_wis_mod() -> int:
	return (wisdom - 10) / 2

func get_cha_mod() -> int:
	return (charisma - 10) / 2

## Derived stats for game mechanics
func get_accuracy() -> int:
	return 95 + get_dex_mod() * 5  # Base 95% + dex modifier

func get_health_max() -> int:
	return 10 + get_con_mod() * 2  # Base 10 HP + con modifier

func get_defense() -> int:
	return 10 + get_dex_mod()  # Base AC 10 + dex modifier

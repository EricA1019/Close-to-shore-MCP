extends GutTest

func _get_entity(_id: String) -> EntityResource:
	return load("res://data/entities/e_001_detective.tres")

func _get_status(id: String) -> StatusResource:
	var map := {
		"S-001": "res://data/statuses/s_001_hungover.tres",
		"S-002": "res://data/statuses/s_002_steady_nerves.tres",
	}
	return load(map.get(id, "res://data/statuses/s_001_hungover.tres"))

func _get_ability(id: String) -> AbilityResource:
	var map := {
		"A-001": "res://data/abilities/a_001_cleanse.tres",
	}
	return load(map.get(id, "res://data/abilities/a_001_cleanse.tres"))

func test_detective_entity_loads():
	# Test that Detective entity loads correctly
	var detective: EntityResource = _get_entity("E-001")
	assert_not_null(detective, "Detective entity should load")
	assert_eq(detective.id, "E-001", "Detective ID should be E-001")
	assert_eq(detective.name, "Detective", "Detective name should be 'Detective'")
	assert_eq(detective.char, "@", "Detective character should be '@'")
	assert_not_null(detective.stat_block, "Detective should have stat block")

func test_detective_stats_present():
	# Test that Detective has proper stats
	var detective: EntityResource = _get_entity("E-001")
	assert_not_null(detective)
	
	var stats: StatBlockResource = detective.stat_block
	assert_not_null(stats)
	assert_gt(stats.strength, 0, "Detective should have strength > 0")
	assert_gt(stats.dexterity, 0, "Detective should have dexterity > 0") 
	assert_gt(stats.constitution, 0, "Detective should have constitution > 0")
	assert_gt(stats.intelligence, 0, "Detective should have intelligence > 0")
	assert_gt(stats.wisdom, 0, "Detective should have wisdom > 0")
	assert_gt(stats.charisma, 0, "Detective should have charisma > 0")
	
	# Test derived stats
	assert_gt(stats.get_accuracy(), 0, "Detective should have accuracy > 0")
	assert_gt(stats.get_health_max(), 0, "Detective should have health_max > 0")

func test_detective_no_affixes():
	# Test that Detective has no affixes (as specified)
	var detective: EntityResource = _get_entity("E-001")
	assert_not_null(detective)
	assert_eq(detective.affixes.size(), 0, "Detective should have no affixes")

func test_detective_abilities_load():
	# Test that Detective's abilities can be resolved
	var detective: EntityResource = _get_entity("E-001")
	assert_not_null(detective)
	
	# Simulate resolution
	var abilities: Array = []
	for ability_id in detective.ability_ids:
		var ability: AbilityResource = _get_ability(ability_id)
		if ability:
			abilities.append(ability)
	assert_gt(abilities.size(), 0, "Detective should have at least one ability")
	
	# Should have Cleanse ability
	var has_cleanse = false
	for ability in abilities:
		if ability.id == "A-001":
			has_cleanse = true
			assert_eq(ability.name, "Cleanse", "Cleanse ability should have correct name")
			break
	assert_true(has_cleanse, "Detective should have Cleanse ability")

func test_detective_statuses_load():
	# Test that Detective's starting statuses can be resolved
	var detective: EntityResource = _get_entity("E-001")
	assert_not_null(detective)
	
	var statuses: Array = []
	for status_id in detective.status_ids:
		var status: StatusResource = _get_status(status_id)
		if status:
			statuses.append(status)
	assert_gt(statuses.size(), 0, "Detective should have at least one starting status")
	
	# Should have Hungover status
	var has_hungover = false
	for status in statuses:
		if status.id == "S-001":
			has_hungover = true
			assert_eq(status.name, "Hungover", "Hungover status should have correct name")
			assert_true(status.is_debuff(), "Hungover should be a debuff")
			break
	assert_true(has_hungover, "Detective should start with Hungover status")

func test_ability_resource_validation():
	# Test that abilities load with correct properties
	var cleanse: AbilityResource = _get_ability("A-001")
	assert_not_null(cleanse)
	assert_eq(cleanse.id, "A-001")
	assert_eq(cleanse.name, "Cleanse")
	assert_eq(cleanse.target, "self")
	assert_eq(cleanse.removes_status, "S-001")

func test_status_resource_validation():
	# Test that statuses load with correct properties
	var hungover: StatusResource = _get_status("S-001")
	assert_not_null(hungover)
	assert_eq(hungover.id, "S-001")
	assert_eq(hungover.name, "Hungover")
	assert_true(hungover.is_debuff())
	assert_eq(hungover.get_mod("accuracy"), -10)
	assert_eq(hungover.get_mod("dexterity"), -2)
	
	var steady_nerves: StatusResource = _get_status("S-002")
	assert_not_null(steady_nerves)
	assert_eq(steady_nerves.id, "S-002")
	assert_eq(steady_nerves.name, "Steady Nerves")
	assert_true(steady_nerves.is_buff())
	assert_eq(steady_nerves.get_mod("accuracy"), 10)

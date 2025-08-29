extends GutTest

## Ensures EntityLoader resolves entities via ContentDB with expected data

func _ensure_db_loaded() -> void:
    # If ContentDB isn't loaded yet (e.g., in headless tests), load the default DB.
    if not ContentDB.database:
        ContentDB.load_database(ContentDB.DEFAULT_DB_PATH)

func test_entity_loader_gets_detective() -> void:
    _ensure_db_loaded()
    var e: EntityResource = EntityLoader.get_entity("E-001")
    assert_not_null(e, "EntityLoader should return E-001 Detective")
    assert_eq(e.id, "E-001")
    assert_eq(e.name, "Detective")
    assert_eq(e.char, "@")
    assert_not_null(e.stat_block, "Detective should have a stat block")
    # Basic stat sanity
    assert_gt(e.stat_block.strength, 0)
    assert_gt(e.stat_block.dexterity, 0)
    assert_gt(e.stat_block.constitution, 0)
    assert_gt(e.stat_block.intelligence, 0)
    assert_gt(e.stat_block.wisdom, 0)
    assert_gt(e.stat_block.charisma, 0)
    # Derived
    assert_gt(e.stat_block.get_accuracy(), 0)
    assert_gt(e.stat_block.get_health_max(), 0)
    # Affixes: none for base Detective
    assert_eq(e.affixes.size(), 0)

func test_entity_loader_resolves_refs() -> void:
    _ensure_db_loaded()
    var e: EntityResource = EntityLoader.get_entity("E-001")
    assert_not_null(e)
    # Ability IDs present and resolvable
    assert_true(e.ability_ids.size() >= 1)
    var abilities := EntityLoader.get_entity_abilities(e)
    assert_true(abilities.size() >= 1)
    var has_cleanse := false
    for a in abilities:
        if a is AbilityResource and a.id == "A-001":
            has_cleanse = true
            assert_eq(a.name, "Cleanse")
            break
    assert_true(has_cleanse, "Detective should have Cleanse (A-001)")
    # Status IDs present and resolvable
    assert_true(e.status_ids.size() >= 1)
    var statuses := EntityLoader.get_entity_statuses(e)
    assert_true(statuses.size() >= 1)
    var has_hungover := false
    for s in statuses:
        if s is StatusResource and s.id == "S-001":
            has_hungover = true
            assert_true(s.is_debuff())
            break
    assert_true(has_hungover, "Detective should start Hungover (S-001)")

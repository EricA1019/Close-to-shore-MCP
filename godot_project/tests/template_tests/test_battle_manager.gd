# Test: Battle Manager
extends "res://addons/gut/test.gd"

func test_battle_initialization():
    var battle = BattleManager.new()
    assert_not_null(battle)
    assert_true(battle.has_method("start_battle"))

func test_battle_flow():
    var battle = BattleManager.new()
    battle.start_battle()
    assert_true(battle.in_progress)

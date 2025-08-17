# Test: Turn Order System
extends "res://addons/gut/test.gd"

func test_turn_order_initialization():
    var manager = TurnOrderManager.new()
    assert_not_null(manager)
    assert_true(manager.has_method("next_turn"))

func test_next_turn():
    var manager = TurnOrderManager.new()
    manager.add_entity(Entity.new())
    manager.add_entity(Entity.new())
    var turn = manager.next_turn()
    assert_not_null(turn)

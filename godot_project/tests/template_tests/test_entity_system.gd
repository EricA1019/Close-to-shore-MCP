# Test: Entity System
extends "res://addons/gut/test.gd"

func test_entity_creation():
    var entity = Entity.new()
    assert_not_null(entity)
    assert_true(entity.has_method("add_component"))

func test_component_addition():
    var entity = Entity.new()
    var comp = Component.new()
    entity.add_component(comp)
    assert_true(comp in entity.components)

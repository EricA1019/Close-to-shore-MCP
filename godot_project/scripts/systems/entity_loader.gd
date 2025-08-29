class_name EntityLoader
extends RefCounted

## Loads entities from Resource Database by ID with resolved references

## Get an entity by ID with all references resolved
static func get_entity(entity_id: String) -> EntityResource:
	# Use ContentDB to find the entity
	var entity_resource = ContentDB.fetch("entities", entity_id)
	if not entity_resource:
		push_error("EntityLoader: Entity not found: " + entity_id)
		return null
	
	if not entity_resource is EntityResource:
		push_error("EntityLoader: Resource is not EntityResource: " + entity_id)
		return null
	
	return entity_resource

## Get an ability by ID 
static func get_ability(ability_id: String) -> AbilityResource:
	var ability_resource = ContentDB.fetch("abilities", ability_id)
	if not ability_resource:
		push_error("EntityLoader: Ability not found: " + ability_id)
		return null
	
	if not ability_resource is AbilityResource:
		push_error("EntityLoader: Resource is not AbilityResource: " + ability_id)
		return null
	
	return ability_resource

## Get a status by ID
static func get_status(status_id: String) -> StatusResource:
	var status_resource = ContentDB.fetch("statuses", status_id)
	if not status_resource:
		push_error("EntityLoader: Status not found: " + status_id)
		return null
	
	if not status_resource is StatusResource:
		push_error("EntityLoader: Resource is not StatusResource: " + status_id)
		return null
	
	return status_resource

## Get all abilities for an entity
static func get_entity_abilities(entity: EntityResource) -> Array[AbilityResource]:
	var abilities: Array[AbilityResource] = []
	for ability_id in entity.ability_ids:
		var ability = get_ability(ability_id)
		if ability:
			abilities.append(ability)
	return abilities

## Get all statuses for an entity
static func get_entity_statuses(entity: EntityResource) -> Array[StatusResource]:
	var statuses: Array[StatusResource] = []
	for status_id in entity.status_ids:
		var status = get_status(status_id)
		if status:
			statuses.append(status)
	return statuses

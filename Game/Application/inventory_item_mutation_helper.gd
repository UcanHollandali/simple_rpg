# Layer: Application
extends RefCounted
class_name InventoryItemMutationHelper

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")


static func repair_active_weapon(inventory_state: Variant) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()

	var weapon_result: Dictionary = _load_weapon_definition_with_max_durability(
		String(inventory_state.weapon_instance.get("definition_id", ""))
	)
	if not bool(weapon_result.get("ok", false)):
		return weapon_result

	var definition_id: String = String(weapon_result.get("definition_id", ""))
	var max_durability: int = int(weapon_result.get("max_durability", 0))
	inventory_state.weapon_instance["current_durability"] = max_durability
	return {
		"ok": true,
		"definition_id": definition_id,
		"current_durability": max_durability,
	}


static func upgrade_weapon_slot(inventory_state: Variant, slot_id: int) -> Dictionary:
	return _upgrade_carried_slot(
		inventory_state,
		slot_id,
		InventoryStateScript.INVENTORY_FAMILY_WEAPON
	)


static func upgrade_armor_slot(inventory_state: Variant, slot_id: int) -> Dictionary:
	return _upgrade_carried_slot(
		inventory_state,
		slot_id,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR
	)


static func add_consumable_stack(inventory_state: Variant, definition_id: String, amount: int = 1) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_consumable_definition",
		}
	if amount <= 0:
		return {
			"ok": false,
			"error": "invalid_amount",
			"definition_id": definition_id,
		}

	var max_stack: int = _load_max_consumable_stack(definition_id)
	if max_stack <= 0:
		return {
			"ok": false,
			"error": "invalid_max_stack",
			"definition_id": definition_id,
		}

	var requested_amount: int = amount
	var applied_amount: int = 0

	for index in range(inventory_state.inventory_slots.size()):
		var slot: Dictionary = inventory_state.inventory_slots[index]
		if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			continue
		if String(slot.get("definition_id", "")) != definition_id:
			continue
		var current_stack: int = int(slot.get("current_stack", 0))
		var free_space: int = max_stack - current_stack
		if free_space <= 0:
			continue
		var added_here: int = min(free_space, amount)
		slot["current_stack"] = current_stack + added_here
		inventory_state.inventory_slots[index] = slot
		applied_amount += added_here
		amount -= added_here
		if amount <= 0:
			break

	while amount > 0 and inventory_state.has_capacity_for_new_slot():
		var new_stack_amount: int = min(max_stack, amount)
		inventory_state.inventory_slots.append({
			"slot_id": _issue_slot_id(inventory_state),
			"inventory_family": InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE,
			"definition_id": definition_id,
			"current_stack": new_stack_amount,
		})
		applied_amount += new_stack_amount
		amount -= new_stack_amount

	if applied_amount <= 0:
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"definition_id": definition_id,
			"requested_amount": requested_amount,
			"overflow_amount": amount,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	inventory_state.mark_inventory_dirty()
	return {
		"ok": true,
		"definition_id": definition_id,
		"requested_amount": requested_amount,
		"applied_amount": applied_amount,
		"overflow_amount": amount,
		"slot_count": inventory_state.consumable_slots.size(),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


static func remove_consumable_stack(inventory_state: Variant, definition_id: String, amount: int = 1) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_consumable_definition",
		}
	if amount <= 0:
		return {
			"ok": false,
			"error": "invalid_amount",
			"definition_id": definition_id,
		}

	var requested_amount: int = amount
	var removed_amount: int = 0
	var index: int = 0

	while index < inventory_state.inventory_slots.size() and amount > 0:
		var slot: Dictionary = inventory_state.inventory_slots[index]
		if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			index += 1
			continue
		if String(slot.get("definition_id", "")) != definition_id:
			index += 1
			continue

		var current_stack: int = int(slot.get("current_stack", 0))
		if current_stack <= 0:
			inventory_state.inventory_slots.remove_at(index)
			continue

		var removed_here: int = min(current_stack, amount)
		current_stack -= removed_here
		removed_amount += removed_here
		amount -= removed_here

		if current_stack <= 0:
			inventory_state.inventory_slots.remove_at(index)
			continue

		slot["current_stack"] = current_stack
		inventory_state.inventory_slots[index] = slot
		index += 1

	if removed_amount <= 0:
		return {
			"ok": false,
			"error": "missing_consumable_stack",
			"definition_id": definition_id,
			"requested_amount": requested_amount,
		}

	inventory_state.mark_inventory_dirty()
	return {
		"ok": true,
		"definition_id": definition_id,
		"requested_amount": requested_amount,
		"removed_amount": removed_amount,
		"missing_amount": amount,
		"slot_count": inventory_state.consumable_slots.size(),
	}


static func add_passive_item(inventory_state: Variant, definition_id: String, capacity: int) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_passive_definition",
		}
	if capacity <= 0:
		return {
			"ok": false,
			"error": "invalid_passive_capacity",
			"definition_id": definition_id,
		}

	var definition_result: Dictionary = _load_definition_or_error(
		"PassiveItems",
		definition_id,
		"missing_passive_definition"
	)
	if not bool(definition_result.get("ok", false)):
		return definition_result

	var capacity_result: Dictionary = _ensure_capacity_for_carried_item(inventory_state, definition_id)
	if not bool(capacity_result.get("ok", false)):
		return capacity_result

	inventory_state.inventory_slots.append({
		"slot_id": _issue_slot_id(inventory_state),
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_PASSIVE,
		"definition_id": definition_id,
	})
	inventory_state.mark_inventory_dirty()

	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": String(capacity_result.get("replaced_definition_id", "")),
		"replaced_family": String(capacity_result.get("replaced_family", "")),
		"current_passive_count": inventory_state.passive_slots.size(),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


static func add_quest_item(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _add_carried_item(
		inventory_state,
		definition_id,
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM,
		"QuestItems",
		"missing_quest_item_definition"
	)


static func remove_quest_item(inventory_state: Variant, definition_id: String) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_quest_item_definition",
		}

	for index in range(inventory_state.inventory_slots.size()):
		var slot: Dictionary = inventory_state.inventory_slots[index]
		if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			continue
		if String(slot.get("definition_id", "")) != definition_id:
			continue
		var slot_id: int = int(slot.get("slot_id", -1))
		inventory_state.inventory_slots.remove_at(index)
		inventory_state.mark_inventory_dirty()
		return {
			"ok": true,
			"inventory_family": InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM,
			"definition_id": definition_id,
			"slot_id": slot_id,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	return {
		"ok": false,
		"error": "missing_quest_item",
		"definition_id": definition_id,
	}


static func add_carried_weapon(inventory_state: Variant, definition_id: String) -> Dictionary:
	var weapon_result: Dictionary = _load_weapon_definition_with_max_durability(definition_id)
	if not bool(weapon_result.get("ok", false)):
		return weapon_result if inventory_state != null else _missing_inventory_state_result()
	return _add_carried_item(
		inventory_state,
		definition_id,
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		"Weapons",
		"missing_weapon_definition",
		{
			"current_durability": int(weapon_result.get("max_durability", 0)),
			"upgrade_level": 0,
		},
		{
			"current_durability": int(weapon_result.get("max_durability", 0)),
		},
		true
	)


static func add_carried_shield(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _add_carried_item(
		inventory_state,
		definition_id,
		InventoryStateScript.INVENTORY_FAMILY_SHIELD,
		"Shields",
		"missing_shield_definition"
	)


static func add_carried_armor(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _add_carried_item(
		inventory_state,
		definition_id,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		"Armors",
		"missing_armor_definition",
		{
			"upgrade_level": 0,
		}
	)


static func add_carried_belt(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _add_carried_item(
		inventory_state,
		definition_id,
		InventoryStateScript.INVENTORY_FAMILY_BELT,
		"Belts",
		"missing_belt_definition"
	)


static func add_shield_attachment(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _add_carried_item(
		inventory_state,
		definition_id,
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT,
		"ShieldAttachments",
		"missing_shield_attachment_definition"
	)


static func replace_active_weapon(inventory_state: Variant, definition_id: String) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()

	var weapon_result: Dictionary = _load_weapon_definition_with_max_durability(definition_id)
	if not bool(weapon_result.get("ok", false)):
		return weapon_result

	var max_durability: int = int(weapon_result.get("max_durability", 0))
	var equip_result: Dictionary = _replace_active_equipment(
		inventory_state,
		definition_id,
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND,
		{
			"definition_id": definition_id,
			"inventory_family": InventoryStateScript.INVENTORY_FAMILY_WEAPON,
			"current_durability": max_durability,
			"upgrade_level": 0,
		}
	)
	if not bool(equip_result.get("ok", false)):
		return equip_result

	equip_result["current_durability"] = max_durability
	return equip_result


static func replace_active_shield(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _replace_active_equipment(
		inventory_state,
		definition_id,
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND,
		{
			"definition_id": definition_id,
			"inventory_family": InventoryStateScript.INVENTORY_FAMILY_SHIELD,
		},
		"Shields",
		"missing_shield_definition"
	)


static func replace_active_armor(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _replace_active_equipment(
		inventory_state,
		definition_id,
		InventoryStateScript.EQUIPMENT_SLOT_ARMOR,
		{
			"definition_id": definition_id,
			"inventory_family": InventoryStateScript.INVENTORY_FAMILY_ARMOR,
			"upgrade_level": 0,
		},
		"Armors",
		"missing_armor_definition"
	)


static func replace_active_belt(inventory_state: Variant, definition_id: String) -> Dictionary:
	return _replace_active_equipment(
		inventory_state,
		definition_id,
		InventoryStateScript.EQUIPMENT_SLOT_BELT,
		{
			"definition_id": definition_id,
			"inventory_family": InventoryStateScript.INVENTORY_FAMILY_BELT,
		},
		"Belts",
		"missing_belt_definition"
	)


static func _upgrade_carried_slot(inventory_state: Variant, slot_id: int, inventory_family: String) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()

	var slot_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}

	var slot: Dictionary = inventory_state.inventory_slots[slot_index]
	if String(slot.get("inventory_family", "")) != inventory_family:
		return {
			"ok": false,
			"error": "invalid_upgrade_target",
			"slot_id": slot_id,
		}

	slot["upgrade_level"] = max(0, int(slot.get("upgrade_level", 0))) + 1
	inventory_state.inventory_slots[slot_index] = slot
	inventory_state.mark_inventory_dirty()
	return {
		"ok": true,
		"slot_id": slot_id,
		"definition_id": String(slot.get("definition_id", "")),
		"upgrade_level": int(slot.get("upgrade_level", 0)),
		"inventory_family": inventory_family,
	}


static func _add_carried_item(
	inventory_state: Variant,
	definition_id: String,
	inventory_family: String,
	content_family: String,
	missing_error: String,
	slot_payload: Dictionary = {},
	result_payload: Dictionary = {},
	skip_definition_validation: bool = false
) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()

	if not skip_definition_validation:
		var definition_result: Dictionary = _load_definition_or_error(content_family, definition_id, missing_error)
		if not bool(definition_result.get("ok", false)):
			return definition_result

	var capacity_result: Dictionary = _ensure_capacity_for_carried_item(inventory_state, definition_id)
	if not bool(capacity_result.get("ok", false)):
		return capacity_result

	var slot_id: int = _issue_slot_id(inventory_state)
	var slot_entry: Dictionary = slot_payload.duplicate(true)
	slot_entry["slot_id"] = slot_id
	slot_entry["inventory_family"] = inventory_family
	slot_entry["definition_id"] = definition_id
	inventory_state.inventory_slots.append(slot_entry)
	inventory_state.mark_inventory_dirty()

	var result: Dictionary = {
		"ok": true,
		"inventory_family": inventory_family,
		"definition_id": definition_id,
		"slot_id": slot_id,
		"replaced_definition_id": String(capacity_result.get("replaced_definition_id", "")),
		"replaced_family": String(capacity_result.get("replaced_family", "")),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}
	if not result_payload.is_empty():
		result.merge(result_payload, true)
	return result


static func _replace_active_equipment(
	inventory_state: Variant,
	definition_id: String,
	equipment_slot_name: String,
	slot_payload: Dictionary,
	content_family: String = "",
	missing_error: String = ""
) -> Dictionary:
	if inventory_state == null:
		return _missing_inventory_state_result()

	if not content_family.is_empty():
		var definition_result: Dictionary = _load_definition_or_error(content_family, definition_id, missing_error)
		if not bool(definition_result.get("ok", false)):
			return definition_result

	var equip_result: Dictionary = inventory_state.replace_equipped_slot(equipment_slot_name, slot_payload)
	if not bool(equip_result.get("ok", false)):
		return equip_result.merged({"definition_id": definition_id}, true)

	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": String(equip_result.get("replaced_definition_id", "")),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


static func _load_definition_or_error(content_family: String, definition_id: String, missing_error: String) -> Dictionary:
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": missing_error,
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var definition: Dictionary = loader.load_definition(content_family, definition_id)
	if definition.is_empty():
		return {
			"ok": false,
			"error": missing_error,
			"definition_id": definition_id,
		}

	return {
		"ok": true,
		"definition": definition,
		"definition_id": definition_id,
	}


static func _load_weapon_definition_with_max_durability(definition_id: String) -> Dictionary:
	var definition_result: Dictionary = _load_definition_or_error(
		"Weapons",
		definition_id,
		"missing_weapon_definition"
	)
	if not bool(definition_result.get("ok", false)):
		return definition_result

	var definition: Dictionary = definition_result.get("definition", {})
	var max_durability: int = int(definition.get("rules", {}).get("stats", {}).get("max_durability", 0))
	if max_durability <= 0:
		return {
			"ok": false,
			"error": "invalid_weapon_durability",
			"definition_id": definition_id,
		}

	return {
		"ok": true,
		"definition": definition,
		"definition_id": definition_id,
		"max_durability": max_durability,
	}


static func _load_max_consumable_stack(definition_id: String) -> int:
	var definition_result: Dictionary = _load_definition_or_error(
		"Consumables",
		definition_id,
		"missing_consumable_definition"
	)
	if not bool(definition_result.get("ok", false)):
		return -1
	var definition: Dictionary = definition_result.get("definition", {})
	var stats: Dictionary = definition.get("rules", {}).get("stats", {})
	return int(stats.get("max_stack", 0))


static func _ensure_capacity_for_carried_item(inventory_state: Variant, definition_id: String) -> Dictionary:
	if inventory_state.has_capacity_for_new_slot():
		return {
			"ok": true,
			"definition_id": definition_id,
			"replaced_definition_id": "",
			"replaced_family": "",
		}

	var eviction_index: int = _find_oldest_non_active_slot_index(inventory_state)
	if eviction_index < 0:
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"definition_id": definition_id,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	var evicted_slot: Dictionary = inventory_state.inventory_slots[eviction_index]
	inventory_state.inventory_slots.remove_at(eviction_index)
	inventory_state.mark_inventory_dirty()
	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": String(evicted_slot.get("definition_id", "")),
		"replaced_family": String(evicted_slot.get("inventory_family", "")),
	}


static func _find_oldest_non_active_slot_index(inventory_state: Variant) -> int:
	for index in range(inventory_state.inventory_slots.size()):
		if String(inventory_state.inventory_slots[index].get("inventory_family", "")) == InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			continue
		return index
	return -1


static func _issue_slot_id(inventory_state: Variant) -> int:
	var issued_slot_id: int = max(1, int(inventory_state.next_slot_id))
	inventory_state.next_slot_id = issued_slot_id + 1
	return issued_slot_id


static func _missing_inventory_state_result() -> Dictionary:
	return {
		"ok": false,
		"error": "missing_inventory_state",
	}

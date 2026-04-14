# Layer: Application
extends RefCounted
class_name InventoryActions

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")

# Compatibility constant only. Shared inventory capacity is now runtime-owned on InventoryState.
const MAX_CONSUMABLE_SLOTS: int = InventoryStateScript.BASE_SLOT_CAPACITY


func toggle_equipment_slot(inventory_owner: Variant, slot_id: int) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var slot_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}

	var slot: Dictionary = inventory_state.inventory_slots[slot_index]
	var inventory_family: String = String(slot.get("inventory_family", ""))
	if inventory_family not in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		InventoryStateScript.INVENTORY_FAMILY_BELT,
	]:
		return {
			"ok": false,
			"error": "invalid_equipment_family",
			"slot_id": slot_id,
			"inventory_family": inventory_family,
		}

	var active_slot_id: int = _get_active_slot_id_for_family(inventory_state, inventory_family)
	var equipping: bool = active_slot_id != slot_id
	if not equipping and inventory_family == InventoryStateScript.INVENTORY_FAMILY_BELT:
		var next_capacity: int = max(0, inventory_state.get_total_capacity() - InventoryStateScript.BELT_SLOT_CAPACITY_BONUS)
		if inventory_state.get_used_capacity() > next_capacity:
			return {
				"ok": false,
				"error": "belt_capacity_required",
				"slot_id": slot_id,
				"used_capacity": inventory_state.get_used_capacity(),
				"total_capacity": inventory_state.get_total_capacity(),
				"required_capacity": inventory_state.get_used_capacity(),
				"next_capacity": next_capacity,
			}

	_set_active_slot_id_for_family(inventory_state, inventory_family, slot_id if equipping else -1)
	return {
		"ok": true,
		"slot_id": slot_id,
		"inventory_family": inventory_family,
		"definition_id": String(slot.get("definition_id", "")),
		"equipped": equipping,
		"active_slot_id": _get_active_slot_id_for_family(inventory_state, inventory_family),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


func move_slot_to_index(inventory_owner: Variant, slot_id: int, target_index: int) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var source_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if source_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}

	var used_capacity: int = inventory_state.get_used_capacity()
	if used_capacity <= 1:
		return {
			"ok": true,
			"slot_id": slot_id,
			"source_index": source_index,
			"target_index": source_index,
		}

	var clamped_target_index: int = clamp(target_index, 0, max(0, inventory_state.get_total_capacity() - 1))
	var destination_index: int = min(clamped_target_index, used_capacity - 1)
	if destination_index == source_index:
		return {
			"ok": true,
			"slot_id": slot_id,
			"source_index": source_index,
			"target_index": destination_index,
		}

	var slot: Dictionary = inventory_state.inventory_slots[source_index]
	inventory_state.inventory_slots.remove_at(source_index)
	if destination_index > source_index:
		destination_index -= 1
	destination_index = clamp(destination_index, 0, inventory_state.inventory_slots.size())
	inventory_state.inventory_slots.insert(destination_index, slot)
	return {
		"ok": true,
		"slot_id": slot_id,
		"source_index": source_index,
		"target_index": destination_index,
	}


func repair_active_weapon(inventory_owner: Variant) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var definition_id: String = String(inventory_state.weapon_instance.get("definition_id", ""))
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_weapon_definition",
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var weapon_definition: Dictionary = loader.load_definition("Weapons", definition_id)
	if weapon_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_weapon_definition",
			"definition_id": definition_id,
		}

	var stats: Dictionary = weapon_definition.get("rules", {}).get("stats", {})
	var max_durability: int = int(stats.get("max_durability", 0))
	if max_durability <= 0:
		return {
			"ok": false,
			"error": "invalid_weapon_durability",
			"definition_id": definition_id,
		}

	inventory_state.weapon_instance["current_durability"] = max_durability
	return {
		"ok": true,
		"definition_id": definition_id,
		"current_durability": max_durability,
	}


func upgrade_weapon_slot(inventory_owner: Variant, slot_id: int) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var slot_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}

	var slot: Dictionary = inventory_state.inventory_slots[slot_index]
	if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_WEAPON:
		return {
			"ok": false,
			"error": "invalid_upgrade_target",
			"slot_id": slot_id,
		}

	slot["upgrade_level"] = max(0, int(slot.get("upgrade_level", 0))) + 1
	inventory_state.inventory_slots[slot_index] = slot
	return {
		"ok": true,
		"slot_id": slot_id,
		"definition_id": String(slot.get("definition_id", "")),
		"upgrade_level": int(slot.get("upgrade_level", 0)),
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_WEAPON,
	}


func upgrade_armor_slot(inventory_owner: Variant, slot_id: int) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var slot_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}

	var slot: Dictionary = inventory_state.inventory_slots[slot_index]
	if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_ARMOR:
		return {
			"ok": false,
			"error": "invalid_upgrade_target",
			"slot_id": slot_id,
		}

	slot["upgrade_level"] = max(0, int(slot.get("upgrade_level", 0))) + 1
	inventory_state.inventory_slots[slot_index] = slot
	return {
		"ok": true,
		"slot_id": slot_id,
		"definition_id": String(slot.get("definition_id", "")),
		"upgrade_level": int(slot.get("upgrade_level", 0)),
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_ARMOR,
	}


func add_consumable_stack(inventory_owner: Variant, definition_id: String, amount: int = 1) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
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


func remove_consumable_stack(inventory_owner: Variant, definition_id: String, amount: int = 1) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
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

	return {
		"ok": true,
		"definition_id": definition_id,
		"requested_amount": requested_amount,
		"removed_amount": removed_amount,
		"missing_amount": amount,
		"slot_count": inventory_state.consumable_slots.size(),
	}


func add_passive_item(inventory_owner: Variant, definition_id: String, capacity: int) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
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

	var loader: ContentLoader = ContentLoaderScript.new()
	var passive_definition: Dictionary = loader.load_definition("PassiveItems", definition_id)
	if passive_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_passive_definition",
			"definition_id": definition_id,
		}

	var replaced_definition_id: String = ""
	var replaced_family: String = ""
	if not inventory_state.has_capacity_for_new_slot():
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
		replaced_definition_id = String(evicted_slot.get("definition_id", ""))
		replaced_family = String(evicted_slot.get("inventory_family", ""))
		inventory_state.inventory_slots.remove_at(eviction_index)

	inventory_state.inventory_slots.append({
		"slot_id": _issue_slot_id(inventory_state),
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_PASSIVE,
		"definition_id": definition_id,
	})

	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": replaced_definition_id,
		"replaced_family": replaced_family,
		"current_passive_count": inventory_state.passive_slots.size(),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


func add_carried_weapon(inventory_owner: Variant, definition_id: String) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_weapon_definition",
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var weapon_definition: Dictionary = loader.load_definition("Weapons", definition_id)
	if weapon_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_weapon_definition",
			"definition_id": definition_id,
		}

	var max_durability: int = int(weapon_definition.get("rules", {}).get("stats", {}).get("max_durability", 0))
	if max_durability <= 0:
		return {
			"ok": false,
			"error": "invalid_weapon_durability",
			"definition_id": definition_id,
		}

	var capacity_result: Dictionary = _ensure_capacity_for_carried_item(inventory_state, definition_id)
	if not bool(capacity_result.get("ok", false)):
		return capacity_result

	var slot_id: int = _issue_slot_id(inventory_state)
	inventory_state.inventory_slots.append({
		"slot_id": slot_id,
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		"definition_id": definition_id,
		"current_durability": max_durability,
		"upgrade_level": 0,
	})
	return {
		"ok": true,
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		"definition_id": definition_id,
		"slot_id": slot_id,
		"current_durability": max_durability,
		"replaced_definition_id": String(capacity_result.get("replaced_definition_id", "")),
		"replaced_family": String(capacity_result.get("replaced_family", "")),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


func add_carried_armor(inventory_owner: Variant, definition_id: String) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_armor_definition",
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var armor_definition: Dictionary = loader.load_definition("Armors", definition_id)
	if armor_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_armor_definition",
			"definition_id": definition_id,
		}

	var capacity_result: Dictionary = _ensure_capacity_for_carried_item(inventory_state, definition_id)
	if not bool(capacity_result.get("ok", false)):
		return capacity_result

	var slot_id: int = _issue_slot_id(inventory_state)
	inventory_state.inventory_slots.append({
		"slot_id": slot_id,
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		"definition_id": definition_id,
		"upgrade_level": 0,
	})
	return {
		"ok": true,
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		"definition_id": definition_id,
		"slot_id": slot_id,
		"replaced_definition_id": String(capacity_result.get("replaced_definition_id", "")),
		"replaced_family": String(capacity_result.get("replaced_family", "")),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


func replace_active_weapon(inventory_owner: Variant, definition_id: String) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_weapon_definition",
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var weapon_definition: Dictionary = loader.load_definition("Weapons", definition_id)
	if weapon_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_weapon_definition",
			"definition_id": definition_id,
		}

	var stats: Dictionary = weapon_definition.get("rules", {}).get("stats", {})
	var max_durability: int = int(stats.get("max_durability", 0))
	if max_durability <= 0:
		return {
			"ok": false,
			"error": "invalid_weapon_durability",
			"definition_id": definition_id,
		}
	if not inventory_state.has_capacity_for_new_slot():
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"definition_id": definition_id,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	var previous_definition_id: String = String(inventory_state.weapon_instance.get("definition_id", ""))
	var slot_id: int = _issue_slot_id(inventory_state)
	inventory_state.inventory_slots.append({
		"slot_id": slot_id,
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		"definition_id": definition_id,
		"current_durability": max_durability,
		"upgrade_level": 0,
	})
	inventory_state.active_weapon_slot_id = slot_id

	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": previous_definition_id,
		"current_durability": max_durability,
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


func replace_active_armor(inventory_owner: Variant, definition_id: String) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_armor_definition",
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var armor_definition: Dictionary = loader.load_definition("Armors", definition_id)
	if armor_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_armor_definition",
			"definition_id": definition_id,
		}
	if not inventory_state.has_capacity_for_new_slot():
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"definition_id": definition_id,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	var previous_definition_id: String = String(inventory_state.armor_instance.get("definition_id", ""))
	var slot_id: int = _issue_slot_id(inventory_state)
	inventory_state.inventory_slots.append({
		"slot_id": slot_id,
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		"definition_id": definition_id,
		"upgrade_level": 0,
	})
	inventory_state.active_armor_slot_id = slot_id

	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": previous_definition_id,
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


func replace_active_belt(inventory_owner: Variant, definition_id: String) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_belt_definition",
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var belt_definition: Dictionary = loader.load_definition("Belts", definition_id)
	if belt_definition.is_empty():
		return {
			"ok": false,
			"error": "missing_belt_definition",
			"definition_id": definition_id,
		}
	if not inventory_state.has_capacity_for_new_slot(InventoryStateScript.BELT_SLOT_CAPACITY_BONUS):
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"definition_id": definition_id,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	var previous_definition_id: String = String(inventory_state.belt_instance.get("definition_id", ""))
	var slot_id: int = _issue_slot_id(inventory_state)
	inventory_state.inventory_slots.append({
		"slot_id": slot_id,
		"inventory_family": InventoryStateScript.INVENTORY_FAMILY_BELT,
		"definition_id": definition_id,
	})
	inventory_state.active_belt_slot_id = slot_id

	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": previous_definition_id,
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


func _load_max_consumable_stack(definition_id: String) -> int:
	var loader: ContentLoader = ContentLoaderScript.new()
	var consumable_definition: Dictionary = loader.load_definition("Consumables", definition_id)
	if consumable_definition.is_empty():
		return -1
	var stats: Dictionary = consumable_definition.get("rules", {}).get("stats", {})
	return int(stats.get("max_stack", 0))


func _ensure_capacity_for_carried_item(inventory_state: InventoryState, definition_id: String) -> Dictionary:
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
	return {
		"ok": true,
		"definition_id": definition_id,
		"replaced_definition_id": String(evicted_slot.get("definition_id", "")),
		"replaced_family": String(evicted_slot.get("inventory_family", "")),
	}


func _find_oldest_non_active_slot_index(inventory_state: InventoryState) -> int:
	for index in range(inventory_state.inventory_slots.size()):
		var slot: Dictionary = inventory_state.inventory_slots[index]
		var slot_id: int = int(slot.get("slot_id", -1))
		if slot_id in [
			int(inventory_state.active_weapon_slot_id),
			int(inventory_state.active_armor_slot_id),
			int(inventory_state.active_belt_slot_id),
		]:
			continue
		return index
	return -1


func _issue_slot_id(inventory_state: InventoryState) -> int:
	var issued_slot_id: int = max(1, int(inventory_state.next_slot_id))
	inventory_state.next_slot_id = issued_slot_id + 1
	return issued_slot_id


func _get_active_slot_id_for_family(inventory_state: InventoryState, inventory_family: String) -> int:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return int(inventory_state.active_weapon_slot_id)
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return int(inventory_state.active_armor_slot_id)
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return int(inventory_state.active_belt_slot_id)
		_:
			return -1


func _set_active_slot_id_for_family(inventory_state: InventoryState, inventory_family: String, slot_id: int) -> void:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			inventory_state.active_weapon_slot_id = slot_id
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			inventory_state.active_armor_slot_id = slot_id
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			inventory_state.active_belt_slot_id = slot_id


# Transitional compatibility only. New callers should prefer passing InventoryState directly
# instead of widening RunState convenience access into a permanent inventory-owner surface.
func _coerce_inventory_state(inventory_owner: Variant) -> RefCounted:
	if inventory_owner == null:
		return null
	if inventory_owner.get_script() == InventoryStateScript:
		return inventory_owner
	if inventory_owner is RunState:
		return inventory_owner.inventory_state
	return null

# Layer: Application
extends RefCounted
class_name InventoryOverflowResolver

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")


static func preview_inventory_item_grant(
	inventory_state: InventoryState,
	inventory_family: String,
	definition_id: String,
	amount: int = 1
) -> Dictionary:
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var normalized_amount: int = max(1, amount)
	var validation_result: Dictionary = _validate_inventory_item_grant_request(
		inventory_family,
		definition_id,
		normalized_amount
	)
	if not bool(validation_result.get("ok", false)):
		return validation_result

	var preview_result: Dictionary = _build_inventory_grant_preview(
		inventory_state,
		inventory_family,
		definition_id,
		normalized_amount,
		validation_result
	)
	preview_result["inventory_family"] = inventory_family
	preview_result["definition_id"] = definition_id
	preview_result["amount"] = normalized_amount
	preview_result["display_name"] = String(validation_result.get("display_name", definition_id))
	return preview_result


static func discard_backpack_slot(inventory_state: InventoryState, slot_id: int) -> Dictionary:
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
	var inventory_family: String = String(slot.get("inventory_family", "")).strip_edges()
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
		return {
			"ok": false,
			"error": "quest_item_protected",
			"slot_id": slot_id,
			"definition_id": String(slot.get("definition_id", "")),
		}

	inventory_state.inventory_slots.remove_at(slot_index)
	return {
		"ok": true,
		"slot_id": slot_id,
		"discarded_definition_id": String(slot.get("definition_id", "")),
		"discarded_family": inventory_family,
		"display_name": build_slot_display_name(slot),
		"slot_label": "Pack %d" % (slot_index + 1),
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


static func grant_inventory_item(
	inventory_actions: Variant,
	inventory_state: InventoryState,
	inventory_family: String,
	definition_id: String,
	amount: int = 1,
	discard_slot_id: int = -1
) -> Dictionary:
	if inventory_actions == null or inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var discard_result: Dictionary = {}
	if discard_slot_id > 0:
		discard_result = discard_backpack_slot(inventory_state, discard_slot_id)
		if not bool(discard_result.get("ok", false)):
			return discard_result.merged({
				"inventory_family": inventory_family,
				"definition_id": definition_id,
			}, true)

	var grant_result: Dictionary = {}
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			grant_result = inventory_actions.add_consumable_stack(inventory_state, definition_id, amount)
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			grant_result = inventory_actions.add_carried_weapon(inventory_state, definition_id)
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			grant_result = inventory_actions.add_carried_shield(inventory_state, definition_id)
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			grant_result = inventory_actions.add_carried_armor(inventory_state, definition_id)
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			grant_result = inventory_actions.add_carried_belt(inventory_state, definition_id)
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			grant_result = inventory_actions.add_passive_item(inventory_state, definition_id, inventory_state.get_total_capacity())
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			grant_result = inventory_actions.add_quest_item(inventory_state, definition_id)
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			grant_result = inventory_actions.add_shield_attachment(inventory_state, definition_id)
		_:
			grant_result = {
				"ok": false,
				"error": "unsupported_inventory_family",
				"inventory_family": inventory_family,
				"definition_id": definition_id,
			}

	if not bool(grant_result.get("ok", false)) or discard_result.is_empty():
		return grant_result

	var discarded_definition_id: String = String(discard_result.get("discarded_definition_id", ""))
	var discarded_family: String = String(discard_result.get("discarded_family", ""))
	grant_result["discarded_definition_id"] = discarded_definition_id
	grant_result["discarded_family"] = discarded_family
	if String(grant_result.get("replaced_definition_id", "")).is_empty():
		grant_result["replaced_definition_id"] = discarded_definition_id
	if String(grant_result.get("replaced_family", "")).is_empty():
		grant_result["replaced_family"] = discarded_family
	return grant_result


static func build_slot_display_name(slot: Dictionary) -> String:
	var inventory_family: String = String(slot.get("inventory_family", "")).strip_edges()
	var definition_id: String = String(slot.get("definition_id", "")).strip_edges()
	var display_name: String = _load_inventory_display_name(inventory_family, definition_id)
	var upgrade_level: int = int(slot.get("upgrade_level", 0))
	if inventory_family in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
	] and upgrade_level > 0:
		return "%s +%d" % [display_name, upgrade_level]
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
		var current_stack: int = int(slot.get("current_stack", 0))
		if current_stack > 1:
			return "%s x%d" % [display_name, current_stack]
	return display_name


static func _build_inventory_grant_preview(
	inventory_state: InventoryState,
	inventory_family: String,
	definition_id: String,
	amount: int,
	validation_result: Dictionary
) -> Dictionary:
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
		return _build_consumable_grant_preview(
			inventory_state,
			definition_id,
			amount,
			int(validation_result.get("max_stack", 0))
		)

	if inventory_state.has_capacity_for_new_slot():
		return {
			"ok": true,
			"inventory_choice_required": false,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	var discardable_slots: Array[Dictionary] = _build_discardable_slot_snapshots(inventory_state)
	if discardable_slots.is_empty():
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"definition_id": definition_id,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	return {
		"ok": true,
		"inventory_choice_required": true,
		"discardable_slots": discardable_slots,
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


static func _build_consumable_grant_preview(
	inventory_state: InventoryState,
	definition_id: String,
	amount: int,
	max_stack: int
) -> Dictionary:
	var remaining_amount: int = amount
	for slot in inventory_state.inventory_slots:
		if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			continue
		if String(slot.get("definition_id", "")) != definition_id:
			continue
		var free_space: int = max(0, max_stack - int(slot.get("current_stack", 0)))
		if free_space <= 0:
			continue
		remaining_amount -= min(free_space, remaining_amount)
		if remaining_amount <= 0:
			return {
				"ok": true,
				"inventory_choice_required": false,
				"used_capacity": inventory_state.get_used_capacity(),
				"total_capacity": inventory_state.get_total_capacity(),
			}

	var needed_slots: int = int(ceil(float(remaining_amount) / float(max_stack)))
	var available_slots: int = max(0, inventory_state.get_total_capacity() - inventory_state.get_used_capacity())
	if needed_slots <= available_slots:
		return {
			"ok": true,
			"inventory_choice_required": false,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	var missing_slots: int = needed_slots - available_slots
	var discardable_slots: Array[Dictionary] = _build_discardable_slot_snapshots(inventory_state)
	if missing_slots <= 1 and not discardable_slots.is_empty():
		return {
			"ok": true,
			"inventory_choice_required": true,
			"discardable_slots": discardable_slots,
			"required_discard_count": 1,
			"used_capacity": inventory_state.get_used_capacity(),
			"total_capacity": inventory_state.get_total_capacity(),
		}

	return {
		"ok": false,
		"error": "no_inventory_capacity",
		"definition_id": definition_id,
		"requested_amount": amount,
		"used_capacity": inventory_state.get_used_capacity(),
		"total_capacity": inventory_state.get_total_capacity(),
	}


static func _build_discardable_slot_snapshots(inventory_state: InventoryState) -> Array[Dictionary]:
	var discardable_slots: Array[Dictionary] = []
	for index in range(inventory_state.inventory_slots.size()):
		var slot: Dictionary = inventory_state.inventory_slots[index]
		if String(slot.get("inventory_family", "")) == InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			continue
		discardable_slots.append({
			"slot_id": int(slot.get("slot_id", -1)),
			"slot_label": "Pack %d" % (index + 1),
			"inventory_family": String(slot.get("inventory_family", "")),
			"definition_id": String(slot.get("definition_id", "")),
			"display_name": build_slot_display_name(slot),
			"current_stack": int(slot.get("current_stack", 0)),
			"upgrade_level": int(slot.get("upgrade_level", 0)),
		})
	return discardable_slots


static func _validate_inventory_item_grant_request(
	inventory_family: String,
	definition_id: String,
	amount: int
) -> Dictionary:
	if definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_%s_definition" % inventory_family,
		}

	var definition_family: String = _definition_family_for_inventory_family(inventory_family)
	if definition_family.is_empty():
		return {
			"ok": false,
			"error": "unsupported_inventory_family",
			"inventory_family": inventory_family,
			"definition_id": definition_id,
		}

	var loader: ContentLoader = ContentLoaderScript.new()
	var definition: Dictionary = loader.load_definition(definition_family, definition_id)
	if definition.is_empty():
		return {
			"ok": false,
			"error": "missing_%s_definition" % inventory_family,
			"inventory_family": inventory_family,
			"definition_id": definition_id,
		}

	var result: Dictionary = {
		"ok": true,
		"display_name": String(definition.get("display", {}).get("name", definition_id)),
	}
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
		if amount <= 0:
			return {
				"ok": false,
				"error": "invalid_amount",
				"definition_id": definition_id,
			}
		var stats: Dictionary = definition.get("rules", {}).get("stats", {})
		var max_stack: int = int(stats.get("max_stack", 0))
		if max_stack <= 0:
			return {
				"ok": false,
				"error": "invalid_max_stack",
				"definition_id": definition_id,
			}
		result["max_stack"] = max_stack
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_WEAPON:
		var max_durability: int = int(definition.get("rules", {}).get("stats", {}).get("max_durability", 0))
		if max_durability <= 0:
			return {
				"ok": false,
				"error": "invalid_weapon_durability",
				"definition_id": definition_id,
			}
	return result


static func _load_inventory_display_name(inventory_family: String, definition_id: String) -> String:
	var definition_family: String = _definition_family_for_inventory_family(inventory_family)
	if definition_family.is_empty() or definition_id.is_empty():
		return definition_id
	var loader: ContentLoader = ContentLoaderScript.new()
	var definition: Dictionary = loader.load_definition(definition_family, definition_id)
	return String(definition.get("display", {}).get("name", definition_id))


static func _definition_family_for_inventory_family(inventory_family: String) -> String:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return "Weapons"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD:
			return "Shields"
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return "Armors"
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return "Belts"
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			return "Consumables"
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE:
			return "PassiveItems"
		InventoryStateScript.INVENTORY_FAMILY_QUEST_ITEM:
			return "QuestItems"
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			return "ShieldAttachments"
		_:
			return ""

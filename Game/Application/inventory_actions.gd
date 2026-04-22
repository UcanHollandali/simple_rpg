# Layer: Application
extends RefCounted
class_name InventoryActions

const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const InventoryOverflowResolverScript = preload("res://Game/Application/inventory_overflow_resolver.gd")
const InventoryItemMutationHelperScript = preload("res://Game/Application/inventory_item_mutation_helper.gd")

static func extract_consumable_use_profile(use_effect: Dictionary) -> Dictionary:
	if use_effect.is_empty():
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
			"repairs_weapon": false,
		}
	if String(use_effect.get("trigger", "")) != "on_use":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
			"repairs_weapon": false,
		}
	if String(use_effect.get("target", "")) != "self":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
			"repairs_weapon": false,
		}
	var effects: Variant = use_effect.get("effects", [])
	if typeof(effects) != TYPE_ARRAY:
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
			"repairs_weapon": false,
		}
	var heal_amount: int = 0
	var hunger_delta: int = 0
	var repairs_weapon: bool = false
	for effect_value in effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		var params: Variant = effect.get("params", {})
		if typeof(params) != TYPE_DICTIONARY:
			continue
		var effect_params: Dictionary = params
		match String(effect.get("type", "")):
			"heal":
				heal_amount += int(effect_params.get("base", 0))
			"modify_hunger":
				hunger_delta += int(effect_params.get("amount", 0))
			"repair_weapon":
				repairs_weapon = true
	return {
		"heal_amount": heal_amount,
		"hunger_delta": hunger_delta,
		"repairs_weapon": repairs_weapon,
	}

func toggle_equipment_slot(inventory_owner: Variant, slot_id: int, discard_slot_id: int = -1) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	if inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}
	var equipped_slot_name: String = inventory_state.find_equipment_slot_name_by_id(slot_id)
	if not equipped_slot_name.is_empty():
		var equipped_slot: Dictionary = inventory_state.build_equipment_slot_snapshot(equipped_slot_name)
		if (
			equipped_slot_name == InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND
			and inventory_state.shield_slot_has_attachment(equipped_slot)
		):
			return inventory_state.detach_attachment_from_equipped_shield()
		if discard_slot_id > 0 and equipped_slot_name != InventoryStateScript.EQUIPMENT_SLOT_BELT:
			var discard_result: Dictionary = InventoryOverflowResolverScript.discard_backpack_slot(inventory_state, discard_slot_id)
			if not bool(discard_result.get("ok", false)):
				return discard_result
		var unequip_result: Dictionary = inventory_state.move_equipment_slot_to_backpack(equipped_slot_name)
		if bool(unequip_result.get("ok", false)) or String(unequip_result.get("error", "")) != "no_inventory_capacity":
			return unequip_result
		return InventoryOverflowResolverScript.preview_unequip_to_backpack(inventory_state, equipped_slot)

	var slot_index: int = inventory_state.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}
	var slot: Dictionary = inventory_state.inventory_slots[slot_index]
	var inventory_family: String = String(slot.get("inventory_family", ""))
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
		return inventory_state.attach_backpack_attachment_to_equipped_shield(slot_id)
	if inventory_family not in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_SHIELD,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		InventoryStateScript.INVENTORY_FAMILY_BELT,
	]:
		return {
			"ok": false,
			"error": "invalid_equipment_family",
			"slot_id": slot_id,
			"inventory_family": inventory_family,
		}
	var target_equipment_slot: String = inventory_state.resolve_default_equipment_slot_name(slot)
	if target_equipment_slot.is_empty():
		return {
			"ok": false,
			"error": "invalid_equipment_family",
			"slot_id": slot_id,
			"inventory_family": inventory_family,
		}
	return inventory_state.move_backpack_slot_to_equipment(slot_id, target_equipment_slot)
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
	inventory_state.mark_inventory_dirty()
	return {
		"ok": true,
		"slot_id": slot_id,
		"source_index": source_index,
		"target_index": destination_index,
	}


func repair_active_weapon(inventory_owner: Variant) -> Dictionary:
	return InventoryItemMutationHelperScript.repair_active_weapon(_coerce_inventory_state(inventory_owner))


func upgrade_weapon_slot(inventory_owner: Variant, slot_id: int) -> Dictionary:
	return InventoryItemMutationHelperScript.upgrade_weapon_slot(_coerce_inventory_state(inventory_owner), slot_id)


func upgrade_armor_slot(inventory_owner: Variant, slot_id: int) -> Dictionary:
	return InventoryItemMutationHelperScript.upgrade_armor_slot(_coerce_inventory_state(inventory_owner), slot_id)


func add_consumable_stack(inventory_owner: Variant, definition_id: String, amount: int = 1) -> Dictionary:
	return InventoryItemMutationHelperScript.add_consumable_stack(_coerce_inventory_state(inventory_owner), definition_id, amount)


func preview_inventory_item_grant(
	inventory_owner: Variant,
	inventory_family: String,
	definition_id: String,
	amount: int = 1
) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	return InventoryOverflowResolverScript.preview_inventory_item_grant(
		inventory_state,
		inventory_family,
		definition_id,
		amount
	)


func discard_backpack_slot(inventory_owner: Variant, slot_id: int) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	return InventoryOverflowResolverScript.discard_backpack_slot(inventory_state, slot_id)


func remove_consumable_stack(inventory_owner: Variant, definition_id: String, amount: int = 1) -> Dictionary:
	return InventoryItemMutationHelperScript.remove_consumable_stack(_coerce_inventory_state(inventory_owner), definition_id, amount)


func add_passive_item(inventory_owner: Variant, definition_id: String, capacity: int) -> Dictionary:
	return InventoryItemMutationHelperScript.add_passive_item(_coerce_inventory_state(inventory_owner), definition_id, capacity)


func add_quest_item(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.add_quest_item(_coerce_inventory_state(inventory_owner), definition_id)


func remove_quest_item(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.remove_quest_item(_coerce_inventory_state(inventory_owner), definition_id)


func add_carried_weapon(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.add_carried_weapon(_coerce_inventory_state(inventory_owner), definition_id)


func add_carried_shield(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.add_carried_shield(_coerce_inventory_state(inventory_owner), definition_id)


func add_carried_armor(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.add_carried_armor(_coerce_inventory_state(inventory_owner), definition_id)


func add_carried_belt(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.add_carried_belt(_coerce_inventory_state(inventory_owner), definition_id)


func add_shield_attachment(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.add_shield_attachment(_coerce_inventory_state(inventory_owner), definition_id)


func replace_active_weapon(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.replace_active_weapon(_coerce_inventory_state(inventory_owner), definition_id)


func replace_active_shield(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.replace_active_shield(_coerce_inventory_state(inventory_owner), definition_id)


func replace_active_armor(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.replace_active_armor(_coerce_inventory_state(inventory_owner), definition_id)


func replace_active_belt(inventory_owner: Variant, definition_id: String) -> Dictionary:
	return InventoryItemMutationHelperScript.replace_active_belt(_coerce_inventory_state(inventory_owner), definition_id)


func grant_inventory_item(
	inventory_owner: Variant,
	inventory_family: String,
	definition_id: String,
	amount: int = 1,
	discard_slot_id: int = -1
) -> Dictionary:
	var inventory_state: RefCounted = _coerce_inventory_state(inventory_owner)
	return InventoryOverflowResolverScript.grant_inventory_item(
		self,
		inventory_state,
		inventory_family,
		definition_id,
		amount,
		discard_slot_id
	)


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

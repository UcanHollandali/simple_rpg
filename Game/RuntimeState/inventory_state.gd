# Layer: RuntimeState
extends RefCounted
class_name InventoryState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const STARTER_LOADOUT_FAMILY: String = "RunLoadouts"
const STARTER_LOADOUT_ID: String = "starter_loadout"

const INVENTORY_FAMILY_WEAPON: String = "weapon"
const INVENTORY_FAMILY_SHIELD: String = "shield"
const INVENTORY_FAMILY_ARMOR: String = "armor"
const INVENTORY_FAMILY_BELT: String = "belt"
const INVENTORY_FAMILY_CONSUMABLE: String = "consumable"
const INVENTORY_FAMILY_PASSIVE: String = "passive"
const INVENTORY_FAMILY_QUEST_ITEM: String = "quest_item"
const INVENTORY_FAMILY_SHIELD_ATTACHMENT: String = "shield_attachment"
const INVENTORY_FAMILIES: PackedStringArray = [
	INVENTORY_FAMILY_WEAPON,
	INVENTORY_FAMILY_SHIELD,
	INVENTORY_FAMILY_ARMOR,
	INVENTORY_FAMILY_BELT,
	INVENTORY_FAMILY_CONSUMABLE,
	INVENTORY_FAMILY_PASSIVE,
	INVENTORY_FAMILY_QUEST_ITEM,
	INVENTORY_FAMILY_SHIELD_ATTACHMENT,
]

const EQUIPMENT_SLOT_RIGHT_HAND: String = "right_hand"
const EQUIPMENT_SLOT_LEFT_HAND: String = "left_hand"
const EQUIPMENT_SLOT_ARMOR: String = "armor"
const EQUIPMENT_SLOT_BELT: String = "belt"
const EQUIPMENT_SLOT_NAMES: PackedStringArray = [
	EQUIPMENT_SLOT_RIGHT_HAND,
	EQUIPMENT_SLOT_LEFT_HAND,
	EQUIPMENT_SLOT_ARMOR,
	EQUIPMENT_SLOT_BELT,
]

const BASE_BACKPACK_CAPACITY: int = 5
const DEFAULT_BELT_BACKPACK_CAPACITY_BONUS: int = 2
const WEAPON_UPGRADE_ATTACK_BONUS_PER_LEVEL: int = 1
const ARMOR_UPGRADE_DEFENSE_BONUS_PER_LEVEL: int = 1
const SHIELD_ATTACHMENT_ID_KEY: String = "attachment_definition_id"
const SHIELD_ATTACHMENT_TARGET_SLOT: String = EQUIPMENT_SLOT_LEFT_HAND
const SHIELD_MAX_ATTACHMENT_COUNT: int = 1

const DEFAULT_WEAPON_SLOT_COMPATIBILITY := {
	"right_hand": true,
	"left_hand": false,
	"offhand_capable": false,
}

var inventory_slots: Array[Dictionary] = []
var next_slot_id: int = 1
var equipped_right_hand_slot: Dictionary = {}
var equipped_left_hand_slot: Dictionary = {}
var equipped_armor_slot: Dictionary = {}
var equipped_belt_slot: Dictionary = {}

var active_weapon_slot_id: int:
	get:
		return int(equipped_right_hand_slot.get("slot_id", -1))

var active_left_hand_slot_id: int:
	get:
		return int(equipped_left_hand_slot.get("slot_id", -1))

var active_armor_slot_id: int:
	get:
		return int(equipped_armor_slot.get("slot_id", -1))

var active_belt_slot_id: int:
	get:
		return int(equipped_belt_slot.get("slot_id", -1))

var right_hand_instance: Dictionary:
	get:
		return equipped_right_hand_slot
	set(value):
		set_right_hand_instance(value)

var left_hand_instance: Dictionary:
	get:
		return equipped_left_hand_slot
	set(value):
		set_left_hand_instance(value)

var shield_instance: Dictionary:
	get:
		if String(equipped_left_hand_slot.get("inventory_family", "")) == INVENTORY_FAMILY_SHIELD:
			return equipped_left_hand_slot
		return {}

var weapon_instance: Dictionary:
	get:
		return right_hand_instance
	set(value):
		set_weapon_instance(value)

var armor_instance: Dictionary:
	get:
		return equipped_armor_slot
	set(value):
		set_armor_instance(value)

var belt_instance: Dictionary:
	get:
		return equipped_belt_slot
	set(value):
		set_belt_instance(value)

var consumable_slots: Array[Dictionary]:
	get:
		return _collect_family_slots(INVENTORY_FAMILY_CONSUMABLE)
	set(value):
		set_consumable_slots(value)

var passive_slots: Array[Dictionary]:
	get:
		return _collect_family_slots(INVENTORY_FAMILY_PASSIVE)
	set(value):
		set_passive_slots(value)


func reset_for_new_run() -> void:
	inventory_slots = []
	next_slot_id = 1
	equipped_right_hand_slot = {}
	equipped_left_hand_slot = {}
	equipped_armor_slot = {}
	equipped_belt_slot = {}

	var starter_loadout: Dictionary = _load_starter_loadout_definition()
	set_right_hand_instance(_build_starter_equipment_instance(starter_loadout, "right_hand_definition_id", "weapon_definition_id", EQUIPMENT_SLOT_RIGHT_HAND))
	set_left_hand_instance(_build_starter_equipment_instance(starter_loadout, "left_hand_definition_id", "", EQUIPMENT_SLOT_LEFT_HAND))
	set_armor_instance(_build_starter_equipment_instance(starter_loadout, "armor_definition_id", "", EQUIPMENT_SLOT_ARMOR))
	set_belt_instance(_build_starter_equipment_instance(starter_loadout, "belt_definition_id", "", EQUIPMENT_SLOT_BELT))
	_replace_backpack_slots(_build_starter_backpack_slots(starter_loadout))


func copy_from_combat_state(combat_state: CombatState) -> void:
	if combat_state == null:
		return

	var projected_inventory: InventoryState = combat_state.build_inventory_projection(self)
	if projected_inventory == null:
		return

	inventory_slots = projected_inventory.inventory_slots.duplicate(true)
	next_slot_id = max(1, int(projected_inventory.next_slot_id))
	equipped_right_hand_slot = projected_inventory.right_hand_instance.duplicate(true)
	equipped_left_hand_slot = projected_inventory.left_hand_instance.duplicate(true)
	equipped_armor_slot = projected_inventory.armor_instance.duplicate(true)
	equipped_belt_slot = projected_inventory.belt_instance.duplicate(true)
	_normalize_loaded_inventory_state()


func to_save_dict() -> Dictionary:
	return {
		"backpack_slots": inventory_slots.duplicate(true),
		"inventory_next_slot_id": next_slot_id,
		"equipped_right_hand_slot": equipped_right_hand_slot.duplicate(true),
		"equipped_left_hand_slot": equipped_left_hand_slot.duplicate(true),
		"equipped_armor_slot": equipped_armor_slot.duplicate(true),
		"equipped_belt_slot": equipped_belt_slot.duplicate(true),
	}


func load_from_flat_save_dict(save_data: Dictionary) -> void:
	if typeof(save_data.get("backpack_slots", null)) == TYPE_ARRAY:
		inventory_slots = _extract_inventory_slot_array(save_data.get("backpack_slots", []))
		next_slot_id = max(1, int(save_data.get("inventory_next_slot_id", 1)))
		equipped_right_hand_slot = _extract_dictionary(save_data.get("equipped_right_hand_slot", {}))
		equipped_left_hand_slot = _extract_dictionary(save_data.get("equipped_left_hand_slot", {}))
		equipped_armor_slot = _extract_dictionary(save_data.get("equipped_armor_slot", {}))
		equipped_belt_slot = _extract_dictionary(save_data.get("equipped_belt_slot", {}))
		_normalize_loaded_inventory_state()
		return

	if typeof(save_data.get("inventory_slots", null)) == TYPE_ARRAY:
		_load_from_shared_inventory_save_dict(save_data)
		return

	inventory_slots = []
	next_slot_id = 1
	equipped_right_hand_slot = {}
	equipped_left_hand_slot = {}
	equipped_armor_slot = {}
	equipped_belt_slot = {}
	set_weapon_instance(save_data.get("weapon_instance", {}))
	set_armor_instance(save_data.get("armor_instance", {}))
	set_belt_instance(save_data.get("belt_instance", {}))
	set_consumable_slots(save_data.get("consumable_slots", []))
	set_passive_slots(save_data.get("passive_slots", []))


func set_right_hand_instance(value: Variant) -> void:
	equipped_right_hand_slot = _coerce_equipment_slot_dictionary(value, EQUIPMENT_SLOT_RIGHT_HAND)
	_normalize_loaded_inventory_state()


func set_left_hand_instance(value: Variant) -> void:
	equipped_left_hand_slot = _coerce_equipment_slot_dictionary(value, EQUIPMENT_SLOT_LEFT_HAND)
	_normalize_loaded_inventory_state()


func set_weapon_instance(value: Variant) -> void:
	set_right_hand_instance(value)


func set_armor_instance(value: Variant) -> void:
	equipped_armor_slot = _coerce_equipment_slot_dictionary(value, EQUIPMENT_SLOT_ARMOR)
	_normalize_loaded_inventory_state()


func set_belt_instance(value: Variant) -> void:
	equipped_belt_slot = _coerce_equipment_slot_dictionary(value, EQUIPMENT_SLOT_BELT)
	_normalize_loaded_inventory_state()


func set_consumable_slots(value: Variant) -> void:
	_replace_family_slots(INVENTORY_FAMILY_CONSUMABLE, _coerce_consumable_slot_array(value))


func set_passive_slots(value: Variant) -> void:
	_replace_family_slots(INVENTORY_FAMILY_PASSIVE, _coerce_simple_slot_array(value, INVENTORY_FAMILY_PASSIVE))


func get_total_capacity() -> int:
	return BASE_BACKPACK_CAPACITY + _equipped_belt_capacity_bonus()


func get_used_capacity() -> int:
	return inventory_slots.size()


func has_capacity_for_new_slot(prospective_bonus_capacity: int = 0) -> bool:
	return get_used_capacity() + 1 <= (get_total_capacity() + max(0, prospective_bonus_capacity))


func can_store_unequipped_slot(equipment_slot_name: String) -> bool:
	if _get_equipment_slot_dictionary(equipment_slot_name).is_empty():
		return true
	if equipment_slot_name == EQUIPMENT_SLOT_BELT:
		return get_used_capacity() + 1 <= _capacity_after_belt_unequip()
	return has_capacity_for_new_slot()


func find_slot_index_by_id(slot_id: int) -> int:
	for index in range(inventory_slots.size()):
		if int(inventory_slots[index].get("slot_id", -1)) == slot_id:
			return index
	return -1


func find_equipment_slot_name_by_id(slot_id: int) -> String:
	if slot_id <= 0:
		return ""
	for equipment_slot_name in EQUIPMENT_SLOT_NAMES:
		if int(_get_equipment_slot_dictionary(equipment_slot_name).get("slot_id", -1)) == slot_id:
			return equipment_slot_name
	return ""


func get_slot_by_id(slot_id: int) -> Dictionary:
	var equipment_slot_name: String = find_equipment_slot_name_by_id(slot_id)
	if not equipment_slot_name.is_empty():
		return _get_equipment_slot_dictionary(equipment_slot_name)
	var backpack_index: int = find_slot_index_by_id(slot_id)
	if backpack_index < 0:
		return {}
	return inventory_slots[backpack_index]


func find_first_slot_index_by_family(inventory_family: String) -> int:
	for index in range(inventory_slots.size()):
		if String(inventory_slots[index].get("inventory_family", "")) == inventory_family:
			return index
	return -1


func build_inventory_slot_snapshot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= inventory_slots.size():
		return {}
	return inventory_slots[slot_index].duplicate(true)


func build_equipment_slot_snapshot(equipment_slot_name: String) -> Dictionary:
	return _get_equipment_slot_dictionary(equipment_slot_name).duplicate(true)


func slot_matches_family(slot_id: int, inventory_family: String) -> bool:
	var slot: Dictionary = get_slot_by_id(slot_id)
	if slot.is_empty():
		return false
	return String(slot.get("inventory_family", "")) == inventory_family


func shield_slot_has_attachment(slot_data: Dictionary = {}) -> bool:
	var shield_slot: Dictionary = slot_data if not slot_data.is_empty() else shield_instance
	return not _extract_shield_attachment_definition_id(shield_slot).is_empty()


func attach_backpack_attachment_to_equipped_shield(slot_id: int) -> Dictionary:
	var backpack_index: int = find_slot_index_by_id(slot_id)
	if backpack_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}
	var attachment_slot: Dictionary = inventory_slots[backpack_index]
	if String(attachment_slot.get("inventory_family", "")) != INVENTORY_FAMILY_SHIELD_ATTACHMENT:
		return {
			"ok": false,
			"error": "invalid_equipment_family",
			"slot_id": slot_id,
			"inventory_family": String(attachment_slot.get("inventory_family", "")),
		}

	var shield_slot: Dictionary = shield_instance.duplicate(true)
	if shield_slot.is_empty():
		return {
			"ok": false,
			"error": "missing_shield_target",
			"slot_id": slot_id,
		}
	if shield_slot_has_attachment(shield_slot):
		return {
			"ok": false,
			"error": "shield_attachment_slot_occupied",
			"slot_id": slot_id,
			"shield_slot_id": int(shield_slot.get("slot_id", -1)),
		}

	var attachment_definition_id: String = String(attachment_slot.get("definition_id", "")).strip_edges()
	if attachment_definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_attachment_definition",
			"slot_id": slot_id,
		}

	inventory_slots.remove_at(backpack_index)
	shield_slot[SHIELD_ATTACHMENT_ID_KEY] = attachment_definition_id
	equipped_left_hand_slot = _normalize_equipment_slot_dictionary(
		shield_slot,
		SHIELD_ATTACHMENT_TARGET_SLOT,
		int(shield_slot.get("slot_id", -1))
	)
	return {
		"ok": true,
		"action": "attached_attachment",
		"slot_id": slot_id,
		"definition_id": attachment_definition_id,
		"shield_definition_id": String(equipped_left_hand_slot.get("definition_id", "")),
		"used_capacity": get_used_capacity(),
		"total_capacity": get_total_capacity(),
	}


func detach_attachment_from_equipped_shield() -> Dictionary:
	var shield_slot: Dictionary = shield_instance.duplicate(true)
	if shield_slot.is_empty():
		return {
			"ok": false,
			"error": "missing_shield_target",
		}

	var attachment_definition_id: String = _extract_shield_attachment_definition_id(shield_slot)
	if attachment_definition_id.is_empty():
		return {
			"ok": false,
			"error": "missing_shield_attachment",
			"shield_slot_id": int(shield_slot.get("slot_id", -1)),
		}
	if not has_capacity_for_new_slot():
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"shield_slot_id": int(shield_slot.get("slot_id", -1)),
			"used_capacity": get_used_capacity(),
			"total_capacity": get_total_capacity(),
		}

	inventory_slots.append(_normalize_slot_dictionary({
		"definition_id": attachment_definition_id,
	}, INVENTORY_FAMILY_SHIELD_ATTACHMENT, _issue_next_slot_id()))
	shield_slot.erase(SHIELD_ATTACHMENT_ID_KEY)
	equipped_left_hand_slot = _normalize_equipment_slot_dictionary(
		shield_slot,
		SHIELD_ATTACHMENT_TARGET_SLOT,
		int(shield_slot.get("slot_id", -1))
	)
	return {
		"ok": true,
		"action": "detached_attachment",
		"definition_id": attachment_definition_id,
		"shield_definition_id": String(equipped_left_hand_slot.get("definition_id", "")),
		"used_capacity": get_used_capacity(),
		"total_capacity": get_total_capacity(),
	}


func resolve_default_equipment_slot_name(slot_data: Dictionary) -> String:
	var inventory_family: String = String(slot_data.get("inventory_family", ""))
	match inventory_family:
		INVENTORY_FAMILY_ARMOR:
			return EQUIPMENT_SLOT_ARMOR
		INVENTORY_FAMILY_BELT:
			return EQUIPMENT_SLOT_BELT
		INVENTORY_FAMILY_SHIELD:
			return EQUIPMENT_SLOT_LEFT_HAND
		INVENTORY_FAMILY_WEAPON:
			var slot_compatibility: Dictionary = _resolve_weapon_slot_compatibility(String(slot_data.get("definition_id", "")))
			if bool(slot_compatibility.get(EQUIPMENT_SLOT_RIGHT_HAND, true)):
				return EQUIPMENT_SLOT_RIGHT_HAND
			if bool(slot_compatibility.get(EQUIPMENT_SLOT_LEFT_HAND, false)) or bool(slot_compatibility.get("offhand_capable", false)):
				return EQUIPMENT_SLOT_LEFT_HAND
			return ""
		_:
			return ""


func slot_can_equip_to(slot_data: Dictionary, equipment_slot_name: String) -> bool:
	if slot_data.is_empty() or equipment_slot_name.is_empty():
		return false

	var inventory_family: String = String(slot_data.get("inventory_family", ""))
	match equipment_slot_name:
		EQUIPMENT_SLOT_RIGHT_HAND:
			if inventory_family != INVENTORY_FAMILY_WEAPON:
				return false
			return bool(_resolve_weapon_slot_compatibility(String(slot_data.get("definition_id", ""))).get(EQUIPMENT_SLOT_RIGHT_HAND, true))
		EQUIPMENT_SLOT_LEFT_HAND:
			if inventory_family == INVENTORY_FAMILY_SHIELD:
				return true
			if inventory_family != INVENTORY_FAMILY_WEAPON:
				return false
			var slot_compatibility: Dictionary = _resolve_weapon_slot_compatibility(String(slot_data.get("definition_id", "")))
			return bool(slot_compatibility.get(EQUIPMENT_SLOT_LEFT_HAND, false)) or bool(slot_compatibility.get("offhand_capable", false))
		EQUIPMENT_SLOT_ARMOR:
			return inventory_family == INVENTORY_FAMILY_ARMOR
		EQUIPMENT_SLOT_BELT:
			return inventory_family == INVENTORY_FAMILY_BELT
		_:
			return false


func move_backpack_slot_to_equipment(slot_id: int, equipment_slot_name: String) -> Dictionary:
	var backpack_index: int = find_slot_index_by_id(slot_id)
	if backpack_index < 0:
		return {
			"ok": false,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}
	var slot: Dictionary = inventory_slots[backpack_index]
	if not slot_can_equip_to(slot, equipment_slot_name):
		return {
			"ok": false,
			"error": "invalid_equipment_family",
			"slot_id": slot_id,
			"inventory_family": String(slot.get("inventory_family", "")),
			"equipment_slot": equipment_slot_name,
		}

	var displaced_slot: Dictionary = _get_equipment_slot_dictionary(equipment_slot_name).duplicate(true)
	inventory_slots.remove_at(backpack_index)
	if not displaced_slot.is_empty():
		inventory_slots.append(displaced_slot)

	_set_equipment_slot_dictionary(equipment_slot_name, slot)
	return {
		"ok": true,
		"slot_id": slot_id,
		"definition_id": String(slot.get("definition_id", "")),
		"inventory_family": String(slot.get("inventory_family", "")),
		"equipment_slot": equipment_slot_name,
		"equipped": true,
		"replaced_definition_id": String(displaced_slot.get("definition_id", "")),
		"used_capacity": get_used_capacity(),
		"total_capacity": get_total_capacity(),
	}


func move_equipment_slot_to_backpack(equipment_slot_name: String) -> Dictionary:
	var slot: Dictionary = _get_equipment_slot_dictionary(equipment_slot_name).duplicate(true)
	if slot.is_empty():
		return {
			"ok": false,
			"error": "missing_equipped_slot",
			"equipment_slot": equipment_slot_name,
		}
	if not can_store_unequipped_slot(equipment_slot_name):
		var next_capacity: int = _capacity_after_belt_unequip() if equipment_slot_name == EQUIPMENT_SLOT_BELT else get_total_capacity()
		return {
			"ok": false,
			"error": "belt_capacity_required" if equipment_slot_name == EQUIPMENT_SLOT_BELT else "no_inventory_capacity",
			"slot_id": int(slot.get("slot_id", -1)),
			"equipment_slot": equipment_slot_name,
			"used_capacity": get_used_capacity(),
			"total_capacity": get_total_capacity(),
			"required_capacity": get_used_capacity() + 1,
			"next_capacity": next_capacity,
		}

	inventory_slots.append(slot)
	_set_equipment_slot_dictionary(equipment_slot_name, {})
	return {
		"ok": true,
		"slot_id": int(slot.get("slot_id", -1)),
		"definition_id": String(slot.get("definition_id", "")),
		"inventory_family": String(slot.get("inventory_family", "")),
		"equipment_slot": equipment_slot_name,
		"equipped": false,
		"used_capacity": get_used_capacity(),
		"total_capacity": get_total_capacity(),
	}


func replace_equipped_slot(equipment_slot_name: String, slot_data: Dictionary) -> Dictionary:
	if slot_data.is_empty():
		return {
			"ok": false,
			"error": "missing_equipment_definition",
			"equipment_slot": equipment_slot_name,
		}

	var normalized_slot: Dictionary = _normalize_equipment_slot_dictionary(slot_data, equipment_slot_name, _resolve_slot_id_for_new_equipment(slot_data))
	if normalized_slot.is_empty():
		return {
			"ok": false,
			"error": "invalid_equipment_family",
			"equipment_slot": equipment_slot_name,
		}

	var displaced_slot: Dictionary = _get_equipment_slot_dictionary(equipment_slot_name).duplicate(true)
	if not displaced_slot.is_empty() and not has_capacity_for_new_slot():
		return {
			"ok": false,
			"error": "no_inventory_capacity",
			"equipment_slot": equipment_slot_name,
			"used_capacity": get_used_capacity(),
			"total_capacity": get_total_capacity(),
		}

	if not displaced_slot.is_empty():
		inventory_slots.append(displaced_slot)
	_set_equipment_slot_dictionary(equipment_slot_name, normalized_slot)
	return {
		"ok": true,
		"definition_id": String(normalized_slot.get("definition_id", "")),
		"replaced_definition_id": String(displaced_slot.get("definition_id", "")),
		"slot_id": int(normalized_slot.get("slot_id", -1)),
		"equipment_slot": equipment_slot_name,
		"used_capacity": get_used_capacity(),
		"total_capacity": get_total_capacity(),
	}


func _load_starter_loadout_definition() -> Dictionary:
	var loader: ContentLoader = ContentLoaderScript.new()
	return loader.load_definition(STARTER_LOADOUT_FAMILY, STARTER_LOADOUT_ID)


func _build_starter_equipment_instance(
	starter_loadout: Dictionary,
	primary_key: String,
	legacy_key: String,
	equipment_slot_name: String
) -> Dictionary:
	var rules: Dictionary = _extract_definition_rules(starter_loadout)
	var definition_id: String = String(rules.get(primary_key, ""))
	if definition_id.is_empty() and not legacy_key.is_empty():
		definition_id = String(rules.get(legacy_key, ""))
	if definition_id.is_empty():
		return {}

	var inventory_family: String = _inventory_family_for_equipment_slot(equipment_slot_name)
	if equipment_slot_name == EQUIPMENT_SLOT_LEFT_HAND:
		inventory_family = _resolve_left_hand_inventory_family_by_definition_id(definition_id)
	var loader: ContentLoader = ContentLoaderScript.new()
	var definition_family: String = _definition_family_for_inventory_family(inventory_family)
	var definition: Dictionary = loader.load_definition(definition_family, definition_id)
	if definition.is_empty():
		return {}

	var starter_slot: Dictionary = {
		"definition_id": definition_id,
		"inventory_family": inventory_family,
	}
	if inventory_family == INVENTORY_FAMILY_WEAPON:
		var weapon_stats: Dictionary = _extract_definition_stats(definition)
		starter_slot["current_durability"] = int(weapon_stats.get("max_durability", 0))
		starter_slot["upgrade_level"] = 0
	if inventory_family == INVENTORY_FAMILY_ARMOR:
		starter_slot["upgrade_level"] = 0
	return starter_slot


func _build_starter_backpack_slots(starter_loadout: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rules: Dictionary = _extract_definition_rules(starter_loadout)
	var backpack_items_variant: Variant = rules.get("backpack_items", [])
	if typeof(backpack_items_variant) == TYPE_ARRAY:
		for entry_variant in backpack_items_variant:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var slot_entry: Dictionary = entry_variant
			var inventory_family: String = String(slot_entry.get("inventory_family", ""))
			if inventory_family not in INVENTORY_FAMILIES:
				continue
			var normalized_slot: Dictionary = _normalize_slot_dictionary(slot_entry, inventory_family, _issue_next_slot_id())
			if String(normalized_slot.get("definition_id", "")).is_empty():
				continue
			result.append(normalized_slot)
		return result

	var legacy_consumables: Array[Dictionary] = _build_starter_consumable_slots(starter_loadout)
	for entry in legacy_consumables:
		result.append(_normalize_slot_dictionary(entry, INVENTORY_FAMILY_CONSUMABLE, _issue_next_slot_id()))
	return result


func _build_starter_consumable_slots(starter_loadout: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var consumable_slots_variant: Variant = _extract_definition_rules(starter_loadout).get("consumable_slots", [])
	if typeof(consumable_slots_variant) != TYPE_ARRAY:
		return result

	for entry in consumable_slots_variant:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var slot_entry: Dictionary = entry
		var definition_id: String = String(slot_entry.get("definition_id", ""))
		var current_stack: int = int(slot_entry.get("current_stack", 0))
		if definition_id.is_empty() or current_stack <= 0:
			continue
		result.append({
			"definition_id": definition_id,
			"current_stack": current_stack,
		})
	return result


func _extract_definition_stats(definition: Dictionary) -> Dictionary:
	return _extract_definition_rules(definition).get("stats", {})


func _extract_definition_rules(definition: Dictionary) -> Dictionary:
	return definition.get("rules", {})


func _replace_family_slots(inventory_family: String, slots: Array[Dictionary]) -> void:
	var preserved_slots: Array[Dictionary] = []
	for slot in inventory_slots:
		if String(slot.get("inventory_family", "")) == inventory_family:
			continue
		preserved_slots.append(slot)

	inventory_slots = preserved_slots
	for slot_data in slots:
		var normalized_slot: Dictionary = _normalize_slot_dictionary(slot_data, inventory_family, _issue_next_slot_id())
		if String(normalized_slot.get("definition_id", "")).is_empty():
			continue
		inventory_slots.append(normalized_slot)

	_normalize_loaded_inventory_state()


func _replace_backpack_slots(slots: Array[Dictionary]) -> void:
	inventory_slots = []
	for slot_data in slots:
		if typeof(slot_data) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_data
		var inventory_family: String = String(slot.get("inventory_family", ""))
		if inventory_family not in INVENTORY_FAMILIES:
			continue
		var normalized_slot: Dictionary = _normalize_slot_dictionary(slot, inventory_family, _issue_next_slot_id())
		if String(normalized_slot.get("definition_id", "")).is_empty():
			continue
		inventory_slots.append(normalized_slot)
	_normalize_loaded_inventory_state()


func _collect_family_slots(inventory_family: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in inventory_slots:
		if String(slot.get("inventory_family", "")) == inventory_family:
			result.append(slot)
	return result


func _inventory_family_for_equipment_slot(equipment_slot_name: String) -> String:
	match equipment_slot_name:
		EQUIPMENT_SLOT_RIGHT_HAND:
			return INVENTORY_FAMILY_WEAPON
		EQUIPMENT_SLOT_LEFT_HAND:
			return INVENTORY_FAMILY_WEAPON
		EQUIPMENT_SLOT_ARMOR:
			return INVENTORY_FAMILY_ARMOR
		EQUIPMENT_SLOT_BELT:
			return INVENTORY_FAMILY_BELT
		_:
			return ""


func _definition_family_for_inventory_family(inventory_family: String) -> String:
	match inventory_family:
		INVENTORY_FAMILY_WEAPON:
			return "Weapons"
		INVENTORY_FAMILY_SHIELD:
			return "Shields"
		INVENTORY_FAMILY_ARMOR:
			return "Armors"
		INVENTORY_FAMILY_BELT:
			return "Belts"
		INVENTORY_FAMILY_CONSUMABLE:
			return "Consumables"
		INVENTORY_FAMILY_PASSIVE:
			return "PassiveItems"
		INVENTORY_FAMILY_QUEST_ITEM:
			return "QuestItems"
		INVENTORY_FAMILY_SHIELD_ATTACHMENT:
			return "ShieldAttachments"
		_:
			return ""


func _get_equipment_slot_dictionary(equipment_slot_name: String) -> Dictionary:
	match equipment_slot_name:
		EQUIPMENT_SLOT_RIGHT_HAND:
			return equipped_right_hand_slot
		EQUIPMENT_SLOT_LEFT_HAND:
			return equipped_left_hand_slot
		EQUIPMENT_SLOT_ARMOR:
			return equipped_armor_slot
		EQUIPMENT_SLOT_BELT:
			return equipped_belt_slot
		_:
			return {}


func _set_equipment_slot_dictionary(equipment_slot_name: String, slot_data: Dictionary) -> void:
	match equipment_slot_name:
		EQUIPMENT_SLOT_RIGHT_HAND:
			equipped_right_hand_slot = slot_data.duplicate(true)
		EQUIPMENT_SLOT_LEFT_HAND:
			equipped_left_hand_slot = slot_data.duplicate(true)
		EQUIPMENT_SLOT_ARMOR:
			equipped_armor_slot = slot_data.duplicate(true)
		EQUIPMENT_SLOT_BELT:
			equipped_belt_slot = slot_data.duplicate(true)


func _load_from_shared_inventory_save_dict(save_data: Dictionary) -> void:
	inventory_slots = _extract_inventory_slot_array(save_data.get("inventory_slots", []))
	next_slot_id = max(1, int(save_data.get("inventory_next_slot_id", 1)))
	equipped_right_hand_slot = _extract_and_remove_equipped_slot_from_backpack(
		int(save_data.get("active_weapon_slot_id", -1)),
		INVENTORY_FAMILY_WEAPON
	)
	equipped_left_hand_slot = {}
	equipped_armor_slot = _extract_and_remove_equipped_slot_from_backpack(
		int(save_data.get("active_armor_slot_id", -1)),
		INVENTORY_FAMILY_ARMOR
	)
	equipped_belt_slot = _extract_and_remove_equipped_slot_from_backpack(
		int(save_data.get("active_belt_slot_id", -1)),
		INVENTORY_FAMILY_BELT
	)
	_normalize_loaded_inventory_state()


func _extract_and_remove_equipped_slot_from_backpack(slot_id: int, inventory_family: String) -> Dictionary:
	var target_index: int = find_slot_index_by_id(slot_id)
	if target_index < 0 and slot_id > 0:
		return {}
	if target_index < 0:
		target_index = find_first_slot_index_by_family(inventory_family)
		if target_index < 0:
			return {}
	var slot: Dictionary = inventory_slots[target_index]
	if String(slot.get("inventory_family", "")) != inventory_family:
		return {}
	inventory_slots.remove_at(target_index)
	return slot


func _resolve_slot_id_for_new_equipment(slot_data: Dictionary) -> int:
	var authored_slot_id: int = int(slot_data.get("slot_id", -1))
	if authored_slot_id > 0 and not _slot_id_in_use_elsewhere(authored_slot_id):
		return authored_slot_id
	return _issue_next_slot_id()


func _resolve_slot_id_for_equipment_slot(slot_data: Dictionary, equipment_slot_name: String) -> int:
	var authored_slot_id: int = int(slot_data.get("slot_id", -1))
	var current_slot_id: int = int(_get_equipment_slot_dictionary(equipment_slot_name).get("slot_id", -1))
	if authored_slot_id > 0:
		if authored_slot_id == current_slot_id:
			return authored_slot_id
		if not _slot_id_in_use_elsewhere(authored_slot_id):
			return authored_slot_id
	return _issue_next_slot_id()


func _slot_id_in_use_elsewhere(slot_id: int) -> bool:
	if slot_id <= 0:
		return false
	if find_slot_index_by_id(slot_id) >= 0:
		return true
	return not find_equipment_slot_name_by_id(slot_id).is_empty()


func _equipped_belt_capacity_bonus() -> int:
	var definition_id: String = String(belt_instance.get("definition_id", "")).strip_edges()
	if definition_id.is_empty():
		return 0
	var loader: ContentLoader = ContentLoaderScript.new()
	var definition: Dictionary = loader.load_definition("Belts", definition_id)
	var backpack_capacity_bonus: int = int(definition.get("rules", {}).get("backpack_capacity_bonus", DEFAULT_BELT_BACKPACK_CAPACITY_BONUS))
	return max(0, backpack_capacity_bonus)


func _capacity_after_belt_unequip() -> int:
	return BASE_BACKPACK_CAPACITY


func _issue_next_slot_id() -> int:
	var issued_slot_id: int = max(1, next_slot_id)
	next_slot_id = issued_slot_id + 1
	return issued_slot_id


func _normalize_loaded_inventory_state() -> void:
	var seen_slot_ids: Dictionary = {}
	var normalized_backpack: Array[Dictionary] = []
	for slot in inventory_slots:
		var inventory_family: String = String(slot.get("inventory_family", ""))
		if inventory_family not in INVENTORY_FAMILIES:
			continue
		var resolved_slot_id: int = _resolve_loaded_slot_id(slot, seen_slot_ids)
		var normalized_slot: Dictionary = _normalize_slot_dictionary(slot, inventory_family, resolved_slot_id)
		if String(normalized_slot.get("definition_id", "")).is_empty():
			continue
		normalized_backpack.append(normalized_slot)

	inventory_slots = normalized_backpack
	equipped_right_hand_slot = _normalize_loaded_equipment_slot(equipped_right_hand_slot, EQUIPMENT_SLOT_RIGHT_HAND, seen_slot_ids)
	equipped_left_hand_slot = _normalize_loaded_equipment_slot(equipped_left_hand_slot, EQUIPMENT_SLOT_LEFT_HAND, seen_slot_ids)
	equipped_armor_slot = _normalize_loaded_equipment_slot(equipped_armor_slot, EQUIPMENT_SLOT_ARMOR, seen_slot_ids)
	equipped_belt_slot = _normalize_loaded_equipment_slot(equipped_belt_slot, EQUIPMENT_SLOT_BELT, seen_slot_ids)
	next_slot_id = max(next_slot_id, _largest_slot_id() + 1)


func _normalize_loaded_equipment_slot(raw_slot_data: Dictionary, equipment_slot_name: String, seen_slot_ids: Dictionary) -> Dictionary:
	if raw_slot_data.is_empty():
		return {}
	var resolved_slot_id: int = _resolve_loaded_slot_id(raw_slot_data, seen_slot_ids)
	return _normalize_equipment_slot_dictionary(raw_slot_data, equipment_slot_name, resolved_slot_id)


func _resolve_loaded_slot_id(slot_data: Dictionary, seen_slot_ids: Dictionary) -> int:
	var raw_slot_id: int = int(slot_data.get("slot_id", -1))
	if raw_slot_id <= 0 or seen_slot_ids.has(raw_slot_id):
		raw_slot_id = _issue_next_slot_id()
	seen_slot_ids[raw_slot_id] = true
	return raw_slot_id


func _largest_slot_id() -> int:
	var result: int = 0
	for slot in inventory_slots:
		result = max(result, int(slot.get("slot_id", 0)))
	for equipment_slot_name in EQUIPMENT_SLOT_NAMES:
		result = max(result, int(_get_equipment_slot_dictionary(equipment_slot_name).get("slot_id", 0)))
	return result


func _extract_inventory_slot_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append((entry as Dictionary).duplicate(true))
	return result


func _coerce_equipment_slot_dictionary(value: Variant, equipment_slot_name: String) -> Dictionary:
	var slot: Dictionary = _extract_dictionary(value)
	if slot.is_empty():
		return {}
	var slot_id: int = _resolve_slot_id_for_equipment_slot(slot, equipment_slot_name)
	return _normalize_equipment_slot_dictionary(slot, equipment_slot_name, slot_id)


func _normalize_equipment_slot_dictionary(slot_data: Dictionary, equipment_slot_name: String, slot_id: int) -> Dictionary:
	var inventory_family: String = _resolve_equipment_inventory_family(slot_data, equipment_slot_name)
	if inventory_family.is_empty():
		return {}
	var normalized_slot: Dictionary = _normalize_slot_dictionary(slot_data, inventory_family, slot_id)
	if String(normalized_slot.get("definition_id", "")).is_empty():
		return {}
	if not slot_can_equip_to(normalized_slot, equipment_slot_name):
		return {}
	return normalized_slot


func _coerce_consumable_slot_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var slot_entry: Dictionary = entry
		var definition_id: String = String(slot_entry.get("definition_id", ""))
		var current_stack: int = int(slot_entry.get("current_stack", 0))
		if definition_id.is_empty() or current_stack <= 0:
			continue
		result.append({
			"definition_id": definition_id,
			"current_stack": current_stack,
		})
	return result


func _coerce_simple_slot_array(value: Variant, inventory_family: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var slot_entry: Dictionary = entry
		var definition_id: String = String(slot_entry.get("definition_id", ""))
		if definition_id.is_empty():
			continue
		result.append({
			"definition_id": definition_id,
			"inventory_family": inventory_family,
		})
	return result


func _normalize_slot_dictionary(slot_data: Dictionary, inventory_family: String, slot_id: int) -> Dictionary:
	var normalized_slot: Dictionary = {
		"slot_id": slot_id,
		"inventory_family": inventory_family,
		"definition_id": String(slot_data.get("definition_id", "")),
	}
	match inventory_family:
		INVENTORY_FAMILY_WEAPON:
			normalized_slot["current_durability"] = max(0, int(slot_data.get("current_durability", 0)))
			normalized_slot["upgrade_level"] = _extract_upgrade_level(slot_data)
		INVENTORY_FAMILY_SHIELD:
			var attachment_definition_id: String = _extract_shield_attachment_definition_id(slot_data)
			if not attachment_definition_id.is_empty():
				normalized_slot[SHIELD_ATTACHMENT_ID_KEY] = attachment_definition_id
		INVENTORY_FAMILY_ARMOR:
			normalized_slot["upgrade_level"] = _extract_upgrade_level(slot_data)
		INVENTORY_FAMILY_CONSUMABLE:
			normalized_slot["current_stack"] = max(1, int(slot_data.get("current_stack", 1)))
	return normalized_slot


func _resolve_equipment_inventory_family(slot_data: Dictionary, equipment_slot_name: String) -> String:
	var inventory_family: String = String(slot_data.get("inventory_family", ""))
	if inventory_family in INVENTORY_FAMILIES:
		return inventory_family

	var definition_id: String = String(slot_data.get("definition_id", ""))
	match equipment_slot_name:
		EQUIPMENT_SLOT_RIGHT_HAND:
			return INVENTORY_FAMILY_WEAPON
		EQUIPMENT_SLOT_LEFT_HAND:
			return _resolve_left_hand_inventory_family_by_definition_id(definition_id)
		EQUIPMENT_SLOT_ARMOR:
			return INVENTORY_FAMILY_ARMOR
		EQUIPMENT_SLOT_BELT:
			return INVENTORY_FAMILY_BELT
		_:
			return ""


func _extract_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return (value as Dictionary).duplicate(true)


func _extract_upgrade_level(slot_data: Dictionary) -> int:
	return max(0, int(slot_data.get("upgrade_level", 0)))


func _resolve_left_hand_inventory_family_by_definition_id(definition_id: String) -> String:
	if _definition_exists("Shields", definition_id):
		return INVENTORY_FAMILY_SHIELD
	return INVENTORY_FAMILY_WEAPON


func _extract_shield_attachment_definition_id(slot_data: Dictionary) -> String:
	if String(slot_data.get("inventory_family", "")).strip_edges() not in [INVENTORY_FAMILY_SHIELD, ""]:
		return ""
	var attachment_definition_id: String = String(slot_data.get(SHIELD_ATTACHMENT_ID_KEY, "")).strip_edges()
	if attachment_definition_id.is_empty():
		return ""
	if not _definition_exists("ShieldAttachments", attachment_definition_id):
		return ""
	return attachment_definition_id


func _definition_exists(family: String, definition_id: String) -> bool:
	if family.is_empty() or definition_id.is_empty():
		return false
	var definition_path: String = ProjectSettings.globalize_path("res://ContentDefinitions/%s/%s.json" % [family, definition_id])
	return FileAccess.file_exists(definition_path)


func _resolve_weapon_slot_compatibility(definition_id: String) -> Dictionary:
	if definition_id.is_empty():
		return DEFAULT_WEAPON_SLOT_COMPATIBILITY.duplicate(true)
	var loader: ContentLoader = ContentLoaderScript.new()
	var definition: Dictionary = loader.load_definition("Weapons", definition_id)
	var slot_compatibility_variant: Variant = definition.get("rules", {}).get("slot_compatibility", {})
	if typeof(slot_compatibility_variant) != TYPE_DICTIONARY:
		return DEFAULT_WEAPON_SLOT_COMPATIBILITY.duplicate(true)
	var slot_compatibility: Dictionary = DEFAULT_WEAPON_SLOT_COMPATIBILITY.duplicate(true)
	for key_variant in (slot_compatibility_variant as Dictionary).keys():
		var key_name: String = String(key_variant)
		slot_compatibility[key_name] = bool((slot_compatibility_variant as Dictionary).get(key_variant, false))
	return slot_compatibility

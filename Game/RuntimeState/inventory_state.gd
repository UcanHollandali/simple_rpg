# Layer: RuntimeState
extends RefCounted
class_name InventoryState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const STARTER_LOADOUT_FAMILY: String = "RunLoadouts"
const STARTER_LOADOUT_ID: String = "starter_loadout"

const INVENTORY_FAMILY_WEAPON: String = "weapon"
const INVENTORY_FAMILY_ARMOR: String = "armor"
const INVENTORY_FAMILY_BELT: String = "belt"
const INVENTORY_FAMILY_CONSUMABLE: String = "consumable"
const INVENTORY_FAMILY_PASSIVE: String = "passive"
const INVENTORY_FAMILIES: PackedStringArray = [
	INVENTORY_FAMILY_WEAPON,
	INVENTORY_FAMILY_ARMOR,
	INVENTORY_FAMILY_BELT,
	INVENTORY_FAMILY_CONSUMABLE,
	INVENTORY_FAMILY_PASSIVE,
]

const BASE_SLOT_CAPACITY: int = 5
const BELT_SLOT_CAPACITY_BONUS: int = 2
const WEAPON_UPGRADE_ATTACK_BONUS_PER_LEVEL: int = 1
const ARMOR_UPGRADE_DEFENSE_BONUS_PER_LEVEL: int = 1

var inventory_slots: Array[Dictionary] = []
var next_slot_id: int = 1
var active_weapon_slot_id: int = -1
var active_armor_slot_id: int = -1
var active_belt_slot_id: int = -1

var weapon_instance: Dictionary:
	get:
		return _get_active_slot_dictionary(active_weapon_slot_id, INVENTORY_FAMILY_WEAPON)
	set(value):
		set_weapon_instance(value)

var armor_instance: Dictionary:
	get:
		return _get_active_slot_dictionary(active_armor_slot_id, INVENTORY_FAMILY_ARMOR)
	set(value):
		set_armor_instance(value)

var belt_instance: Dictionary:
	get:
		return _get_active_slot_dictionary(active_belt_slot_id, INVENTORY_FAMILY_BELT)
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
	active_weapon_slot_id = -1
	active_armor_slot_id = -1
	active_belt_slot_id = -1

	var starter_loadout: Dictionary = _load_starter_loadout_definition()
	set_weapon_instance(_build_starter_weapon_instance(starter_loadout))
	set_consumable_slots(_build_starter_consumable_slots(starter_loadout))


func copy_from_combat_state(combat_state: CombatState) -> void:
	if combat_state == null:
		return

	var projected_inventory: InventoryState = combat_state.build_inventory_projection(self)
	if projected_inventory == null:
		return

	inventory_slots = projected_inventory.inventory_slots.duplicate(true)
	next_slot_id = max(1, int(projected_inventory.next_slot_id))
	active_weapon_slot_id = int(projected_inventory.active_weapon_slot_id)
	active_armor_slot_id = int(projected_inventory.active_armor_slot_id)
	active_belt_slot_id = int(projected_inventory.active_belt_slot_id)
	_ensure_active_slot_ids_valid()


func to_save_dict() -> Dictionary:
	return {
		"inventory_slots": inventory_slots.duplicate(true),
		"inventory_next_slot_id": next_slot_id,
		"active_weapon_slot_id": active_weapon_slot_id,
		"active_armor_slot_id": active_armor_slot_id,
		"active_belt_slot_id": active_belt_slot_id,
	}


func load_from_flat_save_dict(save_data: Dictionary) -> void:
	if typeof(save_data.get("inventory_slots", null)) == TYPE_ARRAY:
		inventory_slots = _extract_inventory_slot_array(save_data.get("inventory_slots", []))
		next_slot_id = max(1, int(save_data.get("inventory_next_slot_id", 1)))
		active_weapon_slot_id = int(save_data.get("active_weapon_slot_id", -1))
		active_armor_slot_id = int(save_data.get("active_armor_slot_id", -1))
		active_belt_slot_id = int(save_data.get("active_belt_slot_id", -1))
		_normalize_loaded_inventory_state()
		return

	inventory_slots = []
	next_slot_id = 1
	active_weapon_slot_id = -1
	active_armor_slot_id = -1
	active_belt_slot_id = -1
	set_weapon_instance(save_data.get("weapon_instance", {}))
	set_armor_instance(save_data.get("armor_instance", {}))
	set_belt_instance(save_data.get("belt_instance", {}))
	set_consumable_slots(save_data.get("consumable_slots", []))
	set_passive_slots(save_data.get("passive_slots", []))


func set_weapon_instance(value: Variant) -> void:
	_set_or_clear_active_equipment(INVENTORY_FAMILY_WEAPON, _coerce_weapon_slot_dictionary(value))


func set_armor_instance(value: Variant) -> void:
	_set_or_clear_active_equipment(INVENTORY_FAMILY_ARMOR, _coerce_simple_slot_dictionary(value, INVENTORY_FAMILY_ARMOR))


func set_belt_instance(value: Variant) -> void:
	_set_or_clear_active_equipment(INVENTORY_FAMILY_BELT, _coerce_simple_slot_dictionary(value, INVENTORY_FAMILY_BELT))


func set_consumable_slots(value: Variant) -> void:
	_replace_family_slots(INVENTORY_FAMILY_CONSUMABLE, _coerce_consumable_slot_array(value))


func set_passive_slots(value: Variant) -> void:
	_replace_family_slots(INVENTORY_FAMILY_PASSIVE, _coerce_simple_slot_array(value, INVENTORY_FAMILY_PASSIVE))


func get_total_capacity() -> int:
	return BASE_SLOT_CAPACITY + _equipped_belt_capacity_bonus()


func get_used_capacity() -> int:
	return inventory_slots.size()


func has_capacity_for_new_slot(prospective_bonus_capacity: int = 0) -> bool:
	return get_used_capacity() + 1 <= (get_total_capacity() + max(0, prospective_bonus_capacity))


func find_slot_index_by_id(slot_id: int) -> int:
	for index in range(inventory_slots.size()):
		if int(inventory_slots[index].get("slot_id", -1)) == slot_id:
			return index
	return -1


func find_first_slot_index_by_family(inventory_family: String) -> int:
	for index in range(inventory_slots.size()):
		if String(inventory_slots[index].get("inventory_family", "")) == inventory_family:
			return index
	return -1


func build_inventory_slot_snapshot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= inventory_slots.size():
		return {}
	return inventory_slots[slot_index].duplicate(true)


func _load_starter_loadout_definition() -> Dictionary:
	var loader: ContentLoader = ContentLoaderScript.new()
	return loader.load_definition(STARTER_LOADOUT_FAMILY, STARTER_LOADOUT_ID)


func _build_starter_weapon_instance(starter_loadout: Dictionary) -> Dictionary:
	var weapon_definition_id: String = String(_extract_definition_rules(starter_loadout).get("weapon_definition_id", ""))
	if weapon_definition_id.is_empty():
		return {}

	var loader: ContentLoader = ContentLoaderScript.new()
	var weapon_definition: Dictionary = loader.load_definition("Weapons", weapon_definition_id)
	var weapon_stats: Dictionary = _extract_definition_stats(weapon_definition)
	return {
		"definition_id": weapon_definition_id,
		"current_durability": int(weapon_stats.get("max_durability", 0)),
		"upgrade_level": 0,
	}


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
	var rules: Dictionary = definition.get("rules", {})
	return rules


func _set_or_clear_active_equipment(inventory_family: String, slot_data: Dictionary) -> void:
	if slot_data.is_empty():
		_clear_active_equipment(inventory_family)
		return

	var active_slot_id: int = _get_active_slot_id_for_family(inventory_family)
	var target_index: int = find_slot_index_by_id(active_slot_id)
	if target_index < 0:
		target_index = find_first_slot_index_by_family(inventory_family)

	var slot_id: int = active_slot_id
	if target_index >= 0:
		slot_id = int(inventory_slots[target_index].get("slot_id", slot_id))
	else:
		slot_id = _issue_next_slot_id()

	var normalized_slot: Dictionary = _normalize_slot_dictionary(slot_data, inventory_family, slot_id)
	if target_index >= 0:
		inventory_slots[target_index] = normalized_slot
	else:
		inventory_slots.append(normalized_slot)

	_set_active_slot_id_for_family(inventory_family, slot_id)
	_ensure_active_slot_ids_valid()


func _clear_active_equipment(inventory_family: String) -> void:
	var target_index: int = find_slot_index_by_id(_get_active_slot_id_for_family(inventory_family))
	if target_index >= 0:
		inventory_slots.remove_at(target_index)
	_set_active_slot_id_for_family(inventory_family, -1)
	_ensure_active_slot_ids_valid()


func _replace_family_slots(inventory_family: String, slots: Array[Dictionary]) -> void:
	var preserved_slots: Array[Dictionary] = []
	for slot in inventory_slots:
		if String(slot.get("inventory_family", "")) == inventory_family:
			continue
		preserved_slots.append(slot)

	inventory_slots = preserved_slots
	for slot_data in slots:
		var normalized_slot: Dictionary = _normalize_slot_dictionary(slot_data, inventory_family, _issue_next_slot_id())
		inventory_slots.append(normalized_slot)

	_ensure_active_slot_ids_valid()


func _collect_family_slots(inventory_family: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in inventory_slots:
		if String(slot.get("inventory_family", "")) == inventory_family:
			result.append(slot)
	return result


func _get_active_slot_dictionary(slot_id: int, inventory_family: String) -> Dictionary:
	var index: int = find_slot_index_by_id(slot_id)
	if index < 0:
		return {}
	var slot: Dictionary = inventory_slots[index]
	if String(slot.get("inventory_family", "")) != inventory_family:
		return {}
	return slot


func _get_active_slot_id_for_family(inventory_family: String) -> int:
	match inventory_family:
		INVENTORY_FAMILY_WEAPON:
			return active_weapon_slot_id
		INVENTORY_FAMILY_ARMOR:
			return active_armor_slot_id
		INVENTORY_FAMILY_BELT:
			return active_belt_slot_id
		_:
			return -1


func _set_active_slot_id_for_family(inventory_family: String, slot_id: int) -> void:
	match inventory_family:
		INVENTORY_FAMILY_WEAPON:
			active_weapon_slot_id = slot_id
		INVENTORY_FAMILY_ARMOR:
			active_armor_slot_id = slot_id
		INVENTORY_FAMILY_BELT:
			active_belt_slot_id = slot_id


func _equipped_belt_capacity_bonus() -> int:
	return BELT_SLOT_CAPACITY_BONUS if not belt_instance.is_empty() else 0


func _issue_next_slot_id() -> int:
	var issued_slot_id: int = next_slot_id
	next_slot_id += 1
	return issued_slot_id


func _normalize_loaded_inventory_state() -> void:
	var seen_slot_ids: Dictionary = {}
	var normalized_slots: Array[Dictionary] = []
	for slot in inventory_slots:
		var inventory_family: String = String(slot.get("inventory_family", ""))
		if not INVENTORY_FAMILIES.has(inventory_family):
			continue
		var raw_slot_id: int = int(slot.get("slot_id", -1))
		if raw_slot_id <= 0 or seen_slot_ids.has(raw_slot_id):
			raw_slot_id = _issue_next_slot_id()
		seen_slot_ids[raw_slot_id] = true
		normalized_slots.append(_normalize_slot_dictionary(slot, inventory_family, raw_slot_id))

	inventory_slots = normalized_slots
	next_slot_id = max(next_slot_id, _largest_slot_id() + 1)

	active_weapon_slot_id = _resolve_loaded_active_slot_id(active_weapon_slot_id, INVENTORY_FAMILY_WEAPON)
	active_armor_slot_id = _resolve_loaded_active_slot_id(active_armor_slot_id, INVENTORY_FAMILY_ARMOR)
	active_belt_slot_id = _resolve_loaded_active_slot_id(active_belt_slot_id, INVENTORY_FAMILY_BELT)


func _resolve_loaded_active_slot_id(slot_id: int, inventory_family: String) -> int:
	var index: int = find_slot_index_by_id(slot_id)
	if index >= 0 and String(inventory_slots[index].get("inventory_family", "")) == inventory_family:
		return slot_id
	var fallback_index: int = find_first_slot_index_by_family(inventory_family)
	if fallback_index >= 0:
		return int(inventory_slots[fallback_index].get("slot_id", -1))
	return -1


func _largest_slot_id() -> int:
	var result: int = 0
	for slot in inventory_slots:
		result = max(result, int(slot.get("slot_id", 0)))
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


func _coerce_weapon_slot_dictionary(value: Variant) -> Dictionary:
	var slot: Dictionary = _extract_dictionary(value)
	if slot.is_empty():
		return {}
	var definition_id: String = String(slot.get("definition_id", ""))
	if definition_id.is_empty():
		return {}
	return {
		"definition_id": definition_id,
		"current_durability": max(0, int(slot.get("current_durability", 0))),
		"upgrade_level": _extract_upgrade_level(slot),
	}


func _coerce_simple_slot_dictionary(value: Variant, inventory_family: String) -> Dictionary:
	var slot: Dictionary = _extract_dictionary(value)
	if slot.is_empty():
		return {}
	var definition_id: String = String(slot.get("definition_id", ""))
	if definition_id.is_empty():
		return {}
	var normalized_slot: Dictionary = {
		"definition_id": definition_id,
		"inventory_family": inventory_family,
	}
	if inventory_family == INVENTORY_FAMILY_ARMOR:
		normalized_slot["upgrade_level"] = _extract_upgrade_level(slot)
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
		INVENTORY_FAMILY_ARMOR:
			normalized_slot["upgrade_level"] = _extract_upgrade_level(slot_data)
		INVENTORY_FAMILY_CONSUMABLE:
			normalized_slot["current_stack"] = max(1, int(slot_data.get("current_stack", 1)))
	return normalized_slot


func _extract_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return (value as Dictionary).duplicate(true)


func _extract_upgrade_level(slot_data: Dictionary) -> int:
	return max(0, int(slot_data.get("upgrade_level", 0)))


func _ensure_active_slot_ids_valid() -> void:
	if find_slot_index_by_id(active_weapon_slot_id) < 0:
		active_weapon_slot_id = -1
	if find_slot_index_by_id(active_armor_slot_id) < 0:
		active_armor_slot_id = -1
	if find_slot_index_by_id(active_belt_slot_id) < 0:
		active_belt_slot_id = -1

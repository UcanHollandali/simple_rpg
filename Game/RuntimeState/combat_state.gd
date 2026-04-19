# Layer: RuntimeState
extends RefCounted
class_name CombatState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const SUPPORTED_STATUS_MODIFIER_KEYS: PackedStringArray = [
	"attack_power_bonus",
	"incoming_damage_flat_reduction",
	"durability_cost_flat_reduction",
	"skip_player_action",
]

var player_hp: int = 0
var player_hunger: int = RunState.DEFAULT_HUNGER
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var current_turn: int = 1
var current_intent_index: int = 0
var current_intent: Dictionary = {}
var enemy_intent_pool: Array = []
var boss_phase_definitions: Array[Dictionary] = []
var boss_phase_index: int = -1
var boss_phase_id: String = ""
var boss_phase_display_name: String = ""
var inventory_slot_order: Array[int] = []
var active_weapon_slot_id: int = -1
var active_left_hand_slot_id: int = -1
var active_armor_slot_id: int = -1
var active_belt_slot_id: int = -1
var weapon_instance: Dictionary = {}
var left_hand_instance: Dictionary = {}
var armor_instance: Dictionary = {}
var belt_instance: Dictionary = {}
var consumable_slots: Array[Dictionary] = []
var player_statuses: Array[Dictionary] = []
var enemy_statuses: Array[Dictionary] = []
var current_guard: int = 0
var enemy_definition: Dictionary = {}
var encounter_node_family: String = ""
var is_boss_combat: bool = false
var owned_character_perk_ids: Array[String] = []
var player_state: Dictionary = {}
var enemy_state: Dictionary = {}
var event_log: Array[Dictionary] = []
var combat_ended: bool = false
var combat_result: String = ""


func setup_from_run_state(run_state: RunState, enemy_def: Dictionary, combat_setup_data: Dictionary = {}) -> void:
	var inventory_state: RefCounted = run_state.inventory_state
	enemy_definition = enemy_def.duplicate(true)
	encounter_node_family = String(combat_setup_data.get("encounter_node_family", ""))
	is_boss_combat = bool(combat_setup_data.get("is_boss_combat", encounter_node_family == "boss"))
	player_hp = run_state.player_hp
	player_hunger = clamp(int(run_state.hunger), 0, RunState.DEFAULT_HUNGER)
	inventory_slot_order = _extract_inventory_slot_order(inventory_state)
	active_weapon_slot_id = int(inventory_state.active_weapon_slot_id)
	active_left_hand_slot_id = int(inventory_state.active_left_hand_slot_id)
	active_armor_slot_id = int(inventory_state.active_armor_slot_id)
	active_belt_slot_id = int(inventory_state.active_belt_slot_id)
	weapon_instance = inventory_state.weapon_instance.duplicate(true)
	left_hand_instance = inventory_state.left_hand_instance.duplicate(true)
	armor_instance = inventory_state.armor_instance.duplicate(true)
	belt_instance = inventory_state.belt_instance.duplicate(true)
	consumable_slots = inventory_state.consumable_slots.duplicate(true)
	owned_character_perk_ids = run_state.character_perk_state.get_owned_perk_ids()
	player_statuses = []
	enemy_statuses = []
	current_guard = 0
	enemy_hp = int(_extract_enemy_stats(enemy_definition).get("base_hp", 0))
	enemy_max_hp = enemy_hp
	boss_phase_definitions = _extract_enemy_boss_phases(enemy_definition)
	boss_phase_index = -1
	boss_phase_id = ""
	boss_phase_display_name = ""
	enemy_intent_pool = _extract_enemy_intent_pool(enemy_definition)
	current_turn = 1
	current_intent_index = 0
	if has_boss_phases():
		_activate_boss_phase(0)
	else:
		current_intent = _extract_initial_intent()
	_rebuild_player_runtime_state(inventory_state.passive_slots)
	enemy_state = {
		"hp": enemy_hp,
		"definition": enemy_definition.duplicate(true),
	}
	event_log = []
	combat_ended = false
	combat_result = ""


func build_inventory_projection(inventory_state: InventoryState) -> InventoryState:
	if inventory_state == null:
		return null

	var projected_inventory: InventoryState = InventoryStateScript.new()
	projected_inventory.load_from_flat_save_dict(inventory_state.to_save_dict())
	_apply_inventory_slot_order(projected_inventory)
	projected_inventory.set_weapon_instance(
		_build_projected_equipment_slot(
			projected_inventory,
			InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND,
			weapon_instance,
			active_weapon_slot_id,
			InventoryStateScript.INVENTORY_FAMILY_WEAPON
		)
	)
	projected_inventory.set_left_hand_instance(
		_build_projected_equipment_slot(
			projected_inventory,
			InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND,
			left_hand_instance,
			active_left_hand_slot_id,
			_resolve_left_hand_inventory_family()
		)
	)
	projected_inventory.set_armor_instance(
		_build_projected_equipment_slot(
			projected_inventory,
			InventoryStateScript.EQUIPMENT_SLOT_ARMOR,
			armor_instance,
			active_armor_slot_id,
			InventoryStateScript.INVENTORY_FAMILY_ARMOR
		)
	)
	projected_inventory.set_belt_instance(
		_build_projected_equipment_slot(
			projected_inventory,
			InventoryStateScript.EQUIPMENT_SLOT_BELT,
			belt_instance,
			active_belt_slot_id,
			InventoryStateScript.INVENTORY_FAMILY_BELT
		)
	)
	_overlay_consumable_slots(projected_inventory)
	return projected_inventory


func apply_inventory_projection(projected_inventory: InventoryState) -> void:
	if projected_inventory == null:
		return

	active_weapon_slot_id = int(projected_inventory.active_weapon_slot_id)
	active_left_hand_slot_id = int(projected_inventory.active_left_hand_slot_id)
	active_armor_slot_id = int(projected_inventory.active_armor_slot_id)
	active_belt_slot_id = int(projected_inventory.active_belt_slot_id)
	inventory_slot_order = _extract_inventory_slot_order(projected_inventory)
	weapon_instance = projected_inventory.weapon_instance.duplicate(true)
	left_hand_instance = projected_inventory.left_hand_instance.duplicate(true)
	armor_instance = projected_inventory.armor_instance.duplicate(true)
	belt_instance = projected_inventory.belt_instance.duplicate(true)
	consumable_slots = projected_inventory.consumable_slots.duplicate(true)
	_rebuild_player_runtime_state(projected_inventory.passive_slots)


func has_boss_phases() -> bool:
	return is_boss_combat and not boss_phase_definitions.is_empty()


func get_current_boss_phase() -> Dictionary:
	if boss_phase_index < 0 or boss_phase_index >= boss_phase_definitions.size():
		return {}
	return boss_phase_definitions[boss_phase_index].duplicate(true)


func refresh_boss_phase_from_enemy_hp() -> Dictionary:
	if not has_boss_phases():
		return {}

	var next_phase_index: int = _resolve_boss_phase_index_for_enemy_hp()
	if next_phase_index < 0 or next_phase_index == boss_phase_index:
		return {}

	_activate_boss_phase(next_phase_index)
	var active_phase: Dictionary = get_current_boss_phase()
	return {
		"changed": true,
		"phase_index": boss_phase_index,
		"phase_id": boss_phase_id,
		"display_name": boss_phase_display_name,
		"threshold_percent": int(active_phase.get("enter_at_or_below_percent", 100)),
	}


func apply_player_status_definition(status_definition: Dictionary, duration_override: int = -1, stack_override: int = 1) -> Dictionary:
	var status_instance: Dictionary = _build_status_instance(status_definition, duration_override, stack_override)
	if status_instance.is_empty():
		return {}

	var definition_id: String = String(status_instance.get("definition_id", ""))
	for index in range(player_statuses.size()):
		var existing_status: Dictionary = player_statuses[index]
		if String(existing_status.get("definition_id", "")) != definition_id:
			continue

		existing_status["remaining_turns"] = max(
			int(existing_status.get("remaining_turns", 0)),
			int(status_instance.get("remaining_turns", 0))
		)
		existing_status["stacks"] = min(
			int(existing_status.get("max_stacks", 1)),
			max(int(existing_status.get("stacks", 1)), int(status_instance.get("stacks", 1)))
		)
		player_statuses[index] = existing_status

		var refreshed_status: Dictionary = existing_status.duplicate(true)
		refreshed_status["refreshed"] = true
		return refreshed_status

	player_statuses.append(status_instance)
	var applied_status: Dictionary = status_instance.duplicate(true)
	applied_status["refreshed"] = false
	return applied_status


func build_effective_player_state() -> Dictionary:
	var effective_state: Dictionary = player_state.duplicate(true)
	for status_value in player_statuses:
		if typeof(status_value) != TYPE_DICTIONARY:
			continue
		var status: Dictionary = status_value
		var stat_modifiers_variant: Variant = status.get("stat_modifiers", {})
		if typeof(stat_modifiers_variant) != TYPE_DICTIONARY:
			continue
		var stat_modifiers: Dictionary = stat_modifiers_variant
		var stacks: int = max(1, int(status.get("stacks", 1)))
		for stat_key in stat_modifiers.keys():
			var stat_name: String = String(stat_key)
			if stat_name.is_empty():
				continue
			effective_state[stat_name] = int(effective_state.get(stat_name, 0)) + (int(stat_modifiers.get(stat_key, 0)) * stacks)
	return effective_state


func resolve_player_turn_end_statuses() -> Dictionary:
	var total_damage: int = 0
	var ticked_statuses: Array[Dictionary] = []
	var expired_definition_ids: PackedStringArray = []
	var updated_statuses: Array[Dictionary] = []

	for status_value in player_statuses:
		var status: Dictionary = status_value.duplicate(true)
		var remaining_turns: int = int(status.get("remaining_turns", 0))
		if remaining_turns <= 0:
			continue

		var stacks: int = max(1, int(status.get("stacks", 1)))
		var damage_per_turn: int = max(0, int(status.get("damage_per_turn", 0)))
		var damage_applied: int = damage_per_turn * stacks
		if damage_applied > 0:
			player_hp = max(0, player_hp - damage_applied)
			player_state["hp"] = player_hp
			total_damage += damage_applied

		remaining_turns -= 1
		status["remaining_turns"] = remaining_turns
		ticked_statuses.append({
			"definition_id": String(status.get("definition_id", "")),
			"display_name": String(status.get("display_name", "")),
			"damage_applied": damage_applied,
			"remaining_turns": remaining_turns,
		})

		if remaining_turns > 0:
			updated_statuses.append(status)
		else:
			expired_definition_ids.append(String(status.get("definition_id", "")))

	player_statuses = updated_statuses

	return {
		"total_damage": total_damage,
		"ticked_statuses": ticked_statuses,
		"expired_definition_ids": expired_definition_ids,
	}


func _extract_enemy_stats(definition: Dictionary) -> Dictionary:
	var rules: Dictionary = definition.get("rules", {})
	return rules.get("stats", {})


func _extract_enemy_intent_pool(definition: Dictionary) -> Array:
	var rules: Dictionary = definition.get("rules", {})
	return rules.get("intent_pool", []).duplicate(true)


func _extract_enemy_boss_phases(definition: Dictionary) -> Array[Dictionary]:
	var rules: Dictionary = definition.get("rules", {})
	var boss_phases_variant: Variant = rules.get("boss_phases", [])
	if typeof(boss_phases_variant) != TYPE_ARRAY:
		return []

	var phases: Array[Dictionary] = []
	var raw_phases: Array = boss_phases_variant
	for phase_value in raw_phases:
		if typeof(phase_value) != TYPE_DICTIONARY:
			continue
		var phase: Dictionary = phase_value
		phases.append(phase.duplicate(true))
	return phases


func _extract_initial_intent() -> Dictionary:
	if enemy_intent_pool.is_empty():
		return {}
	if typeof(enemy_intent_pool[0]) != TYPE_DICTIONARY:
		return {}
	var intent_dict: Dictionary = enemy_intent_pool[0]
	return intent_dict.duplicate(true)


func _activate_boss_phase(phase_index: int) -> void:
	if phase_index < 0 or phase_index >= boss_phase_definitions.size():
		return

	boss_phase_index = phase_index
	var phase_definition: Dictionary = boss_phase_definitions[phase_index]
	boss_phase_id = String(phase_definition.get("phase_id", ""))
	boss_phase_display_name = String(phase_definition.get("display_name", boss_phase_id))
	var phase_intent_pool_variant: Variant = phase_definition.get("intent_pool", [])
	if typeof(phase_intent_pool_variant) == TYPE_ARRAY:
		var phase_intent_pool: Array = phase_intent_pool_variant
		enemy_intent_pool = phase_intent_pool.duplicate(true)
	else:
		enemy_intent_pool = []
	current_intent_index = 0
	current_intent = _extract_initial_intent()


func _resolve_boss_phase_index_for_enemy_hp() -> int:
	if not has_boss_phases():
		return -1

	var resolved_phase_index: int = 0
	var hp_percent: int = int(floor((float(max(0, enemy_hp)) * 100.0) / float(max(1, enemy_max_hp))))
	for index in range(1, boss_phase_definitions.size()):
		var phase_definition: Dictionary = boss_phase_definitions[index]
		var threshold_percent: int = int(phase_definition.get("enter_at_or_below_percent", -1))
		if threshold_percent > 0 and hp_percent <= threshold_percent:
			resolved_phase_index = index
	return resolved_phase_index


func _rebuild_player_runtime_state(passive_slot_list: Array[Dictionary]) -> void:
	var random_roll_percent: int = int(player_state.get("random_roll_percent", 100))
	player_state = {
		"hp": player_hp,
		"hunger": player_hunger,
		"weapon_instance": weapon_instance.duplicate(true),
		"left_hand_instance": left_hand_instance.duplicate(true),
		"armor_instance": armor_instance.duplicate(true),
		"belt_instance": belt_instance.duplicate(true),
		"consumable_slots": consumable_slots.duplicate(true),
		"guard_points": current_guard,
		"random_roll_percent": random_roll_percent,
	}
	if String(left_hand_instance.get("inventory_family", "")) == InventoryStateScript.INVENTORY_FAMILY_SHIELD:
		_apply_equipped_item_effect("Shields", left_hand_instance)
		_apply_equipped_shield_attachment_effect(left_hand_instance)
	_apply_equipped_item_effect("Armors", armor_instance)
	_apply_equipped_upgrade_bonus("weapon", weapon_instance)
	_apply_equipped_upgrade_bonus("armor", armor_instance)
	_apply_passive_item_effects(passive_slot_list)
	_apply_character_perk_effects()


func _resolve_left_hand_inventory_family() -> String:
	var inventory_family: String = String(left_hand_instance.get("inventory_family", ""))
	if inventory_family in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_SHIELD,
	]:
		return inventory_family
	return InventoryStateScript.INVENTORY_FAMILY_WEAPON


func _build_projected_equipment_slot(
	inventory_state: InventoryState,
	equipment_slot_name: String,
	slot_instance: Dictionary,
	slot_id: int,
	inventory_family: String
) -> Dictionary:
	if slot_instance.is_empty():
		return {}

	var projected_slot: Dictionary = slot_instance.duplicate(true)
	projected_slot["inventory_family"] = inventory_family
	if slot_id > 0:
		projected_slot["slot_id"] = slot_id
	else:
		var existing_slot: Dictionary = inventory_state.build_equipment_slot_snapshot(equipment_slot_name)
		if not existing_slot.is_empty():
			projected_slot["slot_id"] = int(existing_slot.get("slot_id", -1))
	return projected_slot


func _overlay_consumable_slots(inventory_state: InventoryState) -> void:
	if inventory_state == null:
		return

	var combat_slots_by_id: Dictionary = {}
	for slot_value in consumable_slots:
		if typeof(slot_value) != TYPE_DICTIONARY:
			continue
		var combat_slot: Dictionary = slot_value
		var slot_id: int = int(combat_slot.get("slot_id", -1))
		if slot_id <= 0:
			continue
		combat_slots_by_id[slot_id] = combat_slot.duplicate(true)

	var inventory_changed: bool = false
	for index in range(inventory_state.inventory_slots.size() - 1, -1, -1):
		var slot: Dictionary = inventory_state.inventory_slots[index]
		if String(slot.get("inventory_family", "")) != InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
			continue
		var slot_id: int = int(slot.get("slot_id", -1))
		if not combat_slots_by_id.has(slot_id):
			inventory_state.inventory_slots.remove_at(index)
			inventory_changed = true
			continue
		var merged_slot: Dictionary = slot.duplicate(true)
		merged_slot["current_stack"] = int((combat_slots_by_id[slot_id] as Dictionary).get("current_stack", merged_slot.get("current_stack", 0)))
		inventory_state.inventory_slots[index] = merged_slot
		inventory_changed = true
	if inventory_changed:
		inventory_state.mark_inventory_dirty()


func _extract_inventory_slot_order(inventory_state: InventoryState) -> Array[int]:
	var result: Array[int] = []
	if inventory_state == null:
		return result
	for slot in inventory_state.inventory_slots:
		result.append(int(slot.get("slot_id", -1)))
	return result


func _apply_inventory_slot_order(inventory_state: InventoryState) -> void:
	if inventory_state == null or inventory_slot_order.is_empty():
		return

	var slot_by_id: Dictionary = {}
	for slot in inventory_state.inventory_slots:
		slot_by_id[int(slot.get("slot_id", -1))] = slot

	var reordered_slots: Array[Dictionary] = []
	for ordered_slot_id in inventory_slot_order:
		if not slot_by_id.has(ordered_slot_id):
			continue
		reordered_slots.append((slot_by_id[ordered_slot_id] as Dictionary).duplicate(true))
		slot_by_id.erase(ordered_slot_id)

	for remaining_slot_id in slot_by_id.keys():
		reordered_slots.append((slot_by_id[remaining_slot_id] as Dictionary).duplicate(true))

	inventory_state.inventory_slots = reordered_slots
	inventory_state.mark_inventory_dirty()


func _apply_passive_item_effects(passive_slot_list: Array[Dictionary]) -> void:
	if passive_slot_list.is_empty():
		return

	var loader: ContentLoader = ContentLoaderScript.new()
	for slot in passive_slot_list:
		var definition_id: String = String(slot.get("definition_id", ""))
		if definition_id.is_empty():
			continue
		var definition: Dictionary = loader.load_definition("PassiveItems", definition_id)
		_apply_passive_definition_to_player_state(definition)


func _apply_character_perk_effects() -> void:
	if owned_character_perk_ids.is_empty():
		return

	var loader: ContentLoader = ContentLoaderScript.new()
	for definition_id in owned_character_perk_ids:
		if definition_id.is_empty():
			continue
		var definition: Dictionary = loader.load_definition("CharacterPerks", definition_id)
		_apply_passive_definition_to_player_state(definition)


func _apply_equipped_item_effect(family: String, item_instance: Dictionary) -> void:
	var definition_id: String = String(item_instance.get("definition_id", ""))
	if definition_id.is_empty():
		return

	var loader: ContentLoader = ContentLoaderScript.new()
	var definition: Dictionary = loader.load_definition(family, definition_id)
	if definition.is_empty():
		return
	_apply_passive_definition_to_player_state(definition)


func _apply_equipped_shield_attachment_effect(shield_instance: Dictionary) -> void:
	if shield_instance.is_empty():
		return
	var attachment_definition_id: String = String(shield_instance.get(InventoryStateScript.SHIELD_ATTACHMENT_ID_KEY, "")).strip_edges()
	if attachment_definition_id.is_empty():
		return
	var loader: ContentLoader = ContentLoaderScript.new()
	var attachment_definition: Dictionary = loader.load_definition("ShieldAttachments", attachment_definition_id)
	if attachment_definition.is_empty():
		return
	_apply_passive_definition_to_player_state(attachment_definition)


func _apply_equipped_upgrade_bonus(item_family: String, item_instance: Dictionary) -> void:
	var upgrade_level: int = max(0, int(item_instance.get("upgrade_level", 0)))
	if upgrade_level <= 0:
		return

	match item_family:
		"weapon":
			player_state["attack_power_bonus"] = int(player_state.get("attack_power_bonus", 0)) + (
				upgrade_level * InventoryStateScript.WEAPON_UPGRADE_ATTACK_BONUS_PER_LEVEL
			)
		"armor":
			player_state["incoming_damage_flat_reduction"] = int(player_state.get("incoming_damage_flat_reduction", 0)) + (
				upgrade_level * InventoryStateScript.ARMOR_UPGRADE_DEFENSE_BONUS_PER_LEVEL
			)


func _apply_passive_definition_to_player_state(definition: Dictionary) -> void:
	var rules: Dictionary = definition.get("rules", {})
	var behaviors: Array = rules.get("behaviors", [])
	for behavior_value in behaviors:
		if typeof(behavior_value) != TYPE_DICTIONARY:
			continue
		var behavior: Dictionary = behavior_value
		if String(behavior.get("trigger", "")) != "passive":
			continue
		if String(behavior.get("target", "")) != "self":
			continue
		var effects: Array = behavior.get("effects", [])
		for effect_value in effects:
			if typeof(effect_value) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_value
			if String(effect.get("type", "")) != "modify_stat":
				continue
			var params: Dictionary = effect.get("params", {})
			var stat_name: String = String(params.get("stat", ""))
			if stat_name.is_empty():
				continue
			player_state[stat_name] = int(player_state.get(stat_name, 0)) + int(params.get("amount", 0))


func _build_status_instance(status_definition: Dictionary, duration_override: int, stack_override: int) -> Dictionary:
	var definition_id: String = String(status_definition.get("definition_id", ""))
	if definition_id.is_empty():
		return {}

	var rules: Dictionary = status_definition.get("rules", {})
	var stats: Dictionary = rules.get("stats", {})
	var display: Dictionary = status_definition.get("display", {})
	var damage_per_turn: int = int(stats.get("damage_per_turn", 0))
	var default_duration_turns: int = int(stats.get("duration_turns", 0))
	var max_stacks: int = max(1, int(stats.get("max_stacks", 1)))
	var stat_modifiers: Dictionary = _extract_status_stat_modifiers(stats)
	var remaining_turns: int = duration_override if duration_override > 0 else default_duration_turns
	var stacks: int = min(max_stacks, max(1, stack_override))
	if (damage_per_turn <= 0 and stat_modifiers.is_empty()) or remaining_turns <= 0:
		return {}

	return {
		"definition_id": definition_id,
		"display_name": String(display.get("name", definition_id)),
		"damage_per_turn": damage_per_turn,
		"stat_modifiers": stat_modifiers.duplicate(true),
		"remaining_turns": remaining_turns,
		"stacks": stacks,
		"max_stacks": max_stacks,
	}


func _extract_status_stat_modifiers(stats: Dictionary) -> Dictionary:
	var stat_modifiers_variant: Variant = stats.get("stat_modifiers", {})
	if typeof(stat_modifiers_variant) != TYPE_DICTIONARY:
		return {}

	var raw_modifiers: Dictionary = stat_modifiers_variant
	var result: Dictionary = {}
	for stat_key in raw_modifiers.keys():
		var stat_name: String = String(stat_key)
		if not SUPPORTED_STATUS_MODIFIER_KEYS.has(stat_name):
			continue
		result[stat_name] = int(raw_modifiers.get(stat_key, 0))
	return result

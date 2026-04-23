# Layer: Application
extends RefCounted
class_name CombatFlow

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
signal domain_event_emitted(event_name: String, payload: Dictionary)
signal combat_ended_signal(result: String)
signal turn_phase_resolved(phase_name: String, action_name: String, result: Dictionary)

const ACTION_ATTACK: String = "attack"
const ACTION_DEFEND: String = "defend"
const ACTION_TECHNIQUE: String = "technique"
const ACTION_USE_ITEM: String = "use_item"
const ACTION_SWAP_HAND: String = "swap_hand"

const PHASE_PLAYER_ACTION: String = "player_action"
const PHASE_ENEMY_ACTION: String = "enemy_action"
const PHASE_TURN_END: String = "turn_end"

var combat_state: CombatState = CombatState.new()

var _resolver: CombatResolver
var _run_state: RunState
var _enemy_definition: Dictionary = {}
var _weapon_definition: Dictionary = {}
var _content_loader: ContentLoader = ContentLoaderScript.new()
var _pending_turn_hunger_cost: int = -1


func _init(resolver: CombatResolver = null) -> void:
	if resolver != null:
		_resolver = resolver
	else:
		_resolver = CombatResolver.new()


func setup_combat(
	run_state: RunState,
	enemy_definition: Dictionary,
	weapon_definition: Dictionary,
	combat_setup_data: Dictionary = {}
) -> CombatState:
	_run_state = run_state
	_enemy_definition = enemy_definition.duplicate(true)
	_weapon_definition = weapon_definition.duplicate(true)

	combat_state = CombatState.new()
	combat_state.setup_from_run_state(_run_state, _enemy_definition, combat_setup_data)
	_resolve_active_weapon_definition()
	_pending_turn_hunger_cost = -1

	emit_signal("domain_event_emitted", "CombatStarted", {
		"enemy_definition_id": String(_enemy_definition.get("definition_id", "")),
		"encounter_node_family": String(combat_state.encounter_node_family),
		"is_boss_combat": bool(combat_state.is_boss_combat),
		"boss_phase_id": String(combat_state.boss_phase_id),
		"boss_phase_display_name": String(combat_state.boss_phase_display_name),
		"current_turn": combat_state.current_turn,
	})

	_emit_revealed_intent_if_present()

	return combat_state


func process_player_attack() -> Dictionary:
	if combat_state.combat_ended:
		return _build_ended_action_result()

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_ATTACK)
	if not forced_skip_result.is_empty():
		return forced_skip_result

	var effective_player_state: Dictionary = combat_state.build_effective_player_state()
	effective_player_state["random_roll_percent"] = int(effective_player_state.get("random_roll_percent", 100))
	var active_weapon_definition: Dictionary = _resolve_active_weapon_definition()
	var result: Dictionary = _resolver.resolve_player_attack(
		effective_player_state,
		combat_state.enemy_state,
		active_weapon_definition
	)

	_consume_resolver_output(result)
	_emit_player_action_chosen("Attack")
	return _finalize_action_result(result)


func resolve_attack_turn() -> Dictionary:
	return _resolve_full_turn(ACTION_ATTACK)


func resolve_swap_hand_turn(equipment_slot_name: String, backpack_slot_id: int) -> Dictionary:
	return _resolve_full_turn(ACTION_SWAP_HAND, {
		"equipment_slot_name": equipment_slot_name,
		"backpack_slot_id": backpack_slot_id,
	})


func process_technique() -> Dictionary:
	if combat_state.combat_ended:
		return _build_ended_action_result()

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_TECHNIQUE)
	if not forced_skip_result.is_empty():
		return forced_skip_result
	if not has_equipped_technique():
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": "missing_equipped_technique",
		})
	if not is_technique_available():
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": _resolve_technique_unavailable_reason(),
			"technique_definition_id": String(combat_state.equipped_technique_definition_id),
		})

	var effective_player_state: Dictionary = combat_state.build_effective_player_state()
	effective_player_state["random_roll_percent"] = int(effective_player_state.get("random_roll_percent", 100))
	effective_player_state["queued_attack_multiplier"] = max(1, int(combat_state.queued_attack_multiplier))
	effective_player_state["player_status_count"] = combat_state.player_statuses.size()
	var active_weapon_definition: Dictionary = _resolve_active_weapon_definition()
	var result: Dictionary = _resolver.resolve_player_technique(
		effective_player_state,
		combat_state.enemy_state,
		active_weapon_definition,
		combat_state.equipped_technique_definition
	)
	if bool(result.get("skipped", false)):
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": String(result.get("error", "technique_failed")),
		})

	if String(result.get("technique_effect_type", "")) == "remove_statuses":
		var removed_status_definition_ids: PackedStringArray = combat_state.clear_player_statuses()
		result["removed_status_definition_ids"] = removed_status_definition_ids
		result["removed_status_count"] = removed_status_definition_ids.size()

	_consume_resolver_output(result)
	combat_state.technique_spent = true
	combat_state.player_state["technique_spent"] = true
	_sync_mirror_fields_from_runtime_state()
	_append_event({
		"type": "technique_used",
		"turn": combat_state.current_turn,
		"technique_definition_id": String(result.get("technique_definition_id", combat_state.equipped_technique_definition_id)),
		"technique_effect_type": String(result.get("technique_effect_type", "")),
	})
	_emit_player_action_chosen("Technique")
	emit_signal("domain_event_emitted", "TechniqueUsed", {
		"turn": combat_state.current_turn,
		"technique_definition_id": String(result.get("technique_definition_id", combat_state.equipped_technique_definition_id)),
		"display_name": String(result.get("technique_display_name", combat_state.equipped_technique_definition_id)),
		"technique_effect_type": String(result.get("technique_effect_type", "")),
		"damage_applied": int(result.get("damage_applied", 0)),
		"healed_amount": int(result.get("healed_amount", 0)),
		"removed_status_count": int(result.get("removed_status_count", 0)),
		"queued_attack_multiplier": int(result.get("queued_attack_multiplier", 1)),
	})
	return _finalize_action_result(result)


func resolve_technique_turn() -> Dictionary:
	return _resolve_full_turn(ACTION_TECHNIQUE)


func process_enemy_action() -> Dictionary:
	if check_combat_end():
		return _build_ended_action_result()

	var result: Dictionary = _resolver.resolve_enemy_action(
		combat_state.enemy_state,
		combat_state.build_effective_player_state(),
		combat_state.current_intent
	)

	_consume_resolver_output(result)
	if not _resolver.check_defeat(combat_state.player_state):
		result["applied_statuses"] = _apply_status_effects_from_enemy_intent(combat_state.current_intent)
	return _finalize_action_result(result)


func resolve_use_item_turn(slot_index: int = -1) -> Dictionary:
	return _resolve_full_turn(ACTION_USE_ITEM, slot_index)


func process_swap_hand(equipment_slot_name: String, backpack_slot_id: int) -> Dictionary:
	if combat_state.combat_ended:
		return _build_ended_action_result()

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_SWAP_HAND)
	if not forced_skip_result.is_empty():
		return forced_skip_result
	if not _is_supported_hand_swap_slot(equipment_slot_name):
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": "unsupported_hand_swap_slot",
			"equipment_slot_name": equipment_slot_name,
		})

	var projected_inventory: InventoryState = _build_projected_inventory_state()
	if projected_inventory == null:
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": "missing_inventory_projection",
			"equipment_slot_name": equipment_slot_name,
		})
	if _build_hand_swap_candidate_slots(projected_inventory, equipment_slot_name).is_empty():
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": "missing_hand_swap_candidate",
			"equipment_slot_name": equipment_slot_name,
		})

	var candidate_index: int = projected_inventory.find_slot_index_by_id(backpack_slot_id)
	if candidate_index < 0:
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": "missing_inventory_slot",
			"equipment_slot_name": equipment_slot_name,
			"backpack_slot_id": backpack_slot_id,
		})

	var candidate_slot: Dictionary = projected_inventory.inventory_slots[candidate_index]
	if not _slot_is_valid_hand_swap_candidate(projected_inventory, candidate_slot, equipment_slot_name):
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": "invalid_hand_swap_candidate",
			"equipment_slot_name": equipment_slot_name,
			"backpack_slot_id": backpack_slot_id,
		})

	var swap_result: Dictionary = projected_inventory.move_backpack_slot_to_equipment(backpack_slot_id, equipment_slot_name)
	if not bool(swap_result.get("ok", false)):
		return _build_skipped_action_result({
			"consume_turn": false,
			"error": String(swap_result.get("error", "hand_swap_failed")),
			"equipment_slot_name": equipment_slot_name,
			"backpack_slot_id": backpack_slot_id,
		})

	combat_state.apply_inventory_projection(projected_inventory)
	_resolve_active_weapon_definition()
	_sync_mirror_fields_from_runtime_state()
	_emit_player_action_chosen("SwapHand")
	return _build_action_result(false, check_combat_end(), {
		"equipment_slot_name": equipment_slot_name,
		"backpack_slot_id": backpack_slot_id,
		"equipped_definition_id": String(swap_result.get("definition_id", "")),
		"equipped_inventory_family": String(swap_result.get("inventory_family", "")),
		"replaced_definition_id": String(swap_result.get("replaced_definition_id", "")),
	})


func process_use_item(slot_index: int = -1) -> Dictionary:
	if combat_state.combat_ended:
		return _build_ended_action_result()

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_USE_ITEM)
	if not forced_skip_result.is_empty():
		return forced_skip_result

	slot_index = _resolve_requested_consumable_slot_index(slot_index)
	if slot_index < 0 or slot_index >= combat_state.consumable_slots.size():
		return _build_skipped_action_result()

	var slot: Dictionary = combat_state.consumable_slots[slot_index]
	var definition_id: String = String(slot.get("definition_id", ""))
	var current_stack: int = int(slot.get("current_stack", 0))
	if definition_id.is_empty() or current_stack <= 0:
		return _build_skipped_action_result()

	var consumable_definition: Dictionary = _content_loader.load_definition("Consumables", definition_id)
	if consumable_definition.is_empty():
		return _build_skipped_action_result()

	var use_effect: Dictionary = consumable_definition.get("rules", {}).get("use_effect", {})
	var effect_profile: Dictionary = InventoryActionsScript.extract_consumable_use_profile(use_effect)
	var heal_amount: int = int(effect_profile.get("heal_amount", 0))
	var hunger_delta: int = int(effect_profile.get("hunger_delta", 0))
	var repairs_weapon: bool = bool(effect_profile.get("repairs_weapon", false))
	var display: Dictionary = consumable_definition.get("display", {})
	var display_name: String = String(display.get("name", definition_id))
	var previous_hp: int = combat_state.player_hp
	var previous_hunger: int = combat_state.player_hunger
	var previous_durability: int = int(combat_state.weapon_instance.get("current_durability", 0))
	var max_player_hp: int = RunState.DEFAULT_PLAYER_HP
	var missing_hp: int = max_player_hp - previous_hp
	var healed_amount: int = min(heal_amount, missing_hp) if heal_amount > 0 else 0
	var next_hunger: int = previous_hunger
	if hunger_delta < 0:
		next_hunger = int(clamp(previous_hunger - hunger_delta, 0, RunState.DEFAULT_HUNGER))
	var hunger_restored_amount: int = next_hunger - previous_hunger
	var repaired_durability: int = 0
	if repairs_weapon:
		var active_weapon_definition: Dictionary = _resolve_active_weapon_definition()
		var max_durability: int = int(active_weapon_definition.get("rules", {}).get("stats", {}).get("max_durability", previous_durability))
		if max_durability > previous_durability:
			repaired_durability = max_durability - previous_durability
			combat_state.weapon_instance["current_durability"] = max_durability
			combat_state.player_state["weapon_instance"] = combat_state.weapon_instance.duplicate(true)
	if healed_amount <= 0 and hunger_restored_amount <= 0 and repaired_durability <= 0:
		return _build_skipped_action_result()

	if healed_amount > 0:
		combat_state.player_hp = min(max_player_hp, previous_hp + heal_amount)
		combat_state.player_state["hp"] = combat_state.player_hp
	if hunger_restored_amount > 0:
		combat_state.player_hunger = next_hunger
		combat_state.player_state["hunger"] = combat_state.player_hunger

	current_stack -= 1
	if current_stack <= 0:
		combat_state.consumable_slots.remove_at(slot_index)
	else:
		slot["current_stack"] = current_stack
		combat_state.consumable_slots[slot_index] = slot

	combat_state.player_state["consumable_slots"] = combat_state.consumable_slots.duplicate(true)

	var result: Dictionary = {
		"skipped": false,
		"definition_id": definition_id,
		"display_name": display_name,
		"healed_amount": healed_amount,
		"hunger_restored_amount": hunger_restored_amount,
		"hunger_reduced_amount": hunger_restored_amount,
		"repaired_durability": repaired_durability,
		"updated_player_state": combat_state.player_state.duplicate(true),
		"combat_ended": check_combat_end(),
		"combat_result": combat_state.combat_result,
	}

	_append_event({
		"type": "consumable_used",
		"definition_id": definition_id,
		"display_name": display_name,
		"healed_amount": healed_amount,
		"hunger_restored_amount": hunger_restored_amount,
		"repaired_durability": repaired_durability,
		"slot_index": slot_index,
	})
	_emit_player_action_chosen("UseItem")
	emit_signal("domain_event_emitted", "ConsumableUsed", {
		"definition_id": definition_id,
		"display_name": display_name,
		"healed_amount": healed_amount,
		"hunger_restored_amount": hunger_restored_amount,
		"hunger_reduced_amount": hunger_restored_amount,
		"repaired_durability": repaired_durability,
		"remaining_stack": current_stack,
	})
	return result


func resolve_defend_turn() -> Dictionary:
	return _resolve_full_turn(ACTION_DEFEND)


func process_defend() -> Dictionary:
	if combat_state.combat_ended:
		return _build_ended_action_result()

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_DEFEND)
	if not forced_skip_result.is_empty():
		return forced_skip_result

	var defend_result: Dictionary = _resolver.resolve_player_defend(combat_state.build_effective_player_state())
	_merge_player_runtime_fields(defend_result.get("updated_player_state", {}))
	_sync_mirror_fields_from_runtime_state()
	_append_event({
		"type": "guard_raised",
		"turn": combat_state.current_turn,
		"guard_points": int(defend_result.get("guard_generated", 0)),
	})
	_emit_player_action_chosen("Defend")
	var extra_hunger_cost: int = CombatResolver.resolve_defend_extra_hunger_cost()
	var turn_hunger_cost: int = CombatResolver.resolve_defend_turn_hunger_cost()
	_pending_turn_hunger_cost = turn_hunger_cost
	emit_signal("domain_event_emitted", "GuardGained", {
		"turn": combat_state.current_turn,
		"guard_points": int(defend_result.get("guard_generated", 0)),
		"shield_bonus_applied": bool(defend_result.get("shield_bonus_applied", false)),
		"dual_wield_penalty_applied": bool(defend_result.get("dual_wield_penalty_applied", false)),
		"extra_hunger_cost": extra_hunger_cost,
		"turn_hunger_cost": turn_hunger_cost,
	})
	return _build_action_result(false, check_combat_end(), {
		"guard_generated": int(defend_result.get("guard_generated", 0)),
		"guard_points": combat_state.current_guard,
		"shield_bonus_applied": bool(defend_result.get("shield_bonus_applied", false)),
		"dual_wield_penalty_applied": bool(defend_result.get("dual_wield_penalty_applied", false)),
		"extra_hunger_cost": extra_hunger_cost,
		"turn_hunger_cost": turn_hunger_cost,
	})


func process_turn_end(hunger_cost: int = -1) -> Dictionary:
	var retained_guard: int = CombatResolver.resolve_turn_end_guard_carryover(
		int(combat_state.player_state.get("guard_points", combat_state.current_guard))
	)
	combat_state.player_state["guard_points"] = retained_guard
	combat_state.current_guard = retained_guard
	var status_summary: Dictionary = combat_state.resolve_player_turn_end_statuses()
	_emit_status_turn_end_events(status_summary)
	_sync_mirror_fields_from_runtime_state()
	var resolved_hunger_cost: int = hunger_cost
	if resolved_hunger_cost < 0:
		resolved_hunger_cost = _pending_turn_hunger_cost
		if resolved_hunger_cost < 0:
			resolved_hunger_cost = CombatResolver.resolve_base_turn_hunger_cost()
	_pending_turn_hunger_cost = -1

	if check_combat_end():
		return _build_turn_end_summary(status_summary, true, max(0, resolved_hunger_cost))

	resolved_hunger_cost = max(0, resolved_hunger_cost)
	CombatResolver.apply_turn_end_hunger_tick(combat_state, resolved_hunger_cost)
	CombatResolver.apply_hunger_penalty(combat_state)
	CombatResolver.advance_turn(combat_state)
	var phase_change: Dictionary = CombatResolver.advance_intent(combat_state)
	if bool(phase_change.get("changed", false)):
		_emit_boss_phase_changed(phase_change)
	_sync_mirror_fields_from_runtime_state()

	var turn_end_summary: Dictionary = _build_turn_end_summary(status_summary, false, resolved_hunger_cost)

	_append_event({
		"type": "turn_end_resolved",
		"player_hp": combat_state.player_hp,
		"player_hunger": combat_state.player_hunger,
		"current_turn": combat_state.current_turn,
	})
	_emit_revealed_intent_if_present()
	return _finalize_turn_end_summary(turn_end_summary)


func check_combat_end() -> bool:
	if combat_state.combat_ended:
		return true

	var player_defeated: bool = _resolver.check_defeat(combat_state.player_state)
	if player_defeated:
		return _finish_combat("defeat", false)

	var enemy_defeated: bool = _resolver.check_defeat(combat_state.enemy_state)
	if enemy_defeated:
		return _finish_combat("victory", true)

	return false


func get_current_intent() -> Dictionary:
	return combat_state.current_intent.duplicate(true)

func build_preview_snapshot() -> Dictionary:
	if combat_state == null:
		return {}

	var effective_player_state: Dictionary = combat_state.build_effective_player_state()
	effective_player_state["random_roll_percent"] = 100
	effective_player_state["queued_attack_multiplier"] = max(1, int(combat_state.queued_attack_multiplier))
	effective_player_state["player_status_count"] = combat_state.player_statuses.size()
	var active_weapon_definition: Dictionary = _resolve_active_weapon_definition()
	var attack_result: Dictionary = _resolver.resolve_player_attack_with_context(
		effective_player_state,
		combat_state.enemy_state,
		active_weapon_definition,
		{"damage_multiplier": max(1, int(combat_state.queued_attack_multiplier))}
	)
	var enemy_result: Dictionary = _resolver.resolve_enemy_action(
		combat_state.enemy_state,
		effective_player_state,
		combat_state.current_intent
	)
	var defend_result: Dictionary = _resolver.resolve_player_defend(effective_player_state)
	var defend_preview_state: Dictionary = defend_result.get("updated_player_state", effective_player_state.duplicate(true))
	var defend_enemy_result: Dictionary = _resolver.resolve_enemy_action(
		combat_state.enemy_state,
		defend_preview_state,
		combat_state.current_intent
	)
	var current_durability: int = int(combat_state.weapon_instance.get("current_durability", 0))
	var next_weapon_state: Dictionary = attack_result.get("updated_weapon_state", attack_result.get("weapon_instance", {}))
	var next_durability: int = int(next_weapon_state.get("current_durability", current_durability))
	var updated_enemy_preview_state: Dictionary = attack_result.get("updated_defender_state", {})
	var technique_preview: Dictionary = _build_technique_preview_snapshot(effective_player_state)

	return {
		"attack_damage_preview": int(attack_result.get("damage_applied", 0)),
		"attack_dodge_chance": int(attack_result.get("dodge_chance", 0)),
		"uses_fallback_attack": bool(attack_result.get("used_fallback_attack", false)),
		"durability_spend_preview": max(0, current_durability - next_durability),
		"enemy_defense_preview": int(updated_enemy_preview_state.get("incoming_damage_flat_reduction", 0)),
		"defense_preview": int(effective_player_state.get("incoming_damage_flat_reduction", 0)),
		"incoming_damage_preview": int(enemy_result.get("damage_applied", 0)),
		"guard_gain_preview": int(defend_result.get("guard_generated", 0)),
		"guard_absorb_preview": int(defend_enemy_result.get("guard_absorbed", 0)),
		"guard_damage_preview": int(defend_enemy_result.get("damage_applied", 0)),
		"hunger_tick_preview": CombatResolver.resolve_base_turn_hunger_cost(),
		"defend_hunger_cost_preview": CombatResolver.resolve_defend_turn_hunger_cost(),
	}.merged(technique_preview, true)

func get_hand_swap_candidates(equipment_slot_name: String) -> Array[Dictionary]:
	if not _is_supported_hand_swap_slot(equipment_slot_name):
		return []
	var projected_inventory: InventoryState = _build_projected_inventory_state()
	return _build_hand_swap_candidate_slots(projected_inventory, equipment_slot_name)


func has_hand_swap_candidates(equipment_slot_name: String) -> bool:
	return not get_hand_swap_candidates(equipment_slot_name).is_empty()


func has_any_hand_swap_candidates() -> bool:
	return (
		has_hand_swap_candidates(InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND)
		or has_hand_swap_candidates(InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND)
	)


func _resolve_full_turn(action_name: String, action_payload: Variant = null) -> Dictionary:
	var action_result: Dictionary = _resolve_player_action(action_name, action_payload)
	emit_signal("turn_phase_resolved", PHASE_PLAYER_ACTION, action_name, action_result)

	var turn_result: Dictionary = {
		"action_name": action_name,
		"action_result": action_result,
		"combat_ended": bool(action_result.get("combat_ended", combat_state.combat_ended)),
		"combat_result": String(action_result.get("combat_result", combat_state.combat_result)),
	}
	if bool(action_result.get("combat_ended", false)):
		return turn_result
	if bool(action_result.get("skipped", false)) and not bool(action_result.get("consume_turn", false)):
		return turn_result

	var enemy_result: Dictionary = process_enemy_action()
	turn_result["enemy_result"] = enemy_result
	turn_result["combat_ended"] = bool(enemy_result.get("combat_ended", combat_state.combat_ended))
	turn_result["combat_result"] = String(enemy_result.get("combat_result", combat_state.combat_result))
	emit_signal("turn_phase_resolved", PHASE_ENEMY_ACTION, action_name, enemy_result)
	if bool(enemy_result.get("combat_ended", false)):
		return turn_result

	var turn_end_hunger_cost: int = int(action_result.get("turn_hunger_cost", CombatResolver.resolve_base_turn_hunger_cost()))
	var turn_end_result: Dictionary = process_turn_end(turn_end_hunger_cost)
	turn_result["turn_end_result"] = turn_end_result
	turn_result["combat_ended"] = bool(turn_end_result.get("combat_ended", combat_state.combat_ended))
	turn_result["combat_result"] = String(turn_end_result.get("combat_result", combat_state.combat_result))
	emit_signal("turn_phase_resolved", PHASE_TURN_END, action_name, turn_end_result)
	return turn_result


func _resolve_player_action(action_name: String, action_payload: Variant = null) -> Dictionary:
	match action_name:
		ACTION_ATTACK:
			return process_player_attack()
		ACTION_DEFEND:
			return process_defend()
		ACTION_TECHNIQUE:
			return process_technique()
		ACTION_USE_ITEM:
			var requested_slot_index: int = int(action_payload) if typeof(action_payload) == TYPE_INT else -1
			return process_use_item(requested_slot_index)
		ACTION_SWAP_HAND:
			if typeof(action_payload) != TYPE_DICTIONARY:
				return _build_skipped_action_result({
					"consume_turn": false,
					"error": "missing_hand_swap_payload",
				})
			var payload: Dictionary = action_payload
			return process_swap_hand(
				String(payload.get("equipment_slot_name", "")),
				int(payload.get("backpack_slot_id", -1))
			)
		_:
			return {
				"skipped": true,
				"combat_ended": combat_state.combat_ended,
				"combat_result": combat_state.combat_result,
				"consume_turn": false,
				"error": "unknown_player_action",
				"action_name": action_name,
			}


func _build_technique_preview_snapshot(effective_player_state: Dictionary) -> Dictionary:
	if not has_equipped_technique():
		return {
			"has_equipped_technique": false,
		}

	var active_weapon_definition: Dictionary = _resolve_active_weapon_definition()
	var technique_definition: Dictionary = combat_state.equipped_technique_definition
	var display: Dictionary = technique_definition.get("display", {})
	var rules: Dictionary = technique_definition.get("rules", {})
	var effect: Dictionary = rules.get("effect", {})
	var effect_type: String = String(effect.get("type", "")).strip_edges()
	var params: Dictionary = effect.get("params", {})
	var preview: Dictionary = {
		"has_equipped_technique": true,
		"technique_definition_id": String(combat_state.equipped_technique_definition_id),
		"technique_display_name": String(display.get("name", combat_state.equipped_technique_definition_id)),
		"technique_short_description": String(display.get("short_description", "")),
		"technique_effect_type": effect_type,
		"technique_spent": bool(combat_state.technique_spent),
		"technique_available": is_technique_available(),
		"technique_unavailable_reason": _resolve_technique_unavailable_reason(),
		"queued_attack_multiplier": max(1, int(combat_state.queued_attack_multiplier)),
	}

	match effect_type:
		"remove_statuses":
			preview["technique_removed_status_count"] = combat_state.player_statuses.size()
			preview["technique_guard_gain_preview"] = max(0, int(params.get("guard_gain", 0)))
		"attack_ignore_armor":
			var ignore_armor_result: Dictionary = _resolver.resolve_player_attack_with_context(
				effective_player_state,
				combat_state.enemy_state,
				active_weapon_definition,
				{"ignore_armor": true}
			)
			preview["technique_damage_preview"] = int(ignore_armor_result.get("damage_applied", 0))
			preview["technique_ignores_armor"] = true
		"attack_lifesteal":
			var lifesteal_result: Dictionary = _resolver.resolve_player_attack_with_context(
				effective_player_state,
				combat_state.enemy_state,
				active_weapon_definition,
				{"heal_ratio_percent": int(params.get("heal_ratio_percent", 0))}
			)
			preview["technique_damage_preview"] = int(lifesteal_result.get("damage_applied", 0))
			preview["technique_heal_preview"] = int(lifesteal_result.get("healed_amount", 0))
		"prime_next_attack":
			preview["technique_attack_multiplier_preview"] = max(1, int(params.get("damage_multiplier", 2)))

	return preview


func has_equipped_technique() -> bool:
	return combat_state != null and combat_state.has_equipped_technique()


func is_technique_available() -> bool:
	if not has_equipped_technique():
		return false
	if combat_state.technique_spent:
		return false
	var effect_type: String = String(
		combat_state.equipped_technique_definition.get("rules", {}).get("effect", {}).get("type", "")
	).strip_edges()
	if effect_type == "remove_statuses":
		return not combat_state.player_statuses.is_empty()
	return true


func _resolve_technique_unavailable_reason() -> String:
	if not has_equipped_technique():
		return "missing_equipped_technique"
	if combat_state.technique_spent:
		return "technique_spent"
	var effect_type: String = String(
		combat_state.equipped_technique_definition.get("rules", {}).get("effect", {}).get("type", "")
	).strip_edges()
	if effect_type == "remove_statuses" and combat_state.player_statuses.is_empty():
		return "no_statuses_to_cleanse"
	return ""


func _build_forced_skip_result(action_name: String) -> Dictionary:
	var effective_player_state: Dictionary = combat_state.build_effective_player_state()
	if int(effective_player_state.get("skip_player_action", 0)) <= 0:
		return {}

	var result: Dictionary = {
		"skipped": true,
		"consume_turn": true,
		"skipped_reason": "stunned",
		"action_name": action_name,
		"combat_ended": check_combat_end(),
		"combat_result": combat_state.combat_result,
	}
	_append_event({
		"type": "player_action_skipped",
		"reason": "stunned",
		"action_name": action_name,
		"turn": combat_state.current_turn,
	})
	return result


func _build_action_result(skipped: bool, combat_ended: bool, extra: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {
		"skipped": skipped,
		"combat_ended": combat_ended,
		"combat_result": combat_state.combat_result,
	}
	return result.merged(extra, true)


func _build_ended_action_result() -> Dictionary:
	return _build_action_result(true, true)


func _build_skipped_action_result(extra: Dictionary = {}) -> Dictionary:
	return _build_action_result(true, false, extra)


func _finalize_action_result(result: Dictionary) -> Dictionary:
	result["combat_ended"] = check_combat_end()
	result["combat_result"] = combat_state.combat_result
	return result


func _emit_player_action_chosen(action_name: String) -> void:
	emit_signal("domain_event_emitted", "PlayerActionChosen", {
		"action": action_name,
		"turn": combat_state.current_turn,
	})


func _build_turn_end_summary(status_summary: Dictionary, combat_ended: bool = false, hunger_spent: int = 0) -> Dictionary:
	return {
		"player_hp": combat_state.player_hp,
		"player_hunger": combat_state.player_hunger,
		"hunger_spent": max(0, hunger_spent),
		"guard_points": combat_state.current_guard,
		"current_turn": combat_state.current_turn,
		"current_intent": combat_state.current_intent.duplicate(true),
		"status_summary": status_summary,
		"combat_ended": combat_ended,
		"combat_result": combat_state.combat_result,
	}


func _finalize_turn_end_summary(turn_end_summary: Dictionary) -> Dictionary:
	turn_end_summary["combat_ended"] = check_combat_end()
	turn_end_summary["combat_result"] = combat_state.combat_result
	return turn_end_summary


func _commit_combat_to_run_state() -> void:
	if _run_state == null:
		return
	_run_state.commit_combat_result(combat_state)


func _finish_combat(result: String, emit_enemy_defeated: bool) -> bool:
	combat_state.combat_ended = true
	combat_state.combat_result = result
	_commit_combat_to_run_state()
	if emit_enemy_defeated:
		emit_signal("domain_event_emitted", "EnemyDefeated", {})
	emit_signal("combat_ended_signal", combat_state.combat_result)
	return true


func _consume_resolver_output(result: Dictionary) -> void:
	var updated_attacker_state: Variant = result.get("updated_attacker_state", null)
	if typeof(updated_attacker_state) == TYPE_DICTIONARY:
		var attacker_state: Dictionary = updated_attacker_state
		_merge_player_runtime_fields(attacker_state)

	var updated_player_state: Variant = result.get("updated_player_state", null)
	if typeof(updated_player_state) == TYPE_DICTIONARY:
		var player_state: Dictionary = updated_player_state
		_merge_player_runtime_fields(player_state)

	var updated_defender_state: Variant = result.get("updated_defender_state", null)
	if typeof(updated_defender_state) == TYPE_DICTIONARY:
		var defender_state: Dictionary = updated_defender_state
		combat_state.enemy_state = defender_state.duplicate(true)

	var updated_enemy_state: Variant = result.get("updated_enemy_state", null)
	if typeof(updated_enemy_state) == TYPE_DICTIONARY:
		var enemy_state: Dictionary = updated_enemy_state
		combat_state.enemy_state = enemy_state.duplicate(true)

	var updated_player_statuses: Variant = result.get("updated_player_statuses", null)
	if typeof(updated_player_statuses) == TYPE_ARRAY:
		var statuses: Array = updated_player_statuses
		var typed_statuses: Array[Dictionary] = []
		for status_value in statuses:
			if typeof(status_value) != TYPE_DICTIONARY:
				continue
			typed_statuses.append((status_value as Dictionary).duplicate(true))
		combat_state.player_statuses = typed_statuses

	var updated_weapon_state: Variant = result.get("updated_weapon_state", null)
	if typeof(updated_weapon_state) == TYPE_DICTIONARY:
		var weapon_state: Dictionary = updated_weapon_state
		combat_state.weapon_instance = weapon_state.duplicate(true)
		combat_state.player_state["weapon_instance"] = combat_state.weapon_instance.duplicate(true)

	_append_events(result.get("events", []))
	_sync_mirror_fields_from_runtime_state()
	_emit_event_signals_from_result(result)


func _sync_mirror_fields_from_runtime_state() -> void:
	combat_state.player_hp = int(combat_state.player_state.get("hp", combat_state.player_hp))
	combat_state.player_hunger = clamp(
		int(combat_state.player_state.get("hunger", combat_state.player_hunger)),
		0,
		RunState.DEFAULT_HUNGER
	)
	combat_state.enemy_hp = int(combat_state.enemy_state.get("hp", combat_state.enemy_hp))

	var weapon_variant: Variant = combat_state.player_state.get("weapon_instance", combat_state.weapon_instance)
	if typeof(weapon_variant) == TYPE_DICTIONARY:
		var weapon_state: Dictionary = weapon_variant
		combat_state.weapon_instance = weapon_state.duplicate(true)

	var left_hand_variant: Variant = combat_state.player_state.get("left_hand_instance", combat_state.left_hand_instance)
	if typeof(left_hand_variant) == TYPE_DICTIONARY:
		var left_hand_state: Dictionary = left_hand_variant
		combat_state.left_hand_instance = left_hand_state.duplicate(true)

	var consumable_variant: Variant = combat_state.player_state.get("consumable_slots", combat_state.consumable_slots)
	if typeof(consumable_variant) == TYPE_ARRAY:
		var consumable_array: Array = consumable_variant
		combat_state.consumable_slots = consumable_array.duplicate(true)

	combat_state.current_guard = max(0, int(combat_state.player_state.get("guard_points", combat_state.current_guard)))
	combat_state.technique_spent = bool(combat_state.player_state.get("technique_spent", combat_state.technique_spent))
	combat_state.queued_attack_multiplier = max(1, int(combat_state.player_state.get("queued_attack_multiplier", combat_state.queued_attack_multiplier)))


func _append_events(events_variant: Variant) -> void:
	if typeof(events_variant) != TYPE_ARRAY:
		return

	var events: Array = events_variant
	for event_value in events:
		if typeof(event_value) != TYPE_DICTIONARY:
			continue
		var event_dict: Dictionary = event_value
		_append_event(event_dict)


func _append_event(event_dict: Dictionary) -> void:
	combat_state.event_log.append(event_dict.duplicate(true))


func _emit_revealed_intent_if_present() -> void:
	if combat_state.current_intent.is_empty():
		return
	emit_signal("domain_event_emitted", "EnemyIntentRevealed", {
		"intent": combat_state.current_intent.duplicate(true),
	})


func _emit_boss_phase_changed(phase_change: Dictionary) -> void:
	_append_event({
		"type": "boss_phase_changed",
		"phase_id": String(phase_change.get("phase_id", "")),
		"display_name": String(phase_change.get("display_name", "")),
		"phase_index": int(phase_change.get("phase_index", -1)),
		"threshold_percent": int(phase_change.get("threshold_percent", 100)),
	})
	emit_signal("domain_event_emitted", "BossPhaseChanged", {
		"enemy_definition_id": String(_enemy_definition.get("definition_id", "")),
		"phase_id": String(phase_change.get("phase_id", "")),
		"display_name": String(phase_change.get("display_name", "")),
		"phase_index": int(phase_change.get("phase_index", -1)),
		"threshold_percent": int(phase_change.get("threshold_percent", 100)),
		"turn": combat_state.current_turn,
	})


func _emit_event_signals_from_result(result: Dictionary) -> void:
	if result.has("damage_applied"):
		var target: String = "enemy"
		if result.has("updated_player_state") and not result.has("updated_defender_state"):
			target = "player"
		emit_signal("domain_event_emitted", "DamageApplied", {
			"target": target,
			"amount": int(result.get("damage_applied", 0)),
		})

	if result.has("updated_weapon_state"):
		emit_signal("domain_event_emitted", "DurabilityReduced", {
			"definition_id": String(combat_state.weapon_instance.get("definition_id", "")),
			"current_durability": int(combat_state.weapon_instance.get("current_durability", 0)),
		})

	if bool(result.get("weapon_broke", false)):
		emit_signal("domain_event_emitted", "WeaponBroken", {
			"definition_id": String(combat_state.weapon_instance.get("definition_id", "")),
		})

	if int(result.get("guard_absorbed", 0)) > 0:
		emit_signal("domain_event_emitted", "GuardAbsorbed", {
			"raw_damage": int(result.get("raw_damage", 0)),
			"armor_reduction_applied": int(result.get("armor_reduction_applied", 0)),
			"guard_absorbed": int(result.get("guard_absorbed", 0)),
			"guard_remaining": int(result.get("guard_remaining", 0)),
			"hp_damage": int(result.get("damage_applied", 0)),
		})


func _merge_player_runtime_fields(updated_state: Dictionary) -> void:
	if updated_state.has("hp"):
		combat_state.player_state["hp"] = int(updated_state.get("hp", combat_state.player_state.get("hp", 0)))
	if updated_state.has("hunger"):
		combat_state.player_state["hunger"] = int(updated_state.get("hunger", combat_state.player_state.get("hunger", 0)))
	if updated_state.has("guard_points"):
		combat_state.player_state["guard_points"] = max(0, int(updated_state.get("guard_points", combat_state.player_state.get("guard_points", 0))))

	var left_hand_variant: Variant = updated_state.get("left_hand_instance", null)
	if typeof(left_hand_variant) == TYPE_DICTIONARY:
		var left_hand_state: Dictionary = left_hand_variant
		combat_state.player_state["left_hand_instance"] = left_hand_state.duplicate(true)

	var weapon_variant: Variant = updated_state.get("weapon_instance", null)
	if typeof(weapon_variant) == TYPE_DICTIONARY:
		var weapon_state: Dictionary = weapon_variant
		combat_state.player_state["weapon_instance"] = weapon_state.duplicate(true)

	var consumable_variant: Variant = updated_state.get("consumable_slots", null)
	if typeof(consumable_variant) == TYPE_ARRAY:
		var consumable_slots: Array = consumable_variant
		combat_state.player_state["consumable_slots"] = consumable_slots.duplicate(true)
	if updated_state.has("technique_spent"):
		combat_state.player_state["technique_spent"] = bool(updated_state.get("technique_spent", combat_state.player_state.get("technique_spent", false)))
	if updated_state.has("queued_attack_multiplier"):
		combat_state.player_state["queued_attack_multiplier"] = max(1, int(updated_state.get("queued_attack_multiplier", combat_state.player_state.get("queued_attack_multiplier", 1))))


func find_first_usable_consumable_slot_index() -> int:
	for index in range(combat_state.consumable_slots.size()):
		if _is_consumable_slot_usable(index):
			return index
	return -1


func is_consumable_slot_usable(slot_index: int) -> bool:
	return _is_consumable_slot_usable(slot_index)


func _resolve_requested_consumable_slot_index(slot_index: int) -> int:
	if slot_index >= 0:
		return slot_index
	return find_first_usable_consumable_slot_index()


func _is_consumable_slot_usable(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= combat_state.consumable_slots.size():
		return false

	var slot: Dictionary = combat_state.consumable_slots[slot_index]
	var definition_id: String = String(slot.get("definition_id", ""))
	var current_stack: int = int(slot.get("current_stack", 0))
	if definition_id.is_empty() or current_stack <= 0:
		return false

	var consumable_definition: Dictionary = _content_loader.load_definition("Consumables", definition_id)
	if consumable_definition.is_empty():
		return false

	var effect_profile: Dictionary = InventoryActionsScript.extract_consumable_use_profile(
		consumable_definition.get("rules", {}).get("use_effect", {})
	)
	var heal_amount: int = int(effect_profile.get("heal_amount", 0))
	var hunger_delta: int = int(effect_profile.get("hunger_delta", 0))
	var repairs_weapon: bool = bool(effect_profile.get("repairs_weapon", false))
	var missing_hp: int = RunState.DEFAULT_PLAYER_HP - combat_state.player_hp
	if heal_amount > 0 and missing_hp > 0:
		return true
	if hunger_delta < 0 and combat_state.player_hunger < RunState.DEFAULT_HUNGER:
		return true
	if repairs_weapon:
		var current_durability: int = int(combat_state.weapon_instance.get("current_durability", 0))
		var active_weapon_definition: Dictionary = _resolve_active_weapon_definition()
		var max_durability: int = int(active_weapon_definition.get("rules", {}).get("stats", {}).get("max_durability", current_durability))
		if max_durability > current_durability:
			return true
	return false


func _resolve_active_weapon_definition() -> Dictionary:
	if combat_state == null:
		return _weapon_definition
	var definition_id: String = String(combat_state.weapon_instance.get("definition_id", "")).strip_edges()
	if definition_id.is_empty():
		_weapon_definition = {}
		return _weapon_definition
	if String(_weapon_definition.get("definition_id", "")).strip_edges() == definition_id:
		return _weapon_definition
	var resolved_definition: Dictionary = _content_loader.load_definition("Weapons", definition_id)
	_weapon_definition = resolved_definition.duplicate(true) if not resolved_definition.is_empty() else {}
	return _weapon_definition


func _build_projected_inventory_state() -> InventoryState:
	if _run_state == null or _run_state.inventory_state == null:
		return null
	return combat_state.build_inventory_projection(_run_state.inventory_state)


func _build_hand_swap_candidate_slots(projected_inventory: InventoryState, equipment_slot_name: String) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if projected_inventory == null or not _is_supported_hand_swap_slot(equipment_slot_name):
		return candidates
	for slot_value in projected_inventory.inventory_slots:
		if typeof(slot_value) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_value
		if not _slot_is_valid_hand_swap_candidate(projected_inventory, slot, equipment_slot_name):
			continue
		candidates.append(slot.duplicate(true))
	return candidates


func _slot_is_valid_hand_swap_candidate(projected_inventory: InventoryState, slot: Dictionary, equipment_slot_name: String) -> bool:
	if projected_inventory == null or slot.is_empty() or not _is_supported_hand_swap_slot(equipment_slot_name):
		return false
	var slot_id: int = int(slot.get("slot_id", -1))
	if slot_id <= 0:
		return false
	return projected_inventory.slot_can_equip_to(slot, equipment_slot_name)


func _is_supported_hand_swap_slot(equipment_slot_name: String) -> bool:
	return equipment_slot_name in [
		InventoryStateScript.EQUIPMENT_SLOT_RIGHT_HAND,
		InventoryStateScript.EQUIPMENT_SLOT_LEFT_HAND,
	]


func _apply_status_effects_from_enemy_intent(intent: Dictionary) -> Array[Dictionary]:
	var applied_statuses: Array[Dictionary] = []
	var intent_effects: Variant = intent.get("effects", [])
	if typeof(intent_effects) != TYPE_ARRAY:
		return applied_statuses

	for effect_value in intent_effects:
		if typeof(effect_value) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_value
		if String(effect.get("type", "")) != "apply_status":
			continue

		var params_value: Variant = effect.get("params", {})
		if typeof(params_value) != TYPE_DICTIONARY:
			continue
		var params: Dictionary = params_value
		var status_definition_id: String = String(params.get("definition_id", ""))
		if status_definition_id.is_empty():
			continue

		var status_definition: Dictionary = _content_loader.load_definition("Statuses", status_definition_id)
		if status_definition.is_empty():
			continue

		var applied_status: Dictionary = combat_state.apply_player_status_definition(
			status_definition,
			int(params.get("duration_turns", 0)),
			int(params.get("stacks", 1))
		)
		if applied_status.is_empty():
			continue

		applied_statuses.append(applied_status.duplicate(true))
		_append_event({
			"type": "status_applied",
			"target": "player",
			"definition_id": String(applied_status.get("definition_id", "")),
			"remaining_turns": int(applied_status.get("remaining_turns", 0)),
			"refreshed": bool(applied_status.get("refreshed", false)),
		})
		emit_signal("domain_event_emitted", "StatusApplied", {
			"target": "player",
			"definition_id": String(applied_status.get("definition_id", "")),
			"display_name": String(applied_status.get("display_name", "")),
			"remaining_turns": int(applied_status.get("remaining_turns", 0)),
			"refreshed": bool(applied_status.get("refreshed", false)),
		})

	return applied_statuses


func _emit_status_turn_end_events(status_summary: Dictionary) -> void:
	var ticked_statuses: Variant = status_summary.get("ticked_statuses", [])
	if typeof(ticked_statuses) == TYPE_ARRAY:
		for status_value in ticked_statuses:
			if typeof(status_value) != TYPE_DICTIONARY:
				continue
			var status_dict: Dictionary = status_value
			_append_event({
				"type": "status_ticked",
				"target": "player",
				"definition_id": String(status_dict.get("definition_id", "")),
				"damage_applied": int(status_dict.get("damage_applied", 0)),
				"remaining_turns": int(status_dict.get("remaining_turns", 0)),
			})
			emit_signal("domain_event_emitted", "StatusTicked", {
				"target": "player",
				"definition_id": String(status_dict.get("definition_id", "")),
				"display_name": String(status_dict.get("display_name", "")),
				"damage_applied": int(status_dict.get("damage_applied", 0)),
				"remaining_turns": int(status_dict.get("remaining_turns", 0)),
			})

	var expired_statuses: Variant = status_summary.get("expired_definition_ids", PackedStringArray())
	if typeof(expired_statuses) == TYPE_PACKED_STRING_ARRAY:
		var expired_ids: PackedStringArray = expired_statuses
		for definition_id in expired_ids:
			_append_event({
				"type": "status_expired",
				"target": "player",
				"definition_id": definition_id,
			})
			emit_signal("domain_event_emitted", "StatusExpired", {
				"target": "player",
				"definition_id": definition_id,
			})

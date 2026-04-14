# Layer: Application
extends RefCounted
class_name CombatFlow

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")
const InventoryActionsScript = preload("res://Game/Application/inventory_actions.gd")

signal domain_event_emitted(event_name: String, payload: Dictionary)
signal combat_ended_signal(result: String)
signal turn_phase_resolved(phase_name: String, action_name: String, result: Dictionary)

const ACTION_ATTACK: String = "attack"
const ACTION_BRACE: String = "brace"
const ACTION_USE_ITEM: String = "use_item"
const ACTION_CHANGE_EQUIPMENT: String = "change_equipment"

const PHASE_PLAYER_ACTION: String = "player_action"
const PHASE_ENEMY_ACTION: String = "enemy_action"
const PHASE_TURN_END: String = "turn_end"

var combat_state: CombatState = CombatState.new()

var _resolver: CombatResolver
var _run_state: RunState
var _enemy_definition: Dictionary = {}
var _weapon_definition: Dictionary = {}
var _content_loader: ContentLoader = ContentLoaderScript.new()
var _inventory_actions: InventoryActions = InventoryActionsScript.new()


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

	emit_signal("domain_event_emitted", "CombatStarted", {
		"enemy_definition_id": String(_enemy_definition.get("definition_id", "")),
		"encounter_node_family": String(combat_state.encounter_node_family),
		"is_boss_combat": bool(combat_state.is_boss_combat),
		"boss_phase_id": String(combat_state.boss_phase_id),
		"boss_phase_display_name": String(combat_state.boss_phase_display_name),
		"current_turn": combat_state.current_turn,
	})

	if not combat_state.current_intent.is_empty():
		emit_signal("domain_event_emitted", "EnemyIntentRevealed", {
			"intent": combat_state.current_intent.duplicate(true),
		})

	return combat_state


func process_player_attack() -> Dictionary:
	if combat_state.combat_ended:
		return {
			"skipped": true,
			"combat_ended": true,
			"combat_result": combat_state.combat_result,
		}

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_ATTACK)
	if not forced_skip_result.is_empty():
		return forced_skip_result

	var effective_player_state: Dictionary = combat_state.build_effective_player_state()
	effective_player_state["random_roll_percent"] = int(effective_player_state.get("random_roll_percent", 100))
	var result: Dictionary = _resolver.resolve_player_attack(
		effective_player_state,
		combat_state.enemy_state,
		_weapon_definition
	)

	_consume_resolver_output(result)
	emit_signal("domain_event_emitted", "PlayerActionChosen", {
		"action": "Attack",
		"turn": combat_state.current_turn,
	})

	result["combat_ended"] = check_combat_end()
	result["combat_result"] = combat_state.combat_result
	return result


func resolve_attack_turn() -> Dictionary:
	return _resolve_full_turn(ACTION_ATTACK)


func process_enemy_action() -> Dictionary:
	if check_combat_end():
		return {
			"skipped": true,
			"combat_ended": true,
			"combat_result": combat_state.combat_result,
		}

	var result: Dictionary = _resolver.resolve_enemy_action(
		combat_state.enemy_state,
		combat_state.build_effective_player_state(),
		combat_state.current_intent
	)

	_consume_resolver_output(result)
	if not _resolver.check_defeat(combat_state.player_state):
		result["applied_statuses"] = _apply_status_effects_from_enemy_intent(combat_state.current_intent)
	result["combat_ended"] = check_combat_end()
	result["combat_result"] = combat_state.combat_result
	return result


func resolve_use_item_turn(slot_index: int = -1) -> Dictionary:
	return _resolve_full_turn(ACTION_USE_ITEM, slot_index)


func process_use_item(slot_index: int = -1) -> Dictionary:
	if combat_state.combat_ended:
		return {
			"skipped": true,
			"combat_ended": true,
			"combat_result": combat_state.combat_result,
		}

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_USE_ITEM)
	if not forced_skip_result.is_empty():
		return forced_skip_result

	slot_index = _resolve_requested_consumable_slot_index(slot_index)
	if slot_index < 0 or slot_index >= combat_state.consumable_slots.size():
		return {
			"skipped": true,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
		}

	var slot: Dictionary = combat_state.consumable_slots[slot_index]
	var definition_id: String = String(slot.get("definition_id", ""))
	var current_stack: int = int(slot.get("current_stack", 0))
	if definition_id.is_empty() or current_stack <= 0:
		return {
			"skipped": true,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
		}

	var consumable_definition: Dictionary = _content_loader.load_definition("Consumables", definition_id)
	if consumable_definition.is_empty():
		return {
			"skipped": true,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
		}

	var use_effect: Dictionary = consumable_definition.get("rules", {}).get("use_effect", {})
	var effect_profile: Dictionary = _extract_consumable_use_profile(use_effect)
	var heal_amount: int = int(effect_profile.get("heal_amount", 0))
	var hunger_delta: int = int(effect_profile.get("hunger_delta", 0))
	var display: Dictionary = consumable_definition.get("display", {})
	var display_name: String = String(display.get("name", definition_id))
	var previous_hp: int = combat_state.player_hp
	var previous_hunger: int = combat_state.player_hunger
	var max_player_hp: int = RunState.DEFAULT_PLAYER_HP
	var missing_hp: int = max_player_hp - previous_hp
	var healed_amount: int = min(heal_amount, missing_hp) if heal_amount > 0 else 0
	var next_hunger: int = previous_hunger
	if hunger_delta < 0:
		next_hunger = int(clamp(previous_hunger - hunger_delta, 0, RunState.DEFAULT_HUNGER))
	var hunger_restored_amount: int = next_hunger - previous_hunger
	if healed_amount <= 0 and hunger_restored_amount <= 0:
		return {
			"skipped": true,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
		}

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
		"slot_index": slot_index,
	})
	emit_signal("domain_event_emitted", "PlayerActionChosen", {
		"action": "UseItem",
		"turn": combat_state.current_turn,
	})
	emit_signal("domain_event_emitted", "ConsumableUsed", {
		"definition_id": definition_id,
		"display_name": display_name,
		"healed_amount": healed_amount,
		"hunger_restored_amount": hunger_restored_amount,
		"hunger_reduced_amount": hunger_restored_amount,
		"remaining_stack": current_stack,
	})
	return result


func resolve_change_equipment_turn(slot_id: int) -> Dictionary:
	return _resolve_full_turn(ACTION_CHANGE_EQUIPMENT, slot_id)


func process_change_equipment(slot_id: int) -> Dictionary:
	if combat_state.combat_ended:
		return {
			"skipped": true,
			"combat_ended": true,
			"combat_result": combat_state.combat_result,
		}

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_CHANGE_EQUIPMENT)
	if not forced_skip_result.is_empty():
		return forced_skip_result

	if _run_state == null or _run_state.inventory_state == null:
		return {
			"skipped": true,
			"consume_turn": false,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
			"error": "missing_inventory_state",
		}

	var projected_inventory: InventoryState = combat_state.build_inventory_projection(_run_state.inventory_state)
	if projected_inventory == null:
		return {
			"skipped": true,
			"consume_turn": false,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
			"error": "missing_inventory_projection",
		}

	var slot_index: int = projected_inventory.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return {
			"skipped": true,
			"consume_turn": false,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
			"error": "missing_inventory_slot",
			"slot_id": slot_id,
		}

	var slot: Dictionary = projected_inventory.inventory_slots[slot_index]
	var inventory_family: String = String(slot.get("inventory_family", ""))
	var previous_slot_id: int = _get_active_equipped_slot_id(inventory_family)
	if inventory_family not in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		InventoryStateScript.INVENTORY_FAMILY_BELT,
	]:
		return {
			"skipped": true,
			"consume_turn": false,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
			"error": "invalid_equipment_family",
			"slot_id": slot_id,
			"inventory_family": inventory_family,
		}
	var toggle_result: Dictionary = _inventory_actions.toggle_equipment_slot(projected_inventory, slot_id)
	if not bool(toggle_result.get("ok", false)):
		return {
			"skipped": true,
			"consume_turn": false,
			"combat_ended": false,
			"combat_result": combat_state.combat_result,
			"error": String(toggle_result.get("error", "equipment_toggle_failed")),
			"slot_id": slot_id,
			"inventory_family": inventory_family,
		}

	var definition_id: String = String(slot.get("definition_id", ""))
	var display_name: String = _build_inventory_display_name(inventory_family, slot)
	combat_state.apply_inventory_projection(projected_inventory)
	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_WEAPON:
		if bool(toggle_result.get("equipped", false)):
			var next_weapon_definition: Dictionary = _content_loader.load_definition("Weapons", definition_id)
			if not next_weapon_definition.is_empty():
				_weapon_definition = next_weapon_definition
		else:
			_weapon_definition = {}

	var result: Dictionary = {
		"skipped": false,
		"consume_turn": true,
		"slot_id": slot_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"inventory_family": inventory_family,
		"previous_slot_id": previous_slot_id,
		"equipped": bool(toggle_result.get("equipped", false)),
		"updated_player_state": combat_state.player_state.duplicate(true),
		"combat_ended": check_combat_end(),
		"combat_result": combat_state.combat_result,
	}

	_append_event({
		"type": "equipment_changed",
		"turn": combat_state.current_turn,
		"slot_id": slot_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"inventory_family": inventory_family,
		"previous_slot_id": previous_slot_id,
		"equipped": bool(toggle_result.get("equipped", false)),
	})
	emit_signal("domain_event_emitted", "PlayerActionChosen", {
		"action": "ChangeEquipment",
		"turn": combat_state.current_turn,
	})
	emit_signal("domain_event_emitted", "EquipmentChanged", {
		"slot_id": slot_id,
		"definition_id": definition_id,
		"display_name": display_name,
		"inventory_family": inventory_family,
		"previous_slot_id": previous_slot_id,
		"equipped": bool(toggle_result.get("equipped", false)),
	})
	return result


func resolve_brace_turn() -> Dictionary:
	return _resolve_full_turn(ACTION_BRACE)


func process_brace() -> Dictionary:
	if combat_state.combat_ended:
		return {
			"skipped": true,
			"combat_ended": true,
			"combat_result": combat_state.combat_result,
		}

	var forced_skip_result: Dictionary = _build_forced_skip_result(ACTION_BRACE)
	if not forced_skip_result.is_empty():
		return forced_skip_result

	combat_state.player_state["brace_active"] = true
	_sync_mirror_fields_from_runtime_state()
	_append_event({
		"type": "brace_activated",
		"turn": combat_state.current_turn,
	})
	emit_signal("domain_event_emitted", "PlayerActionChosen", {
		"action": "Brace",
		"turn": combat_state.current_turn,
	})
	emit_signal("domain_event_emitted", "BraceActivated", {
		"turn": combat_state.current_turn,
	})
	return {
		"skipped": false,
		"brace_active": true,
		"combat_ended": check_combat_end(),
		"combat_result": combat_state.combat_result,
	}


func process_turn_end() -> Dictionary:
	combat_state.player_state["brace_active"] = false
	var status_summary: Dictionary = combat_state.resolve_player_turn_end_statuses()
	_emit_status_turn_end_events(status_summary)
	_sync_mirror_fields_from_runtime_state()

	if check_combat_end():
		return {
			"player_hp": combat_state.player_hp,
			"player_hunger": combat_state.player_hunger,
			"current_turn": combat_state.current_turn,
			"current_intent": combat_state.current_intent.duplicate(true),
			"status_summary": status_summary,
			"combat_ended": true,
			"combat_result": combat_state.combat_result,
		}

	CombatResolver.apply_turn_end_hunger_tick(combat_state)
	CombatResolver.apply_hunger_penalty(combat_state)
	CombatResolver.advance_turn(combat_state)
	var phase_change: Dictionary = CombatResolver.advance_intent(combat_state)
	if bool(phase_change.get("changed", false)):
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
	_sync_mirror_fields_from_runtime_state()

	var turn_end_summary: Dictionary = {
		"player_hp": combat_state.player_hp,
		"player_hunger": combat_state.player_hunger,
		"current_turn": combat_state.current_turn,
		"current_intent": combat_state.current_intent.duplicate(true),
		"status_summary": status_summary,
	}

	_append_event({
		"type": "turn_end_resolved",
		"player_hp": combat_state.player_hp,
		"player_hunger": combat_state.player_hunger,
		"current_turn": combat_state.current_turn,
	})

	if not combat_state.current_intent.is_empty():
		emit_signal("domain_event_emitted", "EnemyIntentRevealed", {
			"intent": combat_state.current_intent.duplicate(true),
		})

	turn_end_summary["combat_ended"] = check_combat_end()
	turn_end_summary["combat_result"] = combat_state.combat_result
	return turn_end_summary


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
	var attack_result: Dictionary = _resolver.resolve_player_attack(
		effective_player_state,
		combat_state.enemy_state,
		_weapon_definition
	)
	var enemy_result: Dictionary = _resolver.resolve_enemy_action(
		combat_state.enemy_state,
		effective_player_state,
		combat_state.current_intent
	)
	var brace_preview_state: Dictionary = effective_player_state.duplicate(true)
	brace_preview_state["brace_active"] = true
	var brace_result: Dictionary = _resolver.resolve_enemy_action(
		combat_state.enemy_state,
		brace_preview_state,
		combat_state.current_intent
	)
	var current_durability: int = int(combat_state.weapon_instance.get("current_durability", 0))
	var next_weapon_state: Dictionary = attack_result.get("updated_weapon_state", attack_result.get("weapon_instance", {}))
	var next_durability: int = int(next_weapon_state.get("current_durability", current_durability))

	return {
		"attack_damage_preview": int(attack_result.get("damage_applied", 0)),
		"attack_dodge_chance": int(attack_result.get("dodge_chance", 0)),
		"uses_fallback_attack": bool(attack_result.get("used_fallback_attack", false)),
		"durability_spend_preview": max(0, current_durability - next_durability),
		"defense_preview": int(effective_player_state.get("incoming_damage_flat_reduction", 0)),
		"incoming_damage_preview": int(enemy_result.get("damage_applied", 0)),
		"brace_damage_preview": int(brace_result.get("damage_applied", 0)),
		"hunger_tick_preview": 1,
	}


func _resolve_full_turn(action_name: String, slot_index: int = 0) -> Dictionary:
	var action_result: Dictionary = _resolve_player_action(action_name, slot_index)
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

	var turn_end_result: Dictionary = process_turn_end()
	turn_result["turn_end_result"] = turn_end_result
	turn_result["combat_ended"] = bool(turn_end_result.get("combat_ended", combat_state.combat_ended))
	turn_result["combat_result"] = String(turn_end_result.get("combat_result", combat_state.combat_result))
	emit_signal("turn_phase_resolved", PHASE_TURN_END, action_name, turn_end_result)
	return turn_result


func _resolve_player_action(action_name: String, slot_index: int = 0) -> Dictionary:
	match action_name:
		ACTION_ATTACK:
			return process_player_attack()
		ACTION_BRACE:
			return process_brace()
		ACTION_USE_ITEM:
			return process_use_item(slot_index)
		ACTION_CHANGE_EQUIPMENT:
			return process_change_equipment(slot_index)
		_:
			return {
				"skipped": true,
				"combat_ended": combat_state.combat_ended,
				"combat_result": combat_state.combat_result,
				"consume_turn": false,
				"error": "unknown_player_action",
				"action_name": action_name,
			}


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

	var consumable_variant: Variant = combat_state.player_state.get("consumable_slots", combat_state.consumable_slots)
	if typeof(consumable_variant) == TYPE_ARRAY:
		var consumable_array: Array = consumable_variant
		combat_state.consumable_slots = consumable_array.duplicate(true)

	combat_state.brace_active = bool(combat_state.player_state.get("brace_active", combat_state.brace_active))


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

	if bool(result.get("brace_applied", false)):
		emit_signal("domain_event_emitted", "BraceMitigated", {
			"raw_damage": int(result.get("brace_reduced_damage_from", 0)),
			"reduced_damage": int(result.get("damage_applied", 0)),
		})


func _merge_player_runtime_fields(updated_state: Dictionary) -> void:
	if updated_state.has("hp"):
		combat_state.player_state["hp"] = int(updated_state.get("hp", combat_state.player_state.get("hp", 0)))
	if updated_state.has("hunger"):
		combat_state.player_state["hunger"] = int(updated_state.get("hunger", combat_state.player_state.get("hunger", 0)))
	if updated_state.has("brace_active"):
		combat_state.player_state["brace_active"] = bool(updated_state.get("brace_active", combat_state.player_state.get("brace_active", false)))

	var weapon_variant: Variant = updated_state.get("weapon_instance", null)
	if typeof(weapon_variant) == TYPE_DICTIONARY:
		var weapon_state: Dictionary = weapon_variant
		combat_state.player_state["weapon_instance"] = weapon_state.duplicate(true)

	var consumable_variant: Variant = updated_state.get("consumable_slots", null)
	if typeof(consumable_variant) == TYPE_ARRAY:
		var consumable_slots: Array = consumable_variant
		combat_state.player_state["consumable_slots"] = consumable_slots.duplicate(true)


func find_first_usable_consumable_slot_index() -> int:
	for index in range(combat_state.consumable_slots.size()):
		if _is_consumable_slot_usable(index):
			return index
	return -1


func is_consumable_slot_usable(slot_index: int) -> bool:
	return _is_consumable_slot_usable(slot_index)


func reorder_inventory_slot(slot_id: int, target_index: int) -> Dictionary:
	if _run_state == null or _run_state.inventory_state == null:
		return {
			"ok": false,
			"error": "missing_inventory_state",
		}

	var projected_inventory: InventoryState = combat_state.build_inventory_projection(_run_state.inventory_state)
	if projected_inventory == null:
		return {
			"ok": false,
			"error": "missing_inventory_projection",
		}

	var move_result: Dictionary = _inventory_actions.move_slot_to_index(projected_inventory, slot_id, target_index)
	if not bool(move_result.get("ok", false)):
		return move_result

	combat_state.apply_inventory_projection(projected_inventory)
	return move_result


func can_change_equipment_slot(slot_id: int) -> bool:
	if slot_id <= 0 or _run_state == null or _run_state.inventory_state == null:
		return false

	var projected_inventory: InventoryState = combat_state.build_inventory_projection(_run_state.inventory_state)
	if projected_inventory == null:
		return false

	var slot_index: int = projected_inventory.find_slot_index_by_id(slot_id)
	if slot_index < 0:
		return false

	var slot: Dictionary = projected_inventory.inventory_slots[slot_index]
	var inventory_family: String = String(slot.get("inventory_family", ""))
	if inventory_family not in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		InventoryStateScript.INVENTORY_FAMILY_BELT,
	]:
		return false

	if inventory_family == InventoryStateScript.INVENTORY_FAMILY_BELT and _get_active_equipped_slot_id(inventory_family) == slot_id:
		var next_capacity: int = max(0, projected_inventory.get_total_capacity() - InventoryStateScript.BELT_SLOT_CAPACITY_BONUS)
		return projected_inventory.get_used_capacity() <= next_capacity
	return true


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

	var effect_profile: Dictionary = _extract_consumable_use_profile(
		consumable_definition.get("rules", {}).get("use_effect", {})
	)
	var heal_amount: int = int(effect_profile.get("heal_amount", 0))
	var hunger_delta: int = int(effect_profile.get("hunger_delta", 0))
	var missing_hp: int = RunState.DEFAULT_PLAYER_HP - combat_state.player_hp
	if heal_amount > 0 and missing_hp > 0:
		return true
	if hunger_delta < 0 and combat_state.player_hunger < RunState.DEFAULT_HUNGER:
		return true
	return false


func _get_active_equipped_slot_id(inventory_family: String) -> int:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return combat_state.active_weapon_slot_id
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return combat_state.active_armor_slot_id
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return combat_state.active_belt_slot_id
		_:
			return -1


func _build_inventory_display_name(inventory_family: String, slot: Dictionary) -> String:
	var definition_id: String = String(slot.get("definition_id", ""))
	if definition_id.is_empty():
		return ""

	var family_name: String = _resolve_definition_family_name(inventory_family)
	if family_name.is_empty():
		return definition_id

	var definition: Dictionary = _content_loader.load_definition(family_name, definition_id)
	var display_name: String = String(definition.get("display", {}).get("name", definition_id))
	var upgrade_level: int = max(0, int(slot.get("upgrade_level", 0)))
	if inventory_family in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
	] and upgrade_level > 0:
		return "%s +%d" % [display_name, upgrade_level]
	return display_name


func _resolve_definition_family_name(inventory_family: String) -> String:
	match inventory_family:
		InventoryStateScript.INVENTORY_FAMILY_WEAPON:
			return "Weapons"
		InventoryStateScript.INVENTORY_FAMILY_ARMOR:
			return "Armors"
		InventoryStateScript.INVENTORY_FAMILY_BELT:
			return "Belts"
		_:
			return ""


func _extract_consumable_use_profile(use_effect: Dictionary) -> Dictionary:
	if use_effect.is_empty():
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}
	if String(use_effect.get("trigger", "")) != "on_use":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}
	if String(use_effect.get("target", "")) != "self":
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}

	var effects: Variant = use_effect.get("effects", [])
	if typeof(effects) != TYPE_ARRAY:
		return {
			"heal_amount": 0,
			"hunger_delta": 0,
		}

	var heal_amount: int = 0
	var hunger_delta: int = 0
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

	return {
		"heal_amount": heal_amount,
		"hunger_delta": hunger_delta,
	}


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

# Layer: Core
extends RefCounted
class_name CombatResolver

const FALLBACK_ATTACK_DAMAGE: int = 1
const MAX_HUNGER: int = RunState.DEFAULT_HUNGER
const HUNGRY_THRESHOLD: int = 6
const STARVING_THRESHOLD: int = 2
const BASE_DEFEND_GUARD: int = 2
const SHIELD_DEFEND_BONUS: int = 2
const DUAL_WIELD_ATTACK_POWER_BONUS: int = 1
const DUAL_WIELD_DEFEND_GUARD_PENALTY: int = 1
const GUARD_DECAY_RATE: float = 0.75
const WEAPON_DURABILITY_PROFILE_STANDARD: String = "standard"
const WEAPON_DURABILITY_PROFILE_MULTIPLIERS := {
	"sturdy": 0.5,
	"standard": 1.0,
	"fragile": 1.5,
	"heavy": 2.0,
}


func resolve_player_attack(attacker_state: Dictionary, defender_state: Dictionary, weapon_def: Dictionary) -> Dictionary:
	var working_attacker: Dictionary = attacker_state.duplicate(true)
	var working_defender: Dictionary = _prepare_combatant_state(defender_state)
	var original_weapon_instance: Dictionary = _extract_weapon_instance(working_attacker)
	var updated_weapon_instance: Dictionary = original_weapon_instance.duplicate(true)
	var used_fallback_attack: bool = _is_weapon_broken(updated_weapon_instance)
	var base_damage: int = FALLBACK_ATTACK_DAMAGE
	var bonus_damage: int = 0
	var attack_power_bonus: int = (
		int(working_attacker.get("attack_power_bonus", 0))
		+ _resolve_attack_power_bonus(working_attacker)
		+ _resolve_dual_wield_attack_bonus(working_attacker)
	)
	var defense_reduction: int = int(working_defender.get("incoming_damage_flat_reduction", 0))
	var dodge_chance: int = int(working_defender.get("dodge_chance", 0))
	var dodged: bool = _roll_is_within_percent(working_attacker, dodge_chance)

	working_attacker["attack_power_bonus"] = attack_power_bonus

	if not used_fallback_attack:
		var weapon_stats: Dictionary = _extract_stats(weapon_def)
		base_damage = int(weapon_stats.get("base_damage", FALLBACK_ATTACK_DAMAGE))
		var durability_cost: int = resolve_weapon_base_durability_cost(weapon_def)
		durability_cost = max(0, durability_cost - int(working_attacker.get("durability_cost_flat_reduction", 0)))
		updated_weapon_instance = reduce_durability(updated_weapon_instance, durability_cost)
		if not dodged:
			bonus_damage = _collect_bonus_damage(weapon_def, "on_hit", working_attacker, working_defender)

	if not dodged:
		base_damage = max(1, base_damage + attack_power_bonus - defense_reduction)
		working_defender = apply_damage(working_defender, base_damage)

		if bonus_damage > 0 and not check_defeat(working_defender):
			working_defender = apply_damage(working_defender, bonus_damage)

	working_attacker["weapon_instance"] = updated_weapon_instance.duplicate(true)
	var total_damage_applied: int = max(0, int(defender_state.get("hp", 0)) - int(working_defender.get("hp", 0)))
	var events: Array[Dictionary] = [{
		"type": "player_attack_resolved",
		"damage_applied": total_damage_applied,
		"used_fallback_attack": used_fallback_attack,
		"weapon_broke": (not used_fallback_attack) and int(original_weapon_instance.get("current_durability", 0)) > 0 and int(updated_weapon_instance.get("current_durability", 0)) <= 0,
		"dodge_chance": dodge_chance,
		"dodged": dodged,
	}]

	if bool(events[0]["weapon_broke"]):
		events.append({
			"type": "weapon_broke",
			"definition_id": String(updated_weapon_instance.get("definition_id", "")),
		})

	return {
		"updated_attacker_state": working_attacker,
		"updated_defender_state": working_defender,
		"updated_weapon_state": updated_weapon_instance,
		"weapon_instance": updated_weapon_instance,
		"damage_applied": total_damage_applied,
		"used_fallback_attack": used_fallback_attack,
		"weapon_broke": bool(events[0]["weapon_broke"]),
		"enemy_defeated": check_defeat(working_defender),
		"dodge_chance": dodge_chance,
		"dodged": dodged,
		"events": events,
	}


func resolve_enemy_action(enemy_state: Dictionary, player_state: Dictionary, intent: Dictionary) -> Dictionary:
	var working_enemy: Dictionary = _prepare_combatant_state(enemy_state)
	var working_player: Dictionary = _prepare_combatant_state(player_state)
	var intent_effects: Array = _extract_effects(intent)
	var raw_damage: int = _extract_damage_from_effects(intent_effects)

	if raw_damage <= 0:
		raw_damage = int(working_enemy.get("base_damage", 0))

	raw_damage += int(working_enemy.get("attack_power_bonus", 0))
	var armor_reduction_applied: int = min(raw_damage, max(0, int(working_player.get("incoming_damage_flat_reduction", 0))))
	var post_armor_damage: int = max(0, raw_damage - armor_reduction_applied)
	var guard_before: int = max(0, int(working_player.get("guard_points", 0)))
	var guard_absorbed: int = min(guard_before, post_armor_damage)
	var damage_applied: int = max(0, post_armor_damage - guard_absorbed)
	working_player["guard_points"] = max(0, guard_before - guard_absorbed)
	working_player = apply_damage(working_player, damage_applied)

	return {
		"updated_enemy_state": working_enemy,
		"updated_player_state": working_player,
		"raw_damage": raw_damage,
		"armor_reduction_applied": armor_reduction_applied,
		"guard_before": guard_before,
		"guard_absorbed": guard_absorbed,
		"guard_remaining": int(working_player.get("guard_points", 0)),
		"damage_applied": damage_applied,
		"player_defeated": check_defeat(working_player),
		"events": [{
			"type": "enemy_action_resolved",
			"intent_id": String(intent.get("intent_id", "")),
			"damage_applied": damage_applied,
			"guard_absorbed": guard_absorbed,
		}],
	}


func resolve_player_defend(player_state: Dictionary) -> Dictionary:
	var working_player: Dictionary = _prepare_combatant_state(player_state)
	var existing_guard: int = max(0, int(working_player.get("guard_points", 0)))
	var guard_generated: int = _resolve_defend_guard_amount(working_player)
	var guard_total: int = existing_guard + guard_generated
	working_player["guard_points"] = guard_total
	return {
		"updated_player_state": working_player,
		"guard_generated": guard_generated,
		"guard_points": guard_total,
		"shield_bonus_applied": _left_hand_inventory_family(working_player) == "shield",
		"dual_wield_penalty_applied": _left_hand_inventory_family(working_player) == "weapon",
		"events": [{
			"type": "player_defend_resolved",
			"guard_generated": guard_generated,
		}],
	}


static func resolve_turn_end_guard_carryover(current_guard: int) -> int:
	var clamped_decay_rate: float = clampf(GUARD_DECAY_RATE, 0.0, 1.0)
	var retained_fraction: float = 1.0 - clamped_decay_rate
	return max(0, int(round(float(max(0, current_guard)) * retained_fraction)))


static func apply_turn_end_hunger_tick(combat_state) -> void:
	combat_state.player_hunger = max(0, int(combat_state.player_hunger) - 1)
	combat_state.player_state["hunger"] = combat_state.player_hunger


static func apply_hunger_penalty(combat_state) -> void:
	if int(combat_state.player_hunger) > 0:
		return

	combat_state.player_hp = max(0, int(combat_state.player_hp) - 1)
	combat_state.player_state["hp"] = combat_state.player_hp


static func advance_intent(combat_state) -> Dictionary:
	var phase_change: Dictionary = _refresh_boss_phase(combat_state)
	if bool(phase_change.get("changed", false)):
		return phase_change

	if combat_state.enemy_intent_pool.is_empty():
		combat_state.current_intent = {}
		return {}

	combat_state.current_intent_index = (int(combat_state.current_intent_index) + 1) % combat_state.enemy_intent_pool.size()
	var next_intent_variant: Variant = combat_state.enemy_intent_pool[combat_state.current_intent_index]
	if typeof(next_intent_variant) != TYPE_DICTIONARY:
		combat_state.current_intent = {}
		return {}

	var next_intent: Dictionary = next_intent_variant
	combat_state.current_intent = next_intent.duplicate(true)
	return {}


static func advance_turn(combat_state) -> void:
	combat_state.current_turn = int(combat_state.current_turn) + 1


func check_defeat(entity_state: Dictionary) -> bool:
	return int(entity_state.get("hp", 0)) <= 0


func apply_damage(target_state: Dictionary, amount: int) -> Dictionary:
	var updated_state: Dictionary = target_state.duplicate(true)
	var current_hp: int = int(updated_state.get("hp", 0))
	updated_state["hp"] = max(0, current_hp - max(0, amount))
	return updated_state


func reduce_durability(weapon_instance: Dictionary, amount: int) -> Dictionary:
	var updated_instance: Dictionary = weapon_instance.duplicate(true)
	var current_durability: int = int(updated_instance.get("current_durability", 0))
	updated_instance["current_durability"] = max(0, current_durability - max(0, amount))
	return updated_instance


static func resolve_weapon_durability_profile(weapon_def: Dictionary) -> String:
	var stats: Dictionary = weapon_def.get("rules", {}).get("stats", {})
	var profile: String = String(stats.get("durability_profile", WEAPON_DURABILITY_PROFILE_STANDARD)).strip_edges().to_lower()
	if not WEAPON_DURABILITY_PROFILE_MULTIPLIERS.has(profile):
		return WEAPON_DURABILITY_PROFILE_STANDARD
	return profile


static func resolve_weapon_base_durability_cost(weapon_def: Dictionary) -> int:
	var stats: Dictionary = weapon_def.get("rules", {}).get("stats", {})
	var authored_cost: int = max(0, int(stats.get("durability_cost_per_attack", 1)))
	if authored_cost <= 0:
		return 0
	var profile: String = resolve_weapon_durability_profile(weapon_def)
	var multiplier: float = float(WEAPON_DURABILITY_PROFILE_MULTIPLIERS.get(profile, 1.0))
	return max(1, ceili(float(authored_cost) * multiplier))


func _prepare_combatant_state(state: Dictionary) -> Dictionary:
	var working_state: Dictionary = state.duplicate(true)
	var definition: Dictionary = _extract_definition(working_state)
	var stats: Dictionary = _extract_stats(definition)

	for stat_key in stats.keys():
		if not working_state.has(stat_key):
			working_state[stat_key] = stats[stat_key]

	if not working_state.is_empty():
		working_state = _apply_passive_definition_effects(working_state, definition)

	return working_state


func _extract_definition(state: Dictionary) -> Dictionary:
	var definition_variant: Variant = state.get("definition", {})
	if typeof(definition_variant) != TYPE_DICTIONARY:
		return {}
	var definition: Dictionary = definition_variant
	return definition.duplicate(true)


func _extract_stats(definition: Dictionary) -> Dictionary:
	var rules: Dictionary = definition.get("rules", {})
	return rules.get("stats", {})


func _extract_weapon_instance(attacker_state: Dictionary) -> Dictionary:
	var instance_variant: Variant = attacker_state.get("weapon_instance", {})
	if typeof(instance_variant) == TYPE_DICTIONARY:
		var instance_dict: Dictionary = instance_variant
		return instance_dict.duplicate(true)
	return {}


func _is_weapon_broken(weapon_instance: Dictionary) -> bool:
	return int(weapon_instance.get("current_durability", 0)) <= 0


func _resolve_attack_power_bonus(attacker_state: Dictionary) -> int:
	var hunger: int = int(attacker_state.get("hunger", 0))
	if hunger <= STARVING_THRESHOLD:
		return -2
	if hunger <= HUNGRY_THRESHOLD:
		return -1
	return 0


func _roll_is_within_percent(source_state: Dictionary, threshold: int) -> bool:
	if threshold <= 0:
		return false
	var roll_value: int = int(source_state.get("random_roll_percent", 100))
	return roll_value <= threshold


func _collect_bonus_damage(definition: Dictionary, trigger_name: String, source_state: Dictionary, target_state: Dictionary) -> int:
	var total_bonus_damage: int = 0
	for effect in _collect_trigger_effects(definition, trigger_name, source_state, target_state):
		total_bonus_damage += _extract_damage_from_effect(effect)
	return total_bonus_damage


func _collect_trigger_effects(definition: Dictionary, trigger_name: String, source_state: Dictionary, target_state: Dictionary) -> Array:
	var matching_effects: Array = []
	var rules: Dictionary = definition.get("rules", {})
	var behaviors: Array = rules.get("behaviors", [])

	for behavior in behaviors:
		if typeof(behavior) != TYPE_DICTIONARY:
			continue

		var behavior_dict: Dictionary = behavior
		if String(behavior_dict.get("trigger", "")) != trigger_name:
			continue
		if not _condition_matches(behavior_dict.get("condition", null), source_state, target_state):
			continue

		var effects: Array = behavior_dict.get("effects", [])
		for effect in effects:
			if typeof(effect) == TYPE_DICTIONARY:
				matching_effects.append(effect)

	return matching_effects


func _apply_passive_definition_effects(state: Dictionary, definition: Dictionary) -> Dictionary:
	if state.is_empty():
		return state
	if bool(state.get("_passive_hydrated", false)):
		return state

	var hydrated_state: Dictionary = state.duplicate(true)
	for effect in _collect_trigger_effects(definition, "passive", hydrated_state, hydrated_state):
		hydrated_state = _apply_effect_to_state(hydrated_state, effect)

	hydrated_state["_passive_hydrated"] = true
	return hydrated_state


func _apply_effect_to_state(state: Dictionary, effect: Dictionary) -> Dictionary:
	var updated_state: Dictionary = state.duplicate(true)
	var effect_type: String = String(effect.get("type", ""))
	var params: Dictionary = effect.get("params", {})

	match effect_type:
		"modify_stat":
			var stat_name: String = String(params.get("stat", ""))
			var amount: int = int(params.get("amount", 0))
			if stat_name != "":
				updated_state[stat_name] = int(updated_state.get(stat_name, 0)) + amount
		_:
			pass

	return updated_state


func _condition_matches(condition_value: Variant, source_state: Dictionary, target_state: Dictionary) -> bool:
	if condition_value == null:
		return true
	if typeof(condition_value) != TYPE_DICTIONARY:
		return false

	var condition: Dictionary = condition_value
	var op: String = String(condition.get("op", "always"))
	if op == "always":
		return true

	var stat_name: String = String(condition.get("stat", ""))
	var comparison_value: Variant = condition.get("value", null)
	var state_value: Variant = _resolve_condition_stat(stat_name, source_state, target_state)

	if state_value == null:
		return false

	match op:
		"eq":
			return state_value == comparison_value
		"neq":
			return state_value != comparison_value
		"gt":
			return float(state_value) > float(comparison_value)
		"gte":
			return float(state_value) >= float(comparison_value)
		"lt":
			return float(state_value) < float(comparison_value)
		"lte":
			return float(state_value) <= float(comparison_value)
		"has_tag":
			return _state_has_tag(state_value, comparison_value)
		"not_has_tag":
			return not _state_has_tag(state_value, comparison_value)
		_:
			return false


func _resolve_condition_stat(stat_name: String, source_state: Dictionary, target_state: Dictionary) -> Variant:
	if source_state.has(stat_name):
		return source_state.get(stat_name)
	if target_state.has(stat_name):
		return target_state.get(stat_name)
	return null


func _state_has_tag(state_value: Variant, comparison_value: Variant) -> bool:
	if typeof(state_value) != TYPE_ARRAY:
		return false
	var tag_list: Array = state_value
	return tag_list.has(comparison_value)


func _extract_effects(intent: Dictionary) -> Array:
	return intent.get("effects", [])


func _extract_damage_from_effect(effect: Dictionary) -> int:
	if String(effect.get("type", "")) != "deal_damage":
		return 0
	var params: Dictionary = effect.get("params", {})
	return int(params.get("base", 0))


func _extract_damage_from_effects(effects: Array) -> int:
	var total_damage: int = 0
	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		total_damage += _extract_damage_from_effect(effect)
	return total_damage


func _resolve_defend_guard_amount(player_state: Dictionary) -> int:
	var guard_amount: int = BASE_DEFEND_GUARD
	var left_hand_inventory_family: String = _left_hand_inventory_family(player_state)
	if left_hand_inventory_family == "shield":
		guard_amount += SHIELD_DEFEND_BONUS
	elif left_hand_inventory_family == "weapon":
		guard_amount = max(0, guard_amount - DUAL_WIELD_DEFEND_GUARD_PENALTY)
	return guard_amount


func _resolve_dual_wield_attack_bonus(attacker_state: Dictionary) -> int:
	return DUAL_WIELD_ATTACK_POWER_BONUS if _left_hand_inventory_family(attacker_state) == "weapon" else 0


func _left_hand_inventory_family(state: Dictionary) -> String:
	var left_hand_variant: Variant = state.get("left_hand_instance", {})
	if typeof(left_hand_variant) != TYPE_DICTIONARY:
		return ""
	return String((left_hand_variant as Dictionary).get("inventory_family", ""))


static func _refresh_boss_phase(combat_state) -> Dictionary:
	if combat_state == null:
		return {}
	if not combat_state.has_method("refresh_boss_phase_from_enemy_hp"):
		return {}

	var phase_change_variant: Variant = combat_state.refresh_boss_phase_from_enemy_hp()
	if typeof(phase_change_variant) != TYPE_DICTIONARY:
		return {}
	var phase_change: Dictionary = phase_change_variant
	return phase_change

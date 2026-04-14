# Layer: Application
extends RefCounted
class_name SupportActionApplicationPolicy

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

func apply_action(
	active_run_state: RunState,
	active_support_state: SupportInteractionState,
	inventory_actions: InventoryActions,
	enemy_selection_policy: EnemySelectionPolicy,
	action_id: String
) -> Dictionary:
	if active_run_state == null:
		return {"ok": false, "action_id": action_id, "error": "missing_run_state"}
	if active_support_state == null:
		return {"ok": false, "action_id": action_id, "error": "missing_support_state"}

	var offer: Dictionary = active_support_state.get_offer_by_id(action_id)
	if offer.is_empty():
		return {"ok": false, "action_id": action_id, "error": "unknown_support_action"}
	if not bool(offer.get("available", true)):
		return {"ok": false, "action_id": action_id, "error": "support_action_unavailable"}

	var cost_gold: int = int(offer.get("cost_gold", 0))
	if cost_gold > 0 and active_run_state.gold < cost_gold:
		return {
			"ok": false,
			"action_id": action_id,
			"error": "insufficient_gold",
			"required_gold": cost_gold,
			"current_gold": active_run_state.gold,
		}

	var result: Dictionary = {
		"ok": true,
		"action_id": action_id,
		"support_type": String(active_support_state.support_type),
		"close_interaction": false,
	}
	var effect_type: String = String(offer.get("effect_type", ""))

	match effect_type:
		"rest":
			active_run_state.player_hp = min(RunState.DEFAULT_PLAYER_HP, active_run_state.player_hp + int(offer.get("heal_amount", 0)))
			active_run_state.hunger = clamp(
				active_run_state.hunger + int(offer.get("hunger_delta", 0)),
				0,
				RunState.DEFAULT_HUNGER
			)
			active_support_state.mark_offer_unavailable(action_id)
			result["player_hp"] = active_run_state.player_hp
			result["hunger"] = active_run_state.hunger
			result["close_interaction"] = true
		"repair_weapon":
			var repair_result: Dictionary = inventory_actions.repair_active_weapon(active_run_state.inventory_state)
			if not bool(repair_result.get("ok", false)):
				return {"ok": false, "action_id": action_id, "error": String(repair_result.get("error", "support_action_failed"))}
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(repair_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = true
		"open_blacksmith_weapon_targets":
			active_support_state.open_blacksmith_target_selection(
				SupportInteractionState.BLACKSMITH_VIEW_MODE_WEAPON_TARGETS,
				active_run_state.inventory_state
			)
		"open_blacksmith_armor_targets":
			active_support_state.open_blacksmith_target_selection(
				SupportInteractionState.BLACKSMITH_VIEW_MODE_ARMOR_TARGETS,
				active_run_state.inventory_state
			)
		"cycle_blacksmith_page":
			active_support_state.advance_blacksmith_target_page(active_run_state.inventory_state)
		"upgrade_weapon":
			var upgrade_weapon_result: Dictionary = inventory_actions.upgrade_weapon_slot(
				active_run_state.inventory_state,
				int(offer.get("target_slot_id", -1))
			)
			if not bool(upgrade_weapon_result.get("ok", false)):
				return {"ok": false, "action_id": action_id, "error": String(upgrade_weapon_result.get("error", "support_action_failed"))}
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(upgrade_weapon_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = true
		"upgrade_armor":
			var upgrade_armor_result: Dictionary = inventory_actions.upgrade_armor_slot(
				active_run_state.inventory_state,
				int(offer.get("target_slot_id", -1))
			)
			if not bool(upgrade_armor_result.get("ok", false)):
				return {"ok": false, "action_id": action_id, "error": String(upgrade_armor_result.get("error", "support_action_failed"))}
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(upgrade_armor_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = true
		"buy_consumable":
			var add_result: Dictionary = inventory_actions.add_consumable_stack(active_run_state.inventory_state, String(offer.get("definition_id", "")), int(offer.get("amount", 1)))
			if not bool(add_result.get("ok", false)):
				return {"ok": false, "action_id": action_id, "error": String(add_result.get("error", "support_action_failed"))}
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(add_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"buy_weapon":
			var replace_result: Dictionary = inventory_actions.replace_active_weapon(active_run_state.inventory_state, String(offer.get("definition_id", "")))
			if not bool(replace_result.get("ok", false)):
				return {"ok": false, "action_id": action_id, "error": String(replace_result.get("error", "support_action_failed"))}
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(replace_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"buy_armor":
			var armor_result: Dictionary = inventory_actions.replace_active_armor(active_run_state.inventory_state, String(offer.get("definition_id", "")))
			if not bool(armor_result.get("ok", false)):
				return {"ok": false, "action_id": action_id, "error": String(armor_result.get("error", "support_action_failed"))}
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(armor_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"accept_side_mission":
			var accept_result: Dictionary = _apply_side_mission_accept(
				active_run_state,
				active_support_state,
				enemy_selection_policy
			)
			if not bool(accept_result.get("ok", false)):
				return accept_result.merged({"action_id": action_id}, true)
			result.merge(accept_result, true)
			result["close_interaction"] = true
		"claim_side_mission_reward":
			var reward_result: Dictionary = _apply_side_mission_reward_claim(
				active_run_state,
				active_support_state,
				inventory_actions,
				offer
			)
			if not bool(reward_result.get("ok", false)):
				return reward_result.merged({"action_id": action_id}, true)
			result.merge(reward_result, true)
			result["close_interaction"] = true
		_:
			return {"ok": false, "action_id": action_id, "error": "unknown_support_action"}

	return result


func _should_close_interaction_after_apply(active_support_state: SupportInteractionState) -> bool:
	if active_support_state == null:
		return false
	if active_support_state.support_type != SupportInteractionState.TYPE_MERCHANT:
		return true
	return not active_support_state.has_available_offers()


func _apply_side_mission_accept(
	active_run_state: RunState,
	active_support_state: SupportInteractionState,
	enemy_selection_policy: EnemySelectionPolicy
) -> Dictionary:
	if active_support_state.support_type != SupportInteractionState.TYPE_SIDE_MISSION:
		return {"ok": false, "error": "invalid_support_type"}

	var map_runtime_state: MapRuntimeState = active_run_state.map_runtime_state
	if map_runtime_state == null:
		return {"ok": false, "error": "missing_map_runtime_state"}

	var source_node_id: int = int(active_support_state.source_node_id)
	var candidate_node_ids: Array[int] = map_runtime_state.list_eligible_side_mission_target_node_ids(source_node_id)
	if candidate_node_ids.is_empty():
		return {"ok": false, "error": "no_side_mission_target"}

	var loader: ContentLoader = ContentLoaderScript.new()
	var enemy_definition_ids: Array[String] = []
	if enemy_selection_policy != null:
		enemy_definition_ids = enemy_selection_policy.list_combat_enemy_definition_ids(loader, active_run_state.stage_index)
	if enemy_definition_ids.is_empty():
		return {"ok": false, "error": "missing_side_mission_enemy_pool"}

	var mission_definition: Dictionary = loader.load_definition(
		SupportInteractionState.SIDE_MISSION_FAMILY,
		String(active_support_state.mission_definition_id)
	)
	if mission_definition.is_empty():
		return {"ok": false, "error": "missing_side_mission_definition"}

	var reward_pool: Array[Dictionary] = _extract_side_mission_reward_pool(mission_definition)
	if reward_pool.size() < 2:
		return {"ok": false, "error": "insufficient_side_mission_reward_pool"}

	var rng_context: Dictionary = active_run_state.consume_named_rng_context(
		"side_mission_accept",
		"%d:%d:%s" % [
			int(active_run_state.stage_index),
			source_node_id,
			String(active_support_state.mission_definition_id),
		]
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = max(1, int(rng_context.get("stream_seed", 1)))

	_shuffle_variant_array(candidate_node_ids, rng)
	_shuffle_variant_array(enemy_definition_ids, rng)
	_shuffle_dictionary_array(reward_pool, rng)

	var target_node_id: int = candidate_node_ids[0]
	var target_enemy_definition_id: String = enemy_definition_ids[0]
	var reward_offers: Array[Dictionary] = []
	for index in range(min(2, reward_pool.size())):
		reward_offers.append((reward_pool[index] as Dictionary).duplicate(true))

	map_runtime_state.reveal_node(target_node_id)
	var persisted_state: Dictionary = {
		"support_type": SupportInteractionState.TYPE_SIDE_MISSION,
		"mission_definition_id": active_support_state.mission_definition_id,
		"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_ACCEPTED,
		"target_node_id": target_node_id,
		"target_enemy_definition_id": target_enemy_definition_id,
		"reward_offers": reward_offers,
	}
	active_support_state.setup_for_type(
		SupportInteractionState.TYPE_SIDE_MISSION,
		source_node_id,
		persisted_state,
		active_run_state.stage_index,
		active_run_state.inventory_state,
		map_runtime_state
	)
	return {
		"ok": true,
		"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_ACCEPTED,
		"target_node_id": target_node_id,
		"target_enemy_definition_id": target_enemy_definition_id,
		"reward_offer_count": reward_offers.size(),
	}


func _apply_side_mission_reward_claim(
	active_run_state: RunState,
	active_support_state: SupportInteractionState,
	inventory_actions: InventoryActions,
	offer: Dictionary
) -> Dictionary:
	if active_support_state.support_type != SupportInteractionState.TYPE_SIDE_MISSION:
		return {"ok": false, "error": "invalid_support_type"}

	var inventory_family: String = String(offer.get("inventory_family", ""))
	var definition_id: String = String(offer.get("definition_id", ""))
	var reward_result: Dictionary = {}
	match inventory_family:
		InventoryState.INVENTORY_FAMILY_WEAPON:
			reward_result = inventory_actions.add_carried_weapon(active_run_state.inventory_state, definition_id)
		InventoryState.INVENTORY_FAMILY_ARMOR:
			reward_result = inventory_actions.add_carried_armor(active_run_state.inventory_state, definition_id)
		_:
			return {"ok": false, "error": "invalid_side_mission_reward_family"}

	if not bool(reward_result.get("ok", false)):
		return reward_result

	var persisted_state: Dictionary = active_support_state.build_persisted_node_state()
	persisted_state["mission_status"] = SupportInteractionState.SIDE_MISSION_STATUS_CLAIMED
	active_support_state.setup_for_type(
		SupportInteractionState.TYPE_SIDE_MISSION,
		int(active_support_state.source_node_id),
		persisted_state,
		active_run_state.stage_index,
		active_run_state.inventory_state,
		active_run_state.map_runtime_state
	)
	return {
		"ok": true,
		"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_CLAIMED,
	}.merged(reward_result, true)


func _extract_side_mission_reward_pool(mission_definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var reward_pool_variant: Variant = mission_definition.get("rules", {}).get("reward_pool", [])
	if typeof(reward_pool_variant) != TYPE_ARRAY:
		return result
	for offer_variant in reward_pool_variant:
		if typeof(offer_variant) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_variant
		var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
		var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
		if inventory_family not in [InventoryState.INVENTORY_FAMILY_WEAPON, InventoryState.INVENTORY_FAMILY_ARMOR]:
			continue
		if definition_id.is_empty():
			continue
		result.append({
			"offer_id": String(offer.get("offer_id", "claim_%s" % definition_id)),
			"label": String(offer.get("label", "")),
			"effect_type": "claim_side_mission_reward",
			"inventory_family": inventory_family,
			"definition_id": definition_id,
			"available": true,
		})
	return result


func _shuffle_variant_array(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current_value: Variant = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value


func _shuffle_dictionary_array(values: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current_value: Dictionary = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value

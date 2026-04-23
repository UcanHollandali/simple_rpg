# Layer: Application
extends RefCounted
class_name SupportActionApplicationPolicy

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const INVENTORY_CHOICE_REQUIRED_ERROR: String = "inventory_choice_required"
const HAMLET_TRAINING_TECHNIQUE_IDS_BY_STAGE := {
	1: ["cleanse_pulse", "blood_draw", "sundering_strike", "echo_strike"],
	2: ["sundering_strike", "echo_strike", "blood_draw", "cleanse_pulse"],
	3: ["blood_draw", "cleanse_pulse", "sundering_strike", "echo_strike"],
}

func apply_action(
	active_run_state: RunState,
	active_support_state: SupportInteractionState,
	inventory_actions: InventoryActions,
	enemy_selection_policy: EnemySelectionPolicy,
	action_id: String,
	discard_slot_id: int = -1
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
			var add_result: Dictionary = _resolve_inventory_grant(
				active_run_state,
				inventory_actions,
				action_id,
				InventoryState.INVENTORY_FAMILY_CONSUMABLE,
				String(offer.get("definition_id", "")),
				int(offer.get("amount", 1)),
				discard_slot_id
			)
			if not bool(add_result.get("ok", false)):
				return _merge_support_action_failure(action_id, add_result)
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(add_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"buy_weapon":
			var weapon_result: Dictionary = _resolve_inventory_grant(
				active_run_state,
				inventory_actions,
				action_id,
				InventoryState.INVENTORY_FAMILY_WEAPON,
				String(offer.get("definition_id", "")),
				1,
				discard_slot_id
			)
			if not bool(weapon_result.get("ok", false)):
				return _merge_support_action_failure(action_id, weapon_result)
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(weapon_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"buy_armor":
			var armor_result: Dictionary = _resolve_inventory_grant(
				active_run_state,
				inventory_actions,
				action_id,
				InventoryState.INVENTORY_FAMILY_ARMOR,
				String(offer.get("definition_id", "")),
				1,
				discard_slot_id
			)
			if not bool(armor_result.get("ok", false)):
				return _merge_support_action_failure(action_id, armor_result)
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(armor_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"buy_shield":
			var shield_result: Dictionary = _resolve_inventory_grant(
				active_run_state,
				inventory_actions,
				action_id,
				InventoryState.INVENTORY_FAMILY_SHIELD,
				String(offer.get("definition_id", "")),
				1,
				discard_slot_id
			)
			if not bool(shield_result.get("ok", false)):
				return _merge_support_action_failure(action_id, shield_result)
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(shield_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"buy_belt":
			var belt_result: Dictionary = _resolve_inventory_grant(
				active_run_state,
				inventory_actions,
				action_id,
				InventoryState.INVENTORY_FAMILY_BELT,
				String(offer.get("definition_id", "")),
				1,
				discard_slot_id
			)
			if not bool(belt_result.get("ok", false)):
				return _merge_support_action_failure(action_id, belt_result)
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(belt_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"buy_passive_item":
			var passive_result: Dictionary = _resolve_inventory_grant(
				active_run_state,
				inventory_actions,
				action_id,
				InventoryState.INVENTORY_FAMILY_PASSIVE,
				String(offer.get("definition_id", "")),
				1,
				discard_slot_id
			)
			if not bool(passive_result.get("ok", false)):
				return _merge_support_action_failure(action_id, passive_result)
			active_run_state.gold -= cost_gold
			active_support_state.mark_offer_unavailable(action_id)
			result.merge(passive_result, true)
			result["gold"] = active_run_state.gold
			result["close_interaction"] = _should_close_interaction_after_apply(active_support_state)
		"accept_side_mission":
			var accept_result: Dictionary = _apply_hamlet_accept(
				active_run_state,
				active_support_state,
				inventory_actions,
				enemy_selection_policy,
				discard_slot_id
			)
			if not bool(accept_result.get("ok", false)):
				return accept_result.merged({"action_id": action_id}, true)
			result.merge(accept_result, true)
			result["close_interaction"] = true
		"claim_side_mission_reward":
			var reward_result: Dictionary = _apply_hamlet_reward_claim(
				active_run_state,
				active_support_state,
				inventory_actions,
				offer,
				discard_slot_id
			)
			if not bool(reward_result.get("ok", false)):
				return reward_result.merged({"action_id": action_id}, true)
			result.merge(reward_result, true)
			result["close_interaction"] = bool(reward_result.get("close_interaction", true))
		"equip_technique", "skip_training_choice":
			var training_result: Dictionary = _apply_hamlet_training_choice(
				active_run_state,
				active_support_state,
				offer
			)
			if not bool(training_result.get("ok", false)):
				return training_result.merged({"action_id": action_id}, true)
			result.merge(training_result, true)
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


func _merge_support_action_failure(action_id: String, action_result: Dictionary) -> Dictionary:
	return action_result.merged({
		"ok": false,
		"action_id": action_id,
		"error": String(action_result.get("error", "support_action_failed")),
	}, true)


func _resolve_inventory_grant(
	active_run_state: RunState,
	inventory_actions: InventoryActions,
	action_id: String,
	inventory_family: String,
	definition_id: String,
	amount: int,
	discard_slot_id: int = -1
) -> Dictionary:
	var preview_result: Dictionary = inventory_actions.preview_inventory_item_grant(
		active_run_state.inventory_state,
		inventory_family,
		definition_id,
		max(1, amount)
	)
	if not bool(preview_result.get("ok", false)):
		return preview_result.merged({
			"ok": false,
			"action_id": action_id,
			"error": String(preview_result.get("error", "support_action_failed")),
		}, true)
	if bool(preview_result.get("inventory_choice_required", false)) and discard_slot_id <= 0:
		return preview_result.merged({
			"ok": false,
			"action_id": action_id,
			"error": INVENTORY_CHOICE_REQUIRED_ERROR,
		}, true)
	return inventory_actions.grant_inventory_item(
		active_run_state.inventory_state,
		inventory_family,
		definition_id,
		max(1, amount),
		discard_slot_id
	)


func _apply_hamlet_accept(
	active_run_state: RunState,
	active_support_state: SupportInteractionState,
	inventory_actions: InventoryActions,
	enemy_selection_policy: EnemySelectionPolicy,
	discard_slot_id: int = -1
) -> Dictionary:
	if active_support_state.support_type != SupportInteractionState.TYPE_HAMLET:
		return {"ok": false, "error": "invalid_support_type"}

	var map_runtime_state: MapRuntimeState = active_run_state.map_runtime_state
	if map_runtime_state == null:
		return {"ok": false, "error": "missing_map_runtime_state"}

	var source_node_id: int = int(active_support_state.source_node_id)
	var mission_type: String = String(active_support_state.mission_type)
	var quest_item_definition_id: String = String(active_support_state.quest_item_definition_id).strip_edges()
	if mission_type == SupportInteractionState.MISSION_TYPE_DELIVER_SUPPLIES:
		if quest_item_definition_id.is_empty():
			return {"ok": false, "error": "missing_side_quest_item_definition"}
		var add_quest_item_result: Dictionary = _resolve_inventory_grant(
			active_run_state,
			inventory_actions,
			"accept_side_mission",
			InventoryState.INVENTORY_FAMILY_QUEST_ITEM,
			quest_item_definition_id,
			1,
			discard_slot_id
		)
		if not bool(add_quest_item_result.get("ok", false)):
			return add_quest_item_result

	var target_families: PackedStringArray = _resolve_side_quest_target_families(active_support_state)
	var candidate_node_ids: Array[int] = map_runtime_state.list_eligible_side_quest_target_node_ids(source_node_id, target_families)
	if candidate_node_ids.is_empty():
		return {"ok": false, "error": "no_side_mission_target"}

	var loader: ContentLoader = ContentLoaderScript.new()
	var mission_definition: Dictionary = loader.load_definition(
		SupportInteractionState.SIDE_MISSION_FAMILY,
		String(active_support_state.mission_definition_id)
	)
	if mission_definition.is_empty():
		return {"ok": false, "error": "missing_side_mission_definition"}

	var reward_pool: Array[Dictionary] = _extract_hamlet_reward_pool(mission_definition)
	if reward_pool.size() < 2:
		return {"ok": false, "error": "insufficient_side_mission_reward_pool"}

	var enemy_definition_ids: Array[String] = []
	if mission_type == SupportInteractionState.MISSION_TYPE_HUNT_MARKED_ENEMY:
		if enemy_selection_policy != null:
			enemy_definition_ids = enemy_selection_policy.list_combat_enemy_definition_ids(loader, active_run_state.stage_index)
		if enemy_definition_ids.is_empty():
			return {"ok": false, "error": "missing_side_mission_enemy_pool"}

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
	var hamlet_personality: String = SupportInteractionState.resolve_hamlet_personality_for_stage(
		active_run_state.stage_index
	)

	_shuffle_variant_array(candidate_node_ids, rng)
	if not enemy_definition_ids.is_empty():
		_shuffle_variant_array(enemy_definition_ids, rng)
	_shuffle_dictionary_array(reward_pool, rng)
	reward_pool = _build_biased_hamlet_reward_pool(reward_pool, hamlet_personality)

	var target_node_id: int = candidate_node_ids[0]
	var target_enemy_definition_id: String = enemy_definition_ids[0] if not enemy_definition_ids.is_empty() else ""
	var reward_offers: Array[Dictionary] = []
	for index in range(min(2, reward_pool.size())):
		reward_offers.append((reward_pool[index] as Dictionary).duplicate(true))

	map_runtime_state.reveal_node(target_node_id)
	var persisted_state: Dictionary = {
		"support_type": SupportInteractionState.TYPE_HAMLET,
		"mission_definition_id": active_support_state.mission_definition_id,
		"mission_type": mission_type,
		"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_ACCEPTED,
		"target_node_id": target_node_id,
		"target_enemy_definition_id": target_enemy_definition_id,
		"quest_item_definition_id": quest_item_definition_id,
		"reward_offers": reward_offers,
	}
	active_support_state.setup_for_type(
		SupportInteractionState.TYPE_HAMLET,
		source_node_id,
		persisted_state,
		active_run_state.stage_index,
		active_run_state.inventory_state,
		map_runtime_state,
		active_run_state.run_seed
	)
	return {
		"ok": true,
		"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_ACCEPTED,
		"target_node_id": target_node_id,
		"target_enemy_definition_id": target_enemy_definition_id,
		"mission_type": mission_type,
		"quest_item_definition_id": quest_item_definition_id,
		"reward_offer_count": reward_offers.size(),
	}


func _apply_hamlet_reward_claim(
	active_run_state: RunState,
	active_support_state: SupportInteractionState,
	inventory_actions: InventoryActions,
	offer: Dictionary,
	discard_slot_id: int = -1
) -> Dictionary:
	if active_support_state.support_type != SupportInteractionState.TYPE_HAMLET:
		return {"ok": false, "error": "invalid_support_type"}

	var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
	if effect_type.is_empty():
		effect_type = "grant_item"
	var reward_result: Dictionary = {}
	match effect_type:
		"grant_gold":
			var gold_amount: int = max(1, int(offer.get("amount", 0)))
			active_run_state.gold += gold_amount
			reward_result = {
				"ok": true,
				"gold": active_run_state.gold,
				"applied_amount": gold_amount,
			}
		"grant_item", "claim_side_mission_reward":
			reward_result = _resolve_inventory_grant(
				active_run_state,
				inventory_actions,
				String(offer.get("offer_id", "claim_side_mission_reward")),
				String(offer.get("inventory_family", "")).strip_edges(),
				String(offer.get("definition_id", "")).strip_edges(),
				max(1, int(offer.get("amount", 1))),
				discard_slot_id
			)
		_:
			return {"ok": false, "error": "invalid_side_mission_reward_effect"}

	if not bool(reward_result.get("ok", false)):
		return reward_result

	var quest_item_definition_id: String = String(active_support_state.quest_item_definition_id).strip_edges()
	if not quest_item_definition_id.is_empty():
		inventory_actions.remove_quest_item(active_run_state.inventory_state, quest_item_definition_id)

	var persisted_state: Dictionary = active_support_state.build_persisted_node_state()
	persisted_state["mission_status"] = SupportInteractionState.SIDE_MISSION_STATUS_CLAIMED
	var training_offers: Array[Dictionary] = _build_hamlet_training_offers(active_run_state, active_support_state)
	if training_offers.is_empty():
		persisted_state["training_step"] = SupportInteractionState.TRAINING_STEP_NONE
		persisted_state["technique_offers"] = []
	else:
		persisted_state["training_step"] = SupportInteractionState.TRAINING_STEP_TECHNIQUE_CHOICE
		persisted_state["technique_offers"] = training_offers
	active_support_state.setup_for_type(
		SupportInteractionState.TYPE_HAMLET,
		int(active_support_state.source_node_id),
		persisted_state,
		active_run_state.stage_index,
		active_run_state.inventory_state,
		active_run_state.map_runtime_state,
		active_run_state.run_seed
	)
	return {
		"ok": true,
		"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_CLAIMED,
		"close_interaction": training_offers.is_empty(),
		"training_offer_count": training_offers.size(),
	}.merged(reward_result, true)


func _apply_hamlet_training_choice(
	active_run_state: RunState,
	active_support_state: SupportInteractionState,
	offer: Dictionary
) -> Dictionary:
	if active_support_state.support_type != SupportInteractionState.TYPE_HAMLET:
		return {"ok": false, "error": "invalid_support_type"}
	if String(active_support_state.training_step) != SupportInteractionState.TRAINING_STEP_TECHNIQUE_CHOICE:
		return {"ok": false, "error": "training_choice_not_open"}

	var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
	var previously_equipped_definition_id: String = String(active_run_state.equipped_technique_definition_id).strip_edges()
	var persisted_state: Dictionary = active_support_state.build_persisted_node_state()
	persisted_state["mission_status"] = SupportInteractionState.SIDE_MISSION_STATUS_CLAIMED
	persisted_state["training_step"] = SupportInteractionState.TRAINING_STEP_NONE
	persisted_state["technique_offers"] = []

	match effect_type:
		"equip_technique":
			var technique_definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			if technique_definition_id.is_empty():
				return {"ok": false, "error": "missing_technique_definition"}
			active_run_state.equipped_technique_definition_id = technique_definition_id
			active_support_state.setup_for_type(
				SupportInteractionState.TYPE_HAMLET,
				int(active_support_state.source_node_id),
				persisted_state,
				active_run_state.stage_index,
				active_run_state.inventory_state,
				active_run_state.map_runtime_state,
				active_run_state.run_seed
			)
			return {
				"ok": true,
				"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_CLAIMED,
				"equipped_technique_definition_id": technique_definition_id,
				"replaced_technique_definition_id": previously_equipped_definition_id,
			}
		"skip_training_choice":
			active_support_state.setup_for_type(
				SupportInteractionState.TYPE_HAMLET,
				int(active_support_state.source_node_id),
				persisted_state,
				active_run_state.stage_index,
				active_run_state.inventory_state,
				active_run_state.map_runtime_state,
				active_run_state.run_seed
			)
			return {
				"ok": true,
				"mission_status": SupportInteractionState.SIDE_MISSION_STATUS_CLAIMED,
				"equipped_technique_definition_id": previously_equipped_definition_id,
				"training_skipped": true,
			}
		_:
			return {"ok": false, "error": "invalid_training_choice_effect"}


func _extract_hamlet_reward_pool(mission_definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var reward_pool_variant: Variant = mission_definition.get("rules", {}).get("reward_pool", [])
	if typeof(reward_pool_variant) != TYPE_ARRAY:
		return result
	for offer_variant in reward_pool_variant:
		if typeof(offer_variant) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_variant
		var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
		if effect_type.is_empty():
			effect_type = "grant_item"
		match effect_type:
			"grant_gold":
				var gold_amount: int = max(1, int(offer.get("amount", 0)))
				result.append({
					"offer_id": String(offer.get("offer_id", "claim_gold_%d" % gold_amount)),
					"label": String(offer.get("label", "")),
					"effect_type": "grant_gold",
					"amount": gold_amount,
					"available": true,
				})
			"grant_item":
				var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
				var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
				if inventory_family.is_empty() or definition_id.is_empty():
					continue
				var reward_offer: Dictionary = {
					"offer_id": String(offer.get("offer_id", "claim_%s" % definition_id)),
					"label": String(offer.get("label", "")),
					"effect_type": "grant_item",
					"inventory_family": inventory_family,
					"definition_id": definition_id,
					"available": true,
				}
				if inventory_family == InventoryState.INVENTORY_FAMILY_CONSUMABLE:
					reward_offer["amount"] = max(1, int(offer.get("amount", 1)))
				result.append(reward_offer)
	return result


func _build_hamlet_training_offers(
	active_run_state: RunState,
	active_support_state: SupportInteractionState
) -> Array[Dictionary]:
	if active_run_state == null or active_support_state == null:
		return []

	var technique_ids_variant: Variant = HAMLET_TRAINING_TECHNIQUE_IDS_BY_STAGE.get(
		int(active_run_state.stage_index),
		HAMLET_TRAINING_TECHNIQUE_IDS_BY_STAGE.get(1, [])
	)
	if typeof(technique_ids_variant) != TYPE_ARRAY:
		return []
	var technique_definition_ids: Array = (technique_ids_variant as Array).duplicate(true)
	var equipped_definition_id: String = String(active_run_state.equipped_technique_definition_id).strip_edges()
	if not equipped_definition_id.is_empty() and technique_definition_ids.size() > 2:
		technique_definition_ids.erase(equipped_definition_id)

	var rng_context: Dictionary = active_run_state.consume_named_rng_context(
		"hamlet_training_offer",
		"%d:%d:%s" % [
			int(active_run_state.stage_index),
			int(active_support_state.source_node_id),
			String(active_support_state.mission_definition_id),
		]
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = max(1, int(rng_context.get("stream_seed", 1)))
	_shuffle_variant_array(technique_definition_ids, rng)

	var loader: ContentLoader = ContentLoaderScript.new()
	var result: Array[Dictionary] = []
	for technique_definition_id_variant in technique_definition_ids:
		if result.size() >= 2:
			break
		var technique_definition_id: String = String(technique_definition_id_variant).strip_edges()
		if technique_definition_id.is_empty():
			continue
		var technique_definition: Dictionary = loader.load_definition("Techniques", technique_definition_id)
		if technique_definition.is_empty():
			continue
		var display_name: String = String(technique_definition.get("display", {}).get("name", technique_definition_id))
		var offer: Dictionary = {
			"offer_id": "equip_%s" % technique_definition_id,
			"label": "Take %s" % display_name,
			"effect_type": "equip_technique",
			"definition_id": technique_definition_id,
			"available": true,
		}
		if not equipped_definition_id.is_empty():
			offer["replaces_definition_id"] = equipped_definition_id
		result.append(offer)

	if result.is_empty():
		return result
	result.append({
		"offer_id": "skip_hamlet_training",
		"label": "Skip for now",
		"effect_type": "skip_training_choice",
		"available": true,
	})
	return result


func _build_biased_hamlet_reward_pool(
	reward_pool: Array[Dictionary],
	hamlet_personality: String
) -> Array[Dictionary]:
	var strong_matches: Array[Dictionary] = []
	var medium_matches: Array[Dictionary] = []
	var fallback_matches: Array[Dictionary] = []
	for reward_offer in reward_pool:
		var score: int = _score_hamlet_reward_offer_for_personality(reward_offer, hamlet_personality)
		if score >= 2:
			strong_matches.append(reward_offer)
		elif score >= 1:
			medium_matches.append(reward_offer)
		else:
			fallback_matches.append(reward_offer)
	var biased_pool: Array[Dictionary] = []
	biased_pool.append_array(strong_matches)
	biased_pool.append_array(medium_matches)
	biased_pool.append_array(fallback_matches)
	return biased_pool


func _score_hamlet_reward_offer_for_personality(reward_offer: Dictionary, hamlet_personality: String) -> int:
	var effect_type: String = String(reward_offer.get("effect_type", "grant_item")).strip_edges()
	if effect_type == "grant_gold":
		match hamlet_personality:
			SupportInteractionState.HAMLET_PERSONALITY_FRONTIER, SupportInteractionState.HAMLET_PERSONALITY_PILGRIM:
				return 1
			SupportInteractionState.HAMLET_PERSONALITY_TRADE:
				return 2
			_:
				return 0

	var inventory_family: String = String(reward_offer.get("inventory_family", "")).strip_edges()
	match hamlet_personality:
		SupportInteractionState.HAMLET_PERSONALITY_FRONTIER:
			if inventory_family == InventoryState.INVENTORY_FAMILY_WEAPON:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_ARMOR:
				return 1
		SupportInteractionState.HAMLET_PERSONALITY_PILGRIM:
			if inventory_family == InventoryState.INVENTORY_FAMILY_SHIELD:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_CONSUMABLE:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_SHIELD_ATTACHMENT:
				return 1
			if inventory_family == InventoryState.INVENTORY_FAMILY_ARMOR:
				return 1
		SupportInteractionState.HAMLET_PERSONALITY_TRADE:
			if inventory_family == InventoryState.INVENTORY_FAMILY_BELT:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_PASSIVE:
				return 2
			if inventory_family == InventoryState.INVENTORY_FAMILY_CONSUMABLE:
				return 1
	return 0


func _resolve_side_quest_target_families(active_support_state: SupportInteractionState) -> PackedStringArray:
	var mission_definition: Dictionary = {}
	var loader: ContentLoader = ContentLoaderScript.new()
	if active_support_state != null and not String(active_support_state.mission_definition_id).is_empty():
		mission_definition = loader.load_definition(
			SupportInteractionState.SIDE_MISSION_FAMILY,
			String(active_support_state.mission_definition_id)
		)
	var configured_target_families: Variant = mission_definition.get("rules", {}).get("target_families", [])
	var target_families: PackedStringArray = PackedStringArray()
	if typeof(configured_target_families) == TYPE_ARRAY:
		for family_variant in configured_target_families:
			var family_name: String = String(family_variant).strip_edges()
			if family_name.is_empty() or target_families.has(family_name):
				continue
			target_families.append(family_name)
	if not target_families.is_empty():
		return target_families

	match String(active_support_state.mission_type):
		SupportInteractionState.MISSION_TYPE_DELIVER_SUPPLIES:
			return PackedStringArray(["event", "reward", "rest", "merchant", "blacksmith"])
		SupportInteractionState.MISSION_TYPE_RESCUE_MISSING_SCOUT, SupportInteractionState.MISSION_TYPE_BRING_PROOF:
			return PackedStringArray(["combat", "event", "reward"])
		_:
			return PackedStringArray(["combat"])


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

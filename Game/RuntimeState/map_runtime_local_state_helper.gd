# Layer: RuntimeState helper
extends RefCounted
class_name MapRuntimeLocalStateHelper

const InventoryStateScript = preload("res://Game/RuntimeState/inventory_state.gd")


static func build_node_family_lookup(node_graph: Array[Dictionary], missing_node_id: int) -> Dictionary:
	var node_family_by_id: Dictionary = {}
	for node_data in node_graph:
		var node_id: int = int(node_data.get("node_id", missing_node_id))
		if node_id < 0:
			continue
		node_family_by_id[node_id] = String(node_data.get("node_family", ""))
	return node_family_by_id


static func build_default_support_node_state(node_family: String) -> Dictionary:
	return {
		"support_type": node_family,
		"unavailable_offer_ids": [],
	}


static func normalize_support_node_state(node_family: String, support_node_state: Dictionary) -> Dictionary:
	var unavailable_ids: Array[String] = []
	var unavailable_ids_variant: Variant = support_node_state.get("unavailable_offer_ids", [])
	if typeof(unavailable_ids_variant) == TYPE_ARRAY:
		for offer_id_variant in unavailable_ids_variant:
			var offer_id: String = String(offer_id_variant)
			if offer_id.is_empty() or unavailable_ids.has(offer_id):
				continue
			unavailable_ids.append(offer_id)

	return {
		"support_type": node_family,
		"unavailable_offer_ids": unavailable_ids,
	}


static func support_state_should_persist(normalized_state: Dictionary) -> bool:
	var unavailable_ids_variant: Variant = normalized_state.get("unavailable_offer_ids", [])
	return typeof(unavailable_ids_variant) == TYPE_ARRAY and not (unavailable_ids_variant as Array).is_empty()


static func restore_support_node_states(
	saved_support_states_variant: Variant,
	node_family_by_id: Dictionary,
	support_node_families: PackedStringArray,
	missing_node_id: int
) -> Dictionary:
	var restored_states: Dictionary = {}
	if typeof(saved_support_states_variant) != TYPE_ARRAY:
		return restored_states

	for entry_variant in saved_support_states_variant:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", missing_node_id))
		var node_family: String = String(node_family_by_id.get(node_id, ""))
		if node_family.is_empty() or not support_node_families.has(node_family):
			continue
		restored_states[node_id] = normalize_support_node_state(node_family, entry)
	return restored_states


static func build_default_side_quest_node_state(node_family: String, config: Dictionary) -> Dictionary:
	return {
		"support_type": node_family,
		"mission_definition_id": String(config.get("default_definition_id", "")).strip_edges(),
		"mission_type": String(config.get("default_mission_type", "")).strip_edges(),
		"mission_status": _status_offered(config),
		"target_node_id": _no_pending_node_id(config),
		"target_enemy_definition_id": "",
		"quest_item_definition_id": "",
		"reward_offers": [],
		"training_step": "",
		"technique_offers": [],
	}


static func normalize_side_quest_node_state(
	side_quest_state: Dictionary,
	node_family: String,
	node_family_by_id: Dictionary,
	config: Dictionary
) -> Dictionary:
	var normalized_state: Dictionary = build_default_side_quest_node_state(node_family, config)
	var mission_definition_id: String = String(side_quest_state.get("mission_definition_id", config.get("default_definition_id", ""))).strip_edges()
	if not mission_definition_id.is_empty():
		normalized_state["mission_definition_id"] = mission_definition_id

	var mission_type: String = _normalize_side_quest_mission_type(
		String(side_quest_state.get("mission_type", config.get("default_mission_type", ""))),
		config
	)
	normalized_state["mission_type"] = mission_type

	var mission_status: String = String(side_quest_state.get("mission_status", _status_offered(config)))
	if mission_status not in [
		_status_offered(config),
		_status_accepted(config),
		_status_completed(config),
		_status_claimed(config),
	]:
		mission_status = _status_offered(config)
	normalized_state["mission_status"] = mission_status

	var target_node_id: int = int(side_quest_state.get("target_node_id", _no_pending_node_id(config)))
	var target_family: String = String(node_family_by_id.get(target_node_id, ""))
	if target_family.is_empty() or not _side_quest_target_family_is_valid(mission_type, target_family, config):
		target_node_id = _no_pending_node_id(config)
	normalized_state["target_node_id"] = target_node_id

	var target_enemy_definition_id: String = String(side_quest_state.get("target_enemy_definition_id", "")).strip_edges()
	if target_node_id == _no_pending_node_id(config) or mission_type != _mission_type_hunt(config):
		target_enemy_definition_id = ""
	normalized_state["target_enemy_definition_id"] = target_enemy_definition_id
	normalized_state["quest_item_definition_id"] = String(side_quest_state.get("quest_item_definition_id", "")).strip_edges()

	var reward_offers: Array[Dictionary] = []
	var reward_offers_variant: Variant = side_quest_state.get("reward_offers", [])
	if typeof(reward_offers_variant) == TYPE_ARRAY:
		for offer_variant in reward_offers_variant:
			if typeof(offer_variant) != TYPE_DICTIONARY:
				continue
			var offer: Dictionary = offer_variant
			var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
			if effect_type.is_empty():
				effect_type = "claim_side_mission_reward"
			var offer_id: String = String(offer.get("offer_id", "")).strip_edges()
			if offer_id.is_empty():
				offer_id = "claim_reward"
			match effect_type:
				"grant_gold":
					var gold_amount: int = max(1, int(offer.get("amount", 0)))
					reward_offers.append({
						"offer_id": offer_id if offer_id != "claim_reward" else "claim_gold_%d" % gold_amount,
						"label": String(offer.get("label", "")).strip_edges(),
						"effect_type": "grant_gold",
						"amount": gold_amount,
						"available": bool(offer.get("available", true)),
					})
				"grant_item", "claim_side_mission_reward":
					var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
					if not _side_quest_reward_inventory_family_is_supported(inventory_family):
						continue
					var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
					if definition_id.is_empty():
						continue
					var normalized_offer: Dictionary = {
						"offer_id": offer_id if offer_id != "claim_reward" else "claim_%s" % definition_id,
						"label": String(offer.get("label", "")).strip_edges(),
						"effect_type": "claim_side_mission_reward",
						"inventory_family": inventory_family,
						"definition_id": definition_id,
						"available": bool(offer.get("available", true)),
					}
					if inventory_family == InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE:
						normalized_offer["amount"] = max(1, int(offer.get("amount", 1)))
					reward_offers.append(normalized_offer)

	var training_step: String = _normalize_side_quest_training_step(
		String(side_quest_state.get("training_step", ""))
	)
	var technique_offers: Array[Dictionary] = []
	if training_step == "technique_choice":
		technique_offers = _extract_side_quest_technique_offers(side_quest_state.get("technique_offers", []))

	return normalized_state.merged({
		"reward_offers": reward_offers,
		"training_step": training_step,
		"technique_offers": technique_offers,
	}, true)


static func side_quest_state_should_persist(normalized_state: Dictionary, config: Dictionary) -> bool:
	var mission_status: String = String(normalized_state.get("mission_status", _status_offered(config)))
	var target_node_id: int = int(normalized_state.get("target_node_id", _no_pending_node_id(config)))
	var reward_offers_variant: Variant = normalized_state.get("reward_offers", [])
	return not (
		mission_status == _status_offered(config)
		and target_node_id == _no_pending_node_id(config)
		and typeof(reward_offers_variant) == TYPE_ARRAY
		and (reward_offers_variant as Array).is_empty()
	)


static func restore_side_quest_node_states(
	saved_side_quest_states_variant: Variant,
	node_family_by_id: Dictionary,
	hamlet_node_family: String,
	config: Dictionary
) -> Dictionary:
	var restored_states: Dictionary = {}
	if typeof(saved_side_quest_states_variant) != TYPE_ARRAY:
		return restored_states

	for entry_variant in saved_side_quest_states_variant:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", _no_pending_node_id(config)))
		var node_family: String = String(node_family_by_id.get(node_id, ""))
		if node_family != hamlet_node_family:
			continue
		restored_states[node_id] = normalize_side_quest_node_state(entry, node_family, node_family_by_id, config)
	return restored_states


static func build_target_enemy_definition_id(
	side_mission_node_states: Dictionary,
	target_node_id: int,
	config: Dictionary
) -> String:
	if target_node_id < 0:
		return ""
	for source_node_id_variant in side_mission_node_states.keys():
		var state: Dictionary = side_mission_node_states[source_node_id_variant] as Dictionary
		if String(state.get("mission_status", "")) != _status_accepted(config):
			continue
		if int(state.get("target_node_id", _no_pending_node_id(config))) != target_node_id:
			continue
		return String(state.get("target_enemy_definition_id", ""))
	return ""


static func mark_side_quest_target_completed(
	side_mission_node_states: Dictionary,
	target_node_id: int,
	node_family_by_id: Dictionary,
	config: Dictionary
) -> Dictionary:
	for source_node_id_variant in side_mission_node_states.keys():
		var source_node_id: int = int(source_node_id_variant)
		var state: Dictionary = (side_mission_node_states[source_node_id] as Dictionary).duplicate(true)
		if String(state.get("mission_status", "")) != _status_accepted(config):
			continue
		if int(state.get("target_node_id", _no_pending_node_id(config))) != target_node_id:
			continue
		state["mission_status"] = _status_completed(config)
		side_mission_node_states[source_node_id] = normalize_side_quest_node_state(
			state,
			String(node_family_by_id.get(source_node_id, "")),
			node_family_by_id,
			config
		)
		return (side_mission_node_states[source_node_id] as Dictionary).duplicate(true)
	return {}


static func build_side_quest_highlight_snapshot(side_mission_node_states: Dictionary, config: Dictionary) -> Dictionary:
	var source_node_ids: Array[int] = []
	for node_id_variant in side_mission_node_states.keys():
		source_node_ids.append(int(node_id_variant))
	source_node_ids.sort()
	for source_node_id in source_node_ids:
		var state: Dictionary = side_mission_node_states[source_node_id] as Dictionary
		var mission_status: String = String(state.get("mission_status", _status_offered(config)))
		if mission_status == _status_accepted(config):
			var target_node_id: int = int(state.get("target_node_id", _no_pending_node_id(config)))
			if target_node_id >= 0:
				return {
					"node_id": target_node_id,
					"highlight_state": "target",
				}
		elif mission_status == _status_completed(config):
			return {
				"node_id": source_node_id,
				"highlight_state": "return",
			}
	return {}


static func active_side_quest_by_target_node_id(
	side_mission_node_states: Dictionary,
	target_node_id: int,
	config: Dictionary
) -> Dictionary:
	for source_node_id_variant in side_mission_node_states.keys():
		var source_node_id: int = int(source_node_id_variant)
		var state: Dictionary = (side_mission_node_states[source_node_id] as Dictionary).duplicate(true)
		if String(state.get("mission_status", "")) != _status_accepted(config):
			continue
		if int(state.get("target_node_id", _no_pending_node_id(config))) != target_node_id:
			continue
		return state.merged({"source_node_id": source_node_id}, true)
	return {}


static func _side_quest_reward_inventory_family_is_supported(inventory_family: String) -> bool:
	return inventory_family in [
		InventoryStateScript.INVENTORY_FAMILY_WEAPON,
		InventoryStateScript.INVENTORY_FAMILY_SHIELD,
		InventoryStateScript.INVENTORY_FAMILY_ARMOR,
		InventoryStateScript.INVENTORY_FAMILY_BELT,
		InventoryStateScript.INVENTORY_FAMILY_PASSIVE,
		InventoryStateScript.INVENTORY_FAMILY_SHIELD_ATTACHMENT,
		InventoryStateScript.INVENTORY_FAMILY_CONSUMABLE,
	]


static func _normalize_side_quest_mission_type(mission_type: String, config: Dictionary) -> String:
	if mission_type in [
		_mission_type_hunt(config),
		_mission_type_deliver_supplies(config),
		_mission_type_rescue_missing_scout(config),
		_mission_type_bring_proof(config),
	]:
		return mission_type
	return _mission_type_hunt(config)


static func _normalize_side_quest_training_step(step_name: String) -> String:
	var normalized_step: String = step_name.strip_edges()
	if normalized_step == "technique_choice":
		return normalized_step
	return ""


static func _extract_side_quest_technique_offers(offer_array_variant: Variant) -> Array[Dictionary]:
	var normalized_offers: Array[Dictionary] = []
	if typeof(offer_array_variant) != TYPE_ARRAY:
		return normalized_offers
	for offer_variant in offer_array_variant:
		if typeof(offer_variant) != TYPE_DICTIONARY:
			continue
		var offer: Dictionary = offer_variant
		var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
		match effect_type:
			"equip_technique":
				var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
				if definition_id.is_empty():
					continue
				var normalized_offer: Dictionary = {
					"offer_id": String(offer.get("offer_id", "equip_%s" % definition_id)).strip_edges(),
					"label": String(offer.get("label", "")).strip_edges(),
					"effect_type": effect_type,
					"definition_id": definition_id,
					"available": bool(offer.get("available", true)),
				}
				var replaces_definition_id: String = String(offer.get("replaces_definition_id", "")).strip_edges()
				if not replaces_definition_id.is_empty():
					normalized_offer["replaces_definition_id"] = replaces_definition_id
				normalized_offers.append(normalized_offer)
			"skip_training_choice":
				normalized_offers.append({
					"offer_id": String(offer.get("offer_id", "skip_hamlet_training")).strip_edges(),
					"label": String(offer.get("label", "")).strip_edges(),
					"effect_type": effect_type,
					"available": bool(offer.get("available", true)),
				})
			_:
				continue
	return normalized_offers


static func _side_quest_target_family_is_valid(mission_type: String, target_family: String, config: Dictionary) -> bool:
	var valid_families: PackedStringArray = PackedStringArray(["combat"])
	match mission_type:
		_ when mission_type == _mission_type_deliver_supplies(config):
			valid_families = PackedStringArray(["event", "reward", "rest", "merchant", "blacksmith"])
		_ when mission_type == _mission_type_rescue_missing_scout(config):
			valid_families = PackedStringArray(["combat", "event", "reward"])
		_ when mission_type == _mission_type_bring_proof(config):
			valid_families = PackedStringArray(["combat", "event", "reward"])
	return valid_families.has(target_family)


static func _no_pending_node_id(config: Dictionary) -> int:
	return int(config.get("no_pending_node_id", -1))


static func _status_offered(config: Dictionary) -> String:
	return String(config.get("offered_status", "offered")).strip_edges()


static func _status_accepted(config: Dictionary) -> String:
	return String(config.get("accepted_status", "accepted")).strip_edges()


static func _status_completed(config: Dictionary) -> String:
	return String(config.get("completed_status", "completed")).strip_edges()


static func _status_claimed(config: Dictionary) -> String:
	return String(config.get("claimed_status", "claimed")).strip_edges()


static func _mission_type_hunt(config: Dictionary) -> String:
	return String(config.get("hunt_marked_enemy_type", "hunt_marked_enemy")).strip_edges()


static func _mission_type_deliver_supplies(config: Dictionary) -> String:
	return String(config.get("deliver_supplies_type", "deliver_supplies")).strip_edges()


static func _mission_type_rescue_missing_scout(config: Dictionary) -> String:
	return String(config.get("rescue_missing_scout_type", "rescue_missing_scout")).strip_edges()


static func _mission_type_bring_proof(config: Dictionary) -> String:
	return String(config.get("bring_proof_type", "bring_proof")).strip_edges()

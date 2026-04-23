# Layer: Infrastructure
extends RefCounted
class_name SaveValidationCommon

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")


static func equipped_technique_definition_id_is_valid(definition_id: String) -> bool:
	if definition_id.is_empty():
		return true
	var loader: ContentLoader = ContentLoaderScript.new()
	return not loader.load_definition("Techniques", definition_id).is_empty()


static func technique_offer_array_is_valid(loader: ContentLoader, offer_array: Array, require_training_choice_shape: bool) -> bool:
	var equip_offer_count: int = 0
	var skip_offer_count: int = 0
	for offer_variant in offer_array:
		if typeof(offer_variant) != TYPE_DICTIONARY:
			return false
		var offer: Dictionary = offer_variant
		if String(offer.get("offer_id", "")).strip_edges().is_empty():
			return false
		var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
		match effect_type:
			"equip_technique":
				equip_offer_count += 1
				var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
				if definition_id.is_empty():
					return false
				if loader.load_definition("Techniques", definition_id).is_empty():
					return false
			"skip_training_choice":
				skip_offer_count += 1
			_:
				return false
	if not require_training_choice_shape:
		return true
	return offer_array.size() == 3 and equip_offer_count == 2 and skip_offer_count == 1


static func map_node_states_contain_node(map_node_states: Array, node_id: int) -> bool:
	for entry_variant in map_node_states:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if int((entry_variant as Dictionary).get("node_id", -1)) == node_id:
			return true
	return false


static func realized_graph_contains_node(realized_graph: Array, node_id: int) -> bool:
	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		if int((entry_variant as Dictionary).get("node_id", -1)) == node_id:
			return true
	return false


static func map_contains_node(node_id: int, map_node_states: Array, realized_graph: Array) -> bool:
	if map_node_states_contain_node(map_node_states, node_id):
		return true
	return realized_graph_contains_node(realized_graph, node_id)


static func realized_graph_family_for_node(realized_graph: Array, node_id: int) -> String:
	for entry_variant in realized_graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_variant
		if int(entry.get("node_id", -1)) != node_id:
			continue
		var node_family: String = String(entry.get("node_family", ""))
		return "hamlet" if node_family == "side_mission" else node_family
	return ""


static func side_quest_target_family_is_valid(mission_type: String, target_family: String) -> bool:
	match mission_type:
		"deliver_supplies":
			return target_family in ["event", "reward", "rest", "merchant", "blacksmith"]
		"rescue_missing_scout", "bring_proof":
			return target_family in ["combat", "event", "reward"]
		_:
			return target_family == "combat"


static func side_quest_reward_inventory_family_is_supported(inventory_family: String) -> bool:
	return inventory_family in ["weapon", "shield", "armor", "belt", "passive", "shield_attachment", "consumable"]


static func side_quest_reward_offers_are_valid(reward_offers: Array) -> bool:
	for offer_variant in reward_offers:
		if typeof(offer_variant) != TYPE_DICTIONARY:
			return false
		var offer: Dictionary = offer_variant
		if String(offer.get("offer_id", "")).strip_edges().is_empty():
			return false
		var effect_type: String = String(offer.get("effect_type", "")).strip_edges()
		if effect_type.is_empty():
			effect_type = "claim_side_mission_reward"
		match effect_type:
			"grant_gold":
				if int(offer.get("amount", 0)) <= 0:
					return false
			"grant_item", "claim_side_mission_reward":
				var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
				if not side_quest_reward_inventory_family_is_supported(inventory_family):
					return false
				if String(offer.get("definition_id", "")).strip_edges().is_empty():
					return false
				if inventory_family == "consumable" and int(offer.get("amount", 0)) <= 0:
					return false
			_:
				return false
	return true


static func hamlet_support_interaction_state_is_valid(
	support_interaction_data: Dictionary,
	map_node_states: Array = [],
	realized_graph: Array = []
) -> bool:
	var loader: ContentLoader = ContentLoaderScript.new()
	var mission_definition_id: String = String(support_interaction_data.get("mission_definition_id", "")).strip_edges()
	if mission_definition_id.is_empty():
		return false
	var mission_type: String = String(support_interaction_data.get("mission_type", "hunt_marked_enemy"))
	if mission_type not in ["hunt_marked_enemy", "deliver_supplies", "rescue_missing_scout", "bring_proof"]:
		return false
	var mission_status: String = String(support_interaction_data.get("mission_status", ""))
	if mission_status not in ["offered", "accepted", "completed", "claimed"]:
		return false
	var source_node_id: int = int(support_interaction_data.get("source_node_id", -1))
	if source_node_id < 0 or not map_contains_node(source_node_id, map_node_states, realized_graph):
		return false
	var source_family: String = realized_graph_family_for_node(realized_graph, source_node_id)
	if not source_family.is_empty() and source_family != "hamlet":
		return false
	var target_node_id: int = int(support_interaction_data.get("target_node_id", -1))
	var target_enemy_definition_id: String = String(support_interaction_data.get("target_enemy_definition_id", "")).strip_edges()
	if target_node_id >= 0:
		if not map_contains_node(target_node_id, map_node_states, realized_graph):
			return false
		var target_family: String = realized_graph_family_for_node(realized_graph, target_node_id)
		if not target_family.is_empty() and not side_quest_target_family_is_valid(mission_type, target_family):
			return false
		if mission_type == "hunt_marked_enemy" and target_enemy_definition_id.is_empty():
			return false
	elif mission_status in ["accepted", "completed"]:
		return false
	var quest_item_definition_id: String = String(support_interaction_data.get("quest_item_definition_id", "")).strip_edges()
	if mission_type == "deliver_supplies" and mission_status in ["accepted", "completed"] and quest_item_definition_id.is_empty():
		return false
	var reward_offers_variant: Variant = support_interaction_data.get("reward_offers", [])
	if typeof(reward_offers_variant) != TYPE_ARRAY:
		return false
	if not side_quest_reward_offers_are_valid(reward_offers_variant as Array):
		return false
	var training_step: String = String(support_interaction_data.get("training_step", "")).strip_edges()
	if training_step not in ["", "technique_choice"]:
		return false
	var technique_offers_variant: Variant = support_interaction_data.get("technique_offers", [])
	if typeof(technique_offers_variant) != TYPE_ARRAY:
		return false
	if training_step == "technique_choice":
		if mission_status != "claimed":
			return false
		if not technique_offer_array_is_valid(loader, technique_offers_variant as Array, true):
			return false
	elif not technique_offer_array_is_valid(loader, technique_offers_variant as Array, false):
		return false
	return true

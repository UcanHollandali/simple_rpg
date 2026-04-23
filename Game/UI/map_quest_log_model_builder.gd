# Layer: UI
extends RefCounted
class_name MapQuestLogModelBuilder

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")
const SupportInteractionStateScript = preload("res://Game/RuntimeState/support_interaction_state.gd")
const MapDisplayNameHelperScript = preload("res://Game/UI/map_display_name_helper.gd")


static func build_model(run_state: RunState) -> Dictionary:
	if run_state == null or run_state.map_runtime_state == null:
		return _build_empty_model()

	var map_runtime_state: MapRuntimeState = run_state.map_runtime_state as MapRuntimeState
	if map_runtime_state == null:
		return _build_empty_model()

	var active_state: Dictionary = _find_logged_side_quest_state(map_runtime_state)
	if active_state.is_empty():
		return _build_empty_model()

	var mission_definition_id: String = String(active_state.get("mission_definition_id", "")).strip_edges()
	var loader: ContentLoader = ContentLoaderScript.new()
	var mission_definition: Dictionary = loader.load_definition(
		SupportInteractionStateScript.SIDE_MISSION_FAMILY,
		mission_definition_id
	)
	var display: Dictionary = mission_definition.get("display", {})
	var rules: Dictionary = mission_definition.get("rules", {})
	var mission_status: String = String(active_state.get("mission_status", "")).strip_edges()
	var mission_title_text: String = String(display.get("name", "Hamlet Request")).strip_edges()
	if mission_title_text.is_empty():
		mission_title_text = "Hamlet Request"

	var short_description: String = String(display.get("short_description", "")).strip_edges()
	var summary_text: String = _build_summary_text(rules, mission_status, short_description)
	var objective_text: String = _build_objective_text(map_runtime_state, active_state)
	var reward_offer_count: int = _extract_dictionary_array(active_state.get("reward_offers", [])).size()
	var hint_text: String = _build_hint_text(mission_status, reward_offer_count)
	var status_text: String = _build_status_text(mission_status)
	var launcher_hint_text: String = _build_launcher_hint_text(mission_status)
	var toast_text: String = _build_toast_text(mission_status, reward_offer_count)

	return {
		"has_active_contract": true,
		"status_text": status_text,
		"status_semantic": mission_status,
		"mission_title_text": mission_title_text,
		"summary_text": summary_text,
		"objective_title_text": "Objective",
		"objective_text": objective_text,
		"detail_text": short_description,
		"hint_text": hint_text,
		"launcher_chip_text": status_text,
		"launcher_hint_text": launcher_hint_text,
		"toast_text": toast_text,
	}


static func _find_logged_side_quest_state(map_runtime_state: MapRuntimeState) -> Dictionary:
	if map_runtime_state == null:
		return {}

	var fallback_completed_state: Dictionary = {}
	for node_snapshot_variant in map_runtime_state.build_node_snapshots():
		if typeof(node_snapshot_variant) != TYPE_DICTIONARY:
			continue
		var node_snapshot: Dictionary = node_snapshot_variant
		if String(node_snapshot.get("node_family", "")) != "hamlet":
			continue
		var source_node_id: int = int(node_snapshot.get("node_id", SupportInteractionStateScript.NO_SOURCE_NODE_ID))
		if source_node_id == SupportInteractionStateScript.NO_SOURCE_NODE_ID:
			continue
		var state: Dictionary = map_runtime_state.get_side_quest_node_runtime_state(source_node_id).duplicate(true)
		var mission_status: String = String(state.get("mission_status", "")).strip_edges()
		if mission_status == SupportInteractionStateScript.SIDE_MISSION_STATUS_ACCEPTED:
			return state.merged({"source_node_id": source_node_id}, true)
		if mission_status == SupportInteractionStateScript.SIDE_MISSION_STATUS_COMPLETED and fallback_completed_state.is_empty():
			fallback_completed_state = state.merged({"source_node_id": source_node_id}, true)
	return fallback_completed_state


static func _build_empty_model() -> Dictionary:
	return {
		"has_active_contract": false,
		"status_text": "EMPTY",
		"status_semantic": "empty",
		"mission_title_text": "No active contract",
		"summary_text": "Visit a Waypost to take a request, then track it here while it is active.",
		"objective_title_text": "",
		"objective_text": "",
		"detail_text": "",
		"hint_text": "Accepted or ready-to-claim hamlet requests stay visible here.",
		"launcher_chip_text": "",
		"launcher_hint_text": "",
		"toast_text": "",
	}


static func _build_summary_text(rules: Dictionary, mission_status: String, fallback_text: String) -> String:
	match mission_status:
		SupportInteractionStateScript.SIDE_MISSION_STATUS_ACCEPTED:
			return String(rules.get("accepted_text", fallback_text)).strip_edges()
		SupportInteractionStateScript.SIDE_MISSION_STATUS_COMPLETED:
			return String(rules.get("completed_text", fallback_text)).strip_edges()
		_:
			return fallback_text


static func _build_objective_text(map_runtime_state: MapRuntimeState, active_state: Dictionary) -> String:
	var mission_status: String = String(active_state.get("mission_status", "")).strip_edges()
	var source_node_id: int = int(active_state.get("source_node_id", SupportInteractionStateScript.NO_SOURCE_NODE_ID))
	if mission_status == SupportInteractionStateScript.SIDE_MISSION_STATUS_COMPLETED:
		return "Return to %s." % _display_name_for_node(map_runtime_state, source_node_id)

	var mission_type: String = String(active_state.get("mission_type", SupportInteractionStateScript.MISSION_TYPE_HUNT_MARKED_ENEMY)).strip_edges()
	var target_node_id: int = int(active_state.get("target_node_id", SupportInteractionStateScript.NO_SOURCE_NODE_ID))
	var target_name: String = _display_name_for_node(map_runtime_state, target_node_id)
	match mission_type:
		SupportInteractionStateScript.MISSION_TYPE_DELIVER_SUPPLIES:
			return "Carry the bundle to %s." % target_name
		SupportInteractionStateScript.MISSION_TYPE_RESCUE_MISSING_SCOUT:
			return "Reach %s and resolve the marked pocket." % target_name
		SupportInteractionStateScript.MISSION_TYPE_BRING_PROOF:
			return "Finish %s, secure proof, then return alive." % target_name
		_:
			return "Hunt the marked threat at %s." % target_name


static func _build_hint_text(mission_status: String, reward_offer_count: int) -> String:
	match mission_status:
		SupportInteractionStateScript.SIDE_MISSION_STATUS_ACCEPTED:
			return "The marked route is already highlighted on the board."
		SupportInteractionStateScript.SIDE_MISSION_STATUS_COMPLETED:
			if reward_offer_count > 0:
				return "Return to the Waypost to claim 1 of %d rewards." % reward_offer_count
			return "Return to the Waypost to settle the contract."
		_:
			return ""


static func _build_launcher_hint_text(mission_status: String) -> String:
	match mission_status:
		SupportInteractionStateScript.SIDE_MISSION_STATUS_ACCEPTED:
			return "Target known"
		SupportInteractionStateScript.SIDE_MISSION_STATUS_COMPLETED:
			return "Return to Waypost"
		_:
			return ""


static func _build_toast_text(mission_status: String, reward_offer_count: int) -> String:
	match mission_status:
		SupportInteractionStateScript.SIDE_MISSION_STATUS_ACCEPTED:
			return "Contract tracked. Marked target known."
		SupportInteractionStateScript.SIDE_MISSION_STATUS_COMPLETED:
			if reward_offer_count > 0:
				return "Contract ready. Return to the Waypost."
			return "Contract updated."
		_:
			return ""


static func _build_status_text(mission_status: String) -> String:
	match mission_status:
		SupportInteractionStateScript.SIDE_MISSION_STATUS_ACCEPTED:
			return "ACTIVE"
		SupportInteractionStateScript.SIDE_MISSION_STATUS_COMPLETED:
			return "READY"
		_:
			return "EMPTY"


static func _display_name_for_node(map_runtime_state: MapRuntimeState, node_id: int) -> String:
	if map_runtime_state == null or node_id == SupportInteractionStateScript.NO_SOURCE_NODE_ID:
		return "the marked route"
	var node_family: String = String(map_runtime_state.get_node_family(node_id)).strip_edges()
	if node_family.is_empty():
		return "the marked route"
	var hamlet_personality: String = map_runtime_state.get_hamlet_personality(node_id)
	var display_name: String = MapDisplayNameHelperScript.build_family_display_name(node_family, hamlet_personality)
	return "%s (Node %d)" % [display_name, node_id]


static func _extract_dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for entry_variant in value:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		result.append((entry_variant as Dictionary).duplicate(true))
	return result

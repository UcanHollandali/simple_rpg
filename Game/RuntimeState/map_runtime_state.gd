# Layer: RuntimeState
extends RefCounted
class_name MapRuntimeState

const ContentLoaderScript = preload("res://Game/Infrastructure/content_loader.gd")

const NODE_STATE_UNDISCOVERED: String = "undiscovered"
const NODE_STATE_DISCOVERED: String = "discovered"
const NODE_STATE_RESOLVED: String = "resolved"
const NODE_STATE_LOCKED: String = "locked"

const DEFAULT_NODE_INDEX: int = 0
const NO_PENDING_NODE_ID: int = -1
const MAP_TEMPLATE_FAMILY: String = "MapTemplates"
const DEFAULT_LEGACY_TEMPLATE_ID: String = "fixed_stage_cluster"
const DEFAULT_SCAFFOLD_TEMPLATE_ID: String = "procedural_stage_corridor_v1"
const STAGE_SCAFFOLD_TEMPLATE_IDS: PackedStringArray = [
	"procedural_stage_corridor_v1",
	"procedural_stage_openfield_v1",
	"procedural_stage_loop_v1",
]
const SCATTER_NODE_COUNT: int = 14
const SCATTER_MAX_NODE_DEGREE: int = 4
const SCATTER_EXTRA_EDGES_MIN: int = 2
const SCATTER_EXTRA_EDGES_MAX: int = 4
const SCATTER_ATTEMPT_LIMIT: int = 16
const LEGACY_STAGE_TEMPLATE_IDS: PackedStringArray = [
	"fixed_stage_cluster",
	"fixed_stage_detour",
]
const SAVE_KEY_ACTIVE_TEMPLATE_ID: String = "active_map_template_id"
const SAVE_KEY_REALIZED_GRAPH: String = "map_realized_graph"
const SAVE_KEY_SIDE_MISSION_NODE_STATES: String = "side_mission_node_states"
const SAVE_KEY_ROADSIDE_ENCOUNTERS_THIS_STAGE: String = "roadside_encounters_this_stage"
const SLOT_TYPE_OPENING_SUPPORT: String = "opening_support"
const SLOT_TYPE_LATE_PRIMARY: String = "late_primary"
const SLOT_TYPE_LATE_EVENT: String = "late_event"
const SLOT_TYPE_LATE_SIDE_MISSION: String = "late_side_mission"
const SIDE_MISSION_DEFAULT_DEFINITION_ID: String = "trail_contract_hunt"
const MAX_ROADSIDE_ENCOUNTERS_PER_STAGE: int = 1
const SIDE_MISSION_STATUS_OFFERED: String = "offered"
const SIDE_MISSION_STATUS_ACCEPTED: String = "accepted"
const SIDE_MISSION_STATUS_COMPLETED: String = "completed"
const SIDE_MISSION_STATUS_CLAIMED: String = "claimed"
const STAGE_SUPPORT_LAYOUTS: Array[Dictionary] = [
	{
		"opening_support_family": "rest",
		"late_support_family": "merchant",
	},
	{
		"opening_support_family": "merchant",
		"late_support_family": "blacksmith",
	},
	{
		"opening_support_family": "rest",
		"late_support_family": "blacksmith",
	},
]

var current_node_id: int = DEFAULT_NODE_INDEX
var pending_node_id: int = NO_PENDING_NODE_ID
var pending_node_type: String = ""
var stage_key_resolved: bool = false
var roadside_encounters_this_stage: int = 0
var _node_graph: Array[Dictionary] = []
var _support_node_states: Dictionary = {}
var _side_mission_node_states: Dictionary = {}
var _active_template_id: String = DEFAULT_SCAFFOLD_TEMPLATE_ID

var current_node_index: int:
	get:
		return current_node_id
	set(value):
		current_node_id = value


func reset_for_new_run(stage_index: int = 1) -> void:
	_reset_runtime_state()
	_active_template_id = _resolve_scaffold_id_for_stage(stage_index)
	_node_graph = _build_scaffold_graph(_active_template_id, stage_index)
	_set_node_state(DEFAULT_NODE_INDEX, NODE_STATE_RESOLVED)
	_reveal_adjacent_nodes(DEFAULT_NODE_INDEX)


func reset_for_next_stage(stage_index: int = 1) -> void:
	reset_for_new_run(stage_index)


func has_node(node_id: int) -> bool:
	return _find_node_graph_index(node_id) >= 0


func get_node_count() -> int:
	return _node_graph.size()


func get_current_node_family() -> String:
	return get_node_family(current_node_id)


func get_stage_key_node_id() -> int:
	return _find_first_node_id_by_family("key")


func get_boss_node_id() -> int:
	return _find_first_node_id_by_family("boss")


func get_active_template_id() -> String:
	return _active_template_id


func get_node_family(node_id: int) -> String:
	var node_data: Dictionary = _get_node_data(node_id)
	return String(node_data.get("node_family", ""))


func get_node_state(node_id: int) -> String:
	var node_data: Dictionary = _get_node_data(node_id)
	return String(node_data.get("node_state", NODE_STATE_UNDISCOVERED))


func get_adjacent_node_ids(node_id: int = current_node_id) -> PackedInt32Array:
	var node_data: Dictionary = _get_node_data(node_id)
	var adjacent_variant: Variant = node_data.get("adjacent_node_ids", PackedInt32Array())
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant
	if typeof(adjacent_variant) == TYPE_ARRAY:
		var adjacent_ids: PackedInt32Array = PackedInt32Array()
		for value in adjacent_variant:
			adjacent_ids.append(int(value))
		return adjacent_ids
	return PackedInt32Array()


func get_discovered_adjacent_node_ids(node_id: int = current_node_id) -> PackedInt32Array:
	var discovered_ids: PackedInt32Array = PackedInt32Array()
	for adjacent_node_id in get_adjacent_node_ids(node_id):
		if is_node_discovered(adjacent_node_id):
			discovered_ids.append(adjacent_node_id)
	return discovered_ids


func get_frontier_fog_count() -> int:
	var frontier_count: int = 0
	for node_data in _node_graph:
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) != NODE_STATE_UNDISCOVERED:
			continue
		var adjacent_variant: Variant = node_data.get("adjacent_node_ids", [])
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(adjacent_variant)
		for adjacent_node_id in adjacent_ids:
			if is_node_discovered(adjacent_node_id):
				frontier_count += 1
				break
	return frontier_count


func get_discovered_node_count() -> int:
	var discovered_count: int = 0
	for node_data in _node_graph:
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) != NODE_STATE_UNDISCOVERED:
			discovered_count += 1
	return discovered_count


func get_resolved_node_count() -> int:
	var resolved_count: int = 0
	for node_data in _node_graph:
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) == NODE_STATE_RESOLVED:
			resolved_count += 1
	return resolved_count


func is_stage_key_resolved() -> bool:
	return stage_key_resolved


func is_boss_gate_unlocked() -> bool:
	return stage_key_resolved


func is_node_discovered(node_id: int) -> bool:
	return get_node_state(node_id) != NODE_STATE_UNDISCOVERED


func is_node_locked(node_id: int) -> bool:
	return get_node_state(node_id) == NODE_STATE_LOCKED


func is_node_resolved(node_id: int) -> bool:
	return get_node_state(node_id) == NODE_STATE_RESOLVED


func is_support_node(node_id: int) -> bool:
	return _is_support_node_family(get_node_family(node_id))


func is_side_mission_node(node_id: int) -> bool:
	return get_node_family(node_id) == "side_mission"


func can_move_to_node(node_id: int) -> bool:
	if not has_node(node_id):
		return false
	if not get_adjacent_node_ids().has(node_id):
		return false
	var node_state: String = get_node_state(node_id)
	return node_state != NODE_STATE_UNDISCOVERED and node_state != NODE_STATE_LOCKED


func can_trigger_roadside_encounter() -> bool:
	return roadside_encounters_this_stage < MAX_ROADSIDE_ENCOUNTERS_PER_STAGE


func consume_roadside_encounter_slot() -> bool:
	if not can_trigger_roadside_encounter():
		return false
	roadside_encounters_this_stage += 1
	return true


func get_roadside_encounters_this_stage() -> int:
	return roadside_encounters_this_stage


func node_requires_resolution(node_id: int) -> bool:
	if not has_node(node_id):
		return false
	var node_family: String = get_node_family(node_id)
	if node_family == "start":
		return false
	var node_state: String = get_node_state(node_id)
	if node_family == "side_mission":
		if node_state in [NODE_STATE_UNDISCOVERED, NODE_STATE_LOCKED]:
			return false
		var mission_status: String = String(get_side_mission_node_runtime_state(node_id).get("mission_status", SIDE_MISSION_STATUS_OFFERED))
		return mission_status != SIDE_MISSION_STATUS_CLAIMED
	if _is_support_node_family(node_family):
		return node_state == NODE_STATE_DISCOVERED
	return node_state == NODE_STATE_DISCOVERED


func move_to_node(node_id: int) -> void:
	if not has_node(node_id):
		return
	current_node_id = node_id
	if get_node_state(node_id) == NODE_STATE_UNDISCOVERED:
		_set_node_state(node_id, NODE_STATE_DISCOVERED)
	_reveal_adjacent_nodes(node_id)


func resolve_stage_key() -> void:
	stage_key_resolved = true
	_sync_boss_gate_state()


func mark_node_resolved(node_id: int) -> void:
	if not has_node(node_id):
		return
	if get_node_state(node_id) == NODE_STATE_LOCKED:
		return
	_set_node_state(node_id, NODE_STATE_RESOLVED)


func set_pending_node(node_id: int) -> void:
	if not has_node(node_id):
		pending_node_id = NO_PENDING_NODE_ID
		pending_node_type = ""
		return
	pending_node_id = node_id
	pending_node_type = get_node_family(node_id)


func consume_pending_node_data() -> Dictionary:
	var pending_data: Dictionary = {
		"pending_node_id": pending_node_id,
		"pending_node_type": pending_node_type,
	}
	pending_node_id = NO_PENDING_NODE_ID
	pending_node_type = ""
	return pending_data


func find_adjacent_node_id(node_reference: Variant) -> int:
	if typeof(node_reference) == TYPE_INT:
		var target_node_id: int = int(node_reference)
		return target_node_id if get_adjacent_node_ids().has(target_node_id) else NO_PENDING_NODE_ID

	var reference_text: String = String(node_reference)
	if reference_text.is_valid_int():
		var parsed_node_id: int = int(reference_text)
		return parsed_node_id if get_adjacent_node_ids().has(parsed_node_id) else NO_PENDING_NODE_ID

	for adjacent_node_id in get_adjacent_node_ids():
		if get_node_family(adjacent_node_id) == reference_text:
			return adjacent_node_id
	return NO_PENDING_NODE_ID


func build_adjacent_node_snapshots() -> Array[Dictionary]:
	var node_snapshots: Array[Dictionary] = []
	for node_id in get_adjacent_node_ids():
		node_snapshots.append(_build_node_snapshot(node_id))
	return node_snapshots


func build_node_snapshots() -> Array[Dictionary]:
	var node_snapshots: Array[Dictionary] = []
	for node_data in _node_graph:
		node_snapshots.append({
			"node_id": int(node_data.get("node_id", NO_PENDING_NODE_ID)),
			"node_family": String(node_data.get("node_family", "")),
			"node_state": String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)),
		})
	return node_snapshots


func build_realized_graph_snapshots() -> Array[Dictionary]:
	return _build_realized_graph_save_payload()


func get_support_node_runtime_state(node_id: int) -> Dictionary:
	if not has_node(node_id) or not is_support_node(node_id):
		return {}
	if _support_node_states.has(node_id):
		return (_support_node_states[node_id] as Dictionary).duplicate(true)
	return {
		"support_type": get_node_family(node_id),
		"unavailable_offer_ids": [],
	}


func get_side_mission_node_runtime_state(node_id: int) -> Dictionary:
	if not has_node(node_id) or not is_side_mission_node(node_id):
		return {}
	if _side_mission_node_states.has(node_id):
		return (_side_mission_node_states[node_id] as Dictionary).duplicate(true)
	return _build_default_side_mission_node_state(node_id)


func save_support_node_runtime_state(node_id: int, support_node_state: Dictionary) -> void:
	if not has_node(node_id) or not is_support_node(node_id):
		return

	var normalized_state: Dictionary = _normalize_support_node_state(node_id, support_node_state)
	var unavailable_ids_variant: Variant = normalized_state.get("unavailable_offer_ids", [])
	if typeof(unavailable_ids_variant) == TYPE_ARRAY and (unavailable_ids_variant as Array).is_empty():
		_support_node_states.erase(node_id)
		return
	_support_node_states[node_id] = normalized_state


func save_side_mission_node_runtime_state(node_id: int, side_mission_state: Dictionary) -> void:
	if not has_node(node_id) or not is_side_mission_node(node_id):
		return

	var normalized_state: Dictionary = _normalize_side_mission_node_state(node_id, side_mission_state)
	var mission_status: String = String(normalized_state.get("mission_status", SIDE_MISSION_STATUS_OFFERED))
	var target_node_id: int = int(normalized_state.get("target_node_id", NO_PENDING_NODE_ID))
	var reward_offers_variant: Variant = normalized_state.get("reward_offers", [])
	if mission_status == SIDE_MISSION_STATUS_OFFERED and target_node_id == NO_PENDING_NODE_ID and typeof(reward_offers_variant) == TYPE_ARRAY and (reward_offers_variant as Array).is_empty():
		_side_mission_node_states.erase(node_id)
		return
	_side_mission_node_states[node_id] = normalized_state


func list_eligible_side_mission_target_node_ids(excluded_node_id: int = NO_PENDING_NODE_ID) -> Array[int]:
	var target_node_ids: Array[int] = []
	for node_data in _node_graph:
		var node_id: int = int(node_data.get("node_id", NO_PENDING_NODE_ID))
		if node_id == excluded_node_id:
			continue
		if String(node_data.get("node_family", "")) != "combat":
			continue
		if String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)) == NODE_STATE_RESOLVED:
			continue
		target_node_ids.append(node_id)
	return target_node_ids


func reveal_node(node_id: int) -> void:
	if not has_node(node_id):
		return
	if get_node_state(node_id) != NODE_STATE_UNDISCOVERED:
		return
	var node_family: String = get_node_family(node_id)
	if node_family == "boss" and not stage_key_resolved:
		_set_node_state(node_id, NODE_STATE_LOCKED)
		return
	_set_node_state(node_id, NODE_STATE_DISCOVERED)


func get_side_mission_target_enemy_definition_id(node_id: int) -> String:
	if node_id < 0:
		return ""
	for source_node_id_variant in _side_mission_node_states.keys():
		var source_node_id: int = int(source_node_id_variant)
		var state: Dictionary = _side_mission_node_states[source_node_id] as Dictionary
		if String(state.get("mission_status", "")) != SIDE_MISSION_STATUS_ACCEPTED:
			continue
		if int(state.get("target_node_id", NO_PENDING_NODE_ID)) != node_id:
			continue
		return String(state.get("target_enemy_definition_id", ""))
	return ""


func mark_side_mission_target_completed(target_node_id: int) -> Dictionary:
	for source_node_id_variant in _side_mission_node_states.keys():
		var source_node_id: int = int(source_node_id_variant)
		var state: Dictionary = (_side_mission_node_states[source_node_id] as Dictionary).duplicate(true)
		if String(state.get("mission_status", "")) != SIDE_MISSION_STATUS_ACCEPTED:
			continue
		if int(state.get("target_node_id", NO_PENDING_NODE_ID)) != target_node_id:
			continue
		state["mission_status"] = SIDE_MISSION_STATUS_COMPLETED
		_side_mission_node_states[source_node_id] = _normalize_side_mission_node_state(source_node_id, state)
		return (_side_mission_node_states[source_node_id] as Dictionary).duplicate(true)
	return {}


func build_side_mission_highlight_snapshot() -> Dictionary:
	var source_node_ids: Array[int] = []
	for node_id_variant in _side_mission_node_states.keys():
		source_node_ids.append(int(node_id_variant))
	source_node_ids.sort()
	for source_node_id in source_node_ids:
		var state: Dictionary = _side_mission_node_states[source_node_id] as Dictionary
		var mission_status: String = String(state.get("mission_status", SIDE_MISSION_STATUS_OFFERED))
		if mission_status == SIDE_MISSION_STATUS_ACCEPTED:
			var target_node_id: int = int(state.get("target_node_id", NO_PENDING_NODE_ID))
			if target_node_id >= 0:
				return {
					"node_id": target_node_id,
					"highlight_state": "target",
				}
		elif mission_status == SIDE_MISSION_STATUS_COMPLETED:
			return {
				"node_id": source_node_id,
				"highlight_state": "return",
			}
	return {}


func to_save_dict() -> Dictionary:
	return {
		SAVE_KEY_ACTIVE_TEMPLATE_ID: _active_template_id,
		"current_node_index": current_node_id,
		"current_node_id": current_node_id,
		"pending_node_id": pending_node_id,
		"pending_node_type": pending_node_type,
		"stage_key_resolved": stage_key_resolved,
		"boss_gate_unlocked": is_boss_gate_unlocked(),
		SAVE_KEY_ROADSIDE_ENCOUNTERS_THIS_STAGE: roadside_encounters_this_stage,
		SAVE_KEY_REALIZED_GRAPH: _build_realized_graph_save_payload(),
		"map_node_states": _build_node_state_save_payload(),
		"support_node_states": _build_support_node_state_save_payload(),
		SAVE_KEY_SIDE_MISSION_NODE_STATES: _build_side_mission_node_state_save_payload(),
	}


func load_from_save_dict(save_data: Dictionary, stage_index: int = 1) -> void:
	_reset_runtime_state()
	var restored_template_id: String = String(save_data.get(SAVE_KEY_ACTIVE_TEMPLATE_ID, ""))
	var restored_realized_graph: Array[Dictionary] = _extract_realized_graph_array(save_data.get(SAVE_KEY_REALIZED_GRAPH, []))
	if not restored_realized_graph.is_empty():
		_active_template_id = restored_template_id if not restored_template_id.is_empty() else _resolve_scaffold_id_for_stage(stage_index)
		_node_graph = _build_graph_from_realized_payload(restored_realized_graph)
	else:
		_active_template_id = _resolve_legacy_template_id_for_stage(stage_index)
		_node_graph = _build_legacy_fixed_graph(_active_template_id)

	var restored_current_node_id: int = int(save_data.get("current_node_id", save_data.get("current_node_index", DEFAULT_NODE_INDEX)))
	if has_node(restored_current_node_id):
		current_node_id = restored_current_node_id

	var restored_pending_node_id: int = int(save_data.get("pending_node_id", NO_PENDING_NODE_ID))
	pending_node_id = restored_pending_node_id if has_node(restored_pending_node_id) else NO_PENDING_NODE_ID
	pending_node_type = String(save_data.get("pending_node_type", get_node_family(pending_node_id) if pending_node_id >= 0 else ""))
	stage_key_resolved = bool(save_data.get("stage_key_resolved", save_data.get("boss_gate_unlocked", false)))
	roadside_encounters_this_stage = max(0, int(save_data.get(SAVE_KEY_ROADSIDE_ENCOUNTERS_THIS_STAGE, 0)))

	var saved_node_states_variant: Variant = save_data.get("map_node_states", [])
	if restored_realized_graph.is_empty() and typeof(saved_node_states_variant) == TYPE_ARRAY:
		for entry_variant in saved_node_states_variant:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_variant
			var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
			var node_state: String = String(entry.get("node_state", NODE_STATE_UNDISCOVERED))
			if not has_node(node_id):
				continue
			if not _is_valid_node_state(node_state):
				continue
			_set_node_state(node_id, node_state)

	var saved_support_states_variant: Variant = save_data.get("support_node_states", [])
	if typeof(saved_support_states_variant) == TYPE_ARRAY:
		for entry_variant in saved_support_states_variant:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_variant
			var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
			if not has_node(node_id) or not is_support_node(node_id):
				continue
			_support_node_states[node_id] = _normalize_support_node_state(node_id, entry)

	var saved_side_mission_states_variant: Variant = save_data.get(SAVE_KEY_SIDE_MISSION_NODE_STATES, [])
	if typeof(saved_side_mission_states_variant) == TYPE_ARRAY:
		for entry_variant in saved_side_mission_states_variant:
			if typeof(entry_variant) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = entry_variant
			var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
			if not has_node(node_id) or not is_side_mission_node(node_id):
				continue
			_side_mission_node_states[node_id] = _normalize_side_mission_node_state(node_id, entry)

	_sync_boss_gate_state()


func _build_legacy_fixed_graph(template_id: String) -> Array[Dictionary]:
	var graph: Array[Dictionary] = []
	for template_node in _load_graph_template_nodes(template_id):
		graph.append({
			"node_id": int(template_node.get("node_id", NO_PENDING_NODE_ID)),
			"node_family": String(template_node.get("node_family", "")),
			"node_state": NODE_STATE_UNDISCOVERED,
			"adjacent_node_ids": _coerce_adjacent_ids(template_node.get("adjacent_node_ids", [])),
		})
	return graph


func _load_graph_template_nodes(template_id: String) -> Array[Dictionary]:
	var loader: ContentLoader = ContentLoaderScript.new()
	var template_definition: Dictionary = loader.load_definition(MAP_TEMPLATE_FAMILY, template_id)
	if template_definition.is_empty() and template_id != DEFAULT_SCAFFOLD_TEMPLATE_ID:
		template_definition = loader.load_definition(MAP_TEMPLATE_FAMILY, DEFAULT_SCAFFOLD_TEMPLATE_ID)
	var rules: Dictionary = template_definition.get("rules", {})
	return _extract_template_node_array(rules.get("nodes", []))


func _resolve_scaffold_id_for_stage(stage_index: int) -> String:
	if STAGE_SCAFFOLD_TEMPLATE_IDS.is_empty():
		return DEFAULT_SCAFFOLD_TEMPLATE_ID
	var stage_offset: int = max(0, stage_index - 1)
	return String(STAGE_SCAFFOLD_TEMPLATE_IDS[stage_offset % STAGE_SCAFFOLD_TEMPLATE_IDS.size()])


func _resolve_legacy_template_id_for_stage(stage_index: int) -> String:
	if LEGACY_STAGE_TEMPLATE_IDS.is_empty():
		return ""
	var stage_offset: int = max(0, stage_index - 1)
	return String(LEGACY_STAGE_TEMPLATE_IDS[stage_offset % LEGACY_STAGE_TEMPLATE_IDS.size()])


func _extract_template_node_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result

	for entry in value:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		result.append((entry as Dictionary).duplicate(true))
	return result


func _build_node_snapshot(node_id: int) -> Dictionary:
	return {
		"node_id": node_id,
		"node_family": get_node_family(node_id),
		"node_state": get_node_state(node_id),
	}


func _build_node_state_save_payload() -> Array[Dictionary]:
	var node_states: Array[Dictionary] = []
	for node_data in _node_graph:
		node_states.append({
			"node_id": int(node_data.get("node_id", NO_PENDING_NODE_ID)),
			"node_state": String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)),
		})
	return node_states


func _build_support_node_state_save_payload() -> Array[Dictionary]:
	var support_states: Array[Dictionary] = []
	for node_id in _support_node_states.keys():
		support_states.append({
			"node_id": int(node_id),
		}.merged((_support_node_states[node_id] as Dictionary).duplicate(true), true))
	return support_states


func _build_side_mission_node_state_save_payload() -> Array[Dictionary]:
	var mission_states: Array[Dictionary] = []
	for node_id in _side_mission_node_states.keys():
		mission_states.append({
			"node_id": int(node_id),
		}.merged((_side_mission_node_states[node_id] as Dictionary).duplicate(true), true))
	return mission_states


func _build_realized_graph_save_payload() -> Array[Dictionary]:
	var realized_graph: Array[Dictionary] = []
	for node_data in _node_graph:
		realized_graph.append({
			"node_id": int(node_data.get("node_id", NO_PENDING_NODE_ID)),
			"node_family": String(node_data.get("node_family", "")),
			"node_state": String(node_data.get("node_state", NODE_STATE_UNDISCOVERED)),
			"adjacent_node_ids": _coerce_adjacent_ids(node_data.get("adjacent_node_ids", [])),
		})
	return realized_graph


func _reveal_adjacent_nodes(node_id: int) -> void:
	for adjacent_node_id in get_adjacent_node_ids(node_id):
		if get_node_state(adjacent_node_id) != NODE_STATE_UNDISCOVERED:
			continue
		var node_family: String = get_node_family(adjacent_node_id)
		if node_family == "boss" and not stage_key_resolved:
			_set_node_state(adjacent_node_id, NODE_STATE_LOCKED)
		else:
			_set_node_state(adjacent_node_id, NODE_STATE_DISCOVERED)


func _find_node_graph_index(node_id: int) -> int:
	for index in range(_node_graph.size()):
		if int(_node_graph[index].get("node_id", NO_PENDING_NODE_ID)) == node_id:
			return index
	return -1


func _get_node_data(node_id: int) -> Dictionary:
	var node_index: int = _find_node_graph_index(node_id)
	if node_index < 0:
		return {}
	return _node_graph[node_index]


func _find_first_node_id_by_family(node_family: String) -> int:
	for node_data in _node_graph:
		if String(node_data.get("node_family", "")) == node_family:
			return int(node_data.get("node_id", NO_PENDING_NODE_ID))
	return NO_PENDING_NODE_ID


func _set_node_state(node_id: int, node_state: String) -> void:
	var node_index: int = _find_node_graph_index(node_id)
	if node_index < 0 or not _is_valid_node_state(node_state):
		return
	var updated_node: Dictionary = _node_graph[node_index].duplicate(true)
	updated_node["node_state"] = node_state
	_node_graph[node_index] = updated_node


func _is_valid_node_state(node_state: String) -> bool:
	return node_state in [
		NODE_STATE_UNDISCOVERED,
		NODE_STATE_DISCOVERED,
		NODE_STATE_RESOLVED,
		NODE_STATE_LOCKED,
	]


func _is_support_node_family(node_family: String) -> bool:
	return node_family in ["rest", "merchant", "blacksmith"]


func _normalize_support_node_state(node_id: int, support_node_state: Dictionary) -> Dictionary:
	var unavailable_ids: Array[String] = []
	var unavailable_ids_variant: Variant = support_node_state.get("unavailable_offer_ids", [])
	if typeof(unavailable_ids_variant) == TYPE_ARRAY:
		for offer_id_variant in unavailable_ids_variant:
			var offer_id: String = String(offer_id_variant)
			if offer_id.is_empty() or unavailable_ids.has(offer_id):
				continue
			unavailable_ids.append(offer_id)

	return {
		"support_type": get_node_family(node_id),
		"unavailable_offer_ids": unavailable_ids,
	}


func _build_default_side_mission_node_state(node_id: int) -> Dictionary:
	return {
		"support_type": get_node_family(node_id),
		"mission_definition_id": SIDE_MISSION_DEFAULT_DEFINITION_ID,
		"mission_status": SIDE_MISSION_STATUS_OFFERED,
		"target_node_id": NO_PENDING_NODE_ID,
		"target_enemy_definition_id": "",
		"reward_offers": [],
	}


func _normalize_side_mission_node_state(node_id: int, side_mission_state: Dictionary) -> Dictionary:
	var normalized_state: Dictionary = _build_default_side_mission_node_state(node_id)
	var mission_definition_id: String = String(side_mission_state.get("mission_definition_id", SIDE_MISSION_DEFAULT_DEFINITION_ID)).strip_edges()
	if not mission_definition_id.is_empty():
		normalized_state["mission_definition_id"] = mission_definition_id

	var mission_status: String = String(side_mission_state.get("mission_status", SIDE_MISSION_STATUS_OFFERED))
	if mission_status not in [
		SIDE_MISSION_STATUS_OFFERED,
		SIDE_MISSION_STATUS_ACCEPTED,
		SIDE_MISSION_STATUS_COMPLETED,
		SIDE_MISSION_STATUS_CLAIMED,
	]:
		mission_status = SIDE_MISSION_STATUS_OFFERED
	normalized_state["mission_status"] = mission_status

	var target_node_id: int = int(side_mission_state.get("target_node_id", NO_PENDING_NODE_ID))
	if not has_node(target_node_id) or get_node_family(target_node_id) != "combat":
		target_node_id = NO_PENDING_NODE_ID
	normalized_state["target_node_id"] = target_node_id

	var target_enemy_definition_id: String = String(side_mission_state.get("target_enemy_definition_id", "")).strip_edges()
	if target_node_id == NO_PENDING_NODE_ID:
		target_enemy_definition_id = ""
	normalized_state["target_enemy_definition_id"] = target_enemy_definition_id

	var reward_offers: Array[Dictionary] = []
	var reward_offers_variant: Variant = side_mission_state.get("reward_offers", [])
	if typeof(reward_offers_variant) == TYPE_ARRAY:
		for offer_variant in reward_offers_variant:
			if typeof(offer_variant) != TYPE_DICTIONARY:
				continue
			var offer: Dictionary = offer_variant
			var inventory_family: String = String(offer.get("inventory_family", "")).strip_edges()
			if inventory_family not in ["weapon", "armor"]:
				continue
			var definition_id: String = String(offer.get("definition_id", "")).strip_edges()
			if definition_id.is_empty():
				continue
			var offer_id: String = String(offer.get("offer_id", "")).strip_edges()
			if offer_id.is_empty():
				offer_id = "claim_%s" % definition_id
			reward_offers.append({
				"offer_id": offer_id,
				"label": String(offer.get("label", "")).strip_edges(),
				"effect_type": "claim_side_mission_reward",
				"inventory_family": inventory_family,
				"definition_id": definition_id,
				"available": bool(offer.get("available", true)),
			})
	return normalized_state.merged({
		"reward_offers": reward_offers,
	}, true)


func _sync_boss_gate_state() -> void:
	var boss_node_id: int = get_boss_node_id()
	if boss_node_id == NO_PENDING_NODE_ID:
		return

	var boss_node_state: String = get_node_state(boss_node_id)
	if stage_key_resolved:
		if boss_node_state == NODE_STATE_LOCKED:
			_set_node_state(boss_node_id, NODE_STATE_DISCOVERED)
		return

	if boss_node_state == NODE_STATE_DISCOVERED:
		_set_node_state(boss_node_id, NODE_STATE_LOCKED)


func _coerce_adjacent_ids(adjacent_variant: Variant) -> PackedInt32Array:
	if typeof(adjacent_variant) == TYPE_PACKED_INT32_ARRAY:
		return adjacent_variant

	var adjacent_ids: PackedInt32Array = PackedInt32Array()
	if typeof(adjacent_variant) == TYPE_ARRAY:
		for value in adjacent_variant:
			adjacent_ids.append(int(value))
	return adjacent_ids


func _reset_runtime_state() -> void:
	current_node_id = DEFAULT_NODE_INDEX
	pending_node_id = NO_PENDING_NODE_ID
	pending_node_type = ""
	stage_key_resolved = false
	roadside_encounters_this_stage = 0
	_node_graph = []
	_support_node_states = {}
	_side_mission_node_states = {}


func _build_scaffold_graph(template_id: String, stage_index: int) -> Array[Dictionary]:
	var node_adjacency: Dictionary = _build_controlled_scatter_adjacency(template_id)
	var family_assignments: Dictionary = _build_controlled_scatter_family_assignments(node_adjacency, template_id, stage_index)
	var graph: Array[Dictionary] = _build_scatter_graph_payload(node_adjacency, family_assignments)
	if _validate_scatter_runtime_graph(graph):
		return graph
	if _validate_scatter_runtime_graph_min_floor(graph):
		return graph
	return _build_scatter_graph_fallback(template_id, stage_index, [])


func _build_scatter_graph_fallback(template_id: String, stage_index: int, depth_profile: Array[int]) -> Array[Dictionary]:
	var fallback_adjacency: Dictionary = _build_controlled_scatter_adjacency(DEFAULT_SCAFFOLD_TEMPLATE_ID)
	var fallback_families: Dictionary = _build_controlled_scatter_family_assignments(fallback_adjacency, DEFAULT_SCAFFOLD_TEMPLATE_ID, stage_index)
	var fallback_graph: Array[Dictionary] = _build_scatter_graph_payload(fallback_adjacency, fallback_families)
	if _validate_scatter_runtime_graph(fallback_graph):
		return fallback_graph
	if _validate_scatter_runtime_graph_min_floor(fallback_graph):
		return fallback_graph
	var emergency_graph: Array[Dictionary] = _build_scatter_emergency_fallback_graph(stage_index)
	if _validate_scatter_runtime_graph_min_floor(emergency_graph, true):
		return emergency_graph

	return []


func _build_scatter_emergency_fallback_graph(stage_index: int) -> Array[Dictionary]:
	var node_adjacency: Dictionary = _build_controlled_scatter_adjacency(DEFAULT_SCAFFOLD_TEMPLATE_ID)
	var assignments: Dictionary = _build_controlled_scatter_family_assignments(node_adjacency, DEFAULT_SCAFFOLD_TEMPLATE_ID, stage_index)
	return _build_scatter_graph_payload(node_adjacency, assignments)


func _validate_scatter_runtime_graph_min_floor(graph: Array[Dictionary], allow_reconnect_shortfall: bool = false) -> bool:
	if graph.size() != SCATTER_NODE_COUNT:
		return false
	if not _is_graph_connected_scatter(graph):
		return false

	var family_counts: Dictionary = {}
	var degree_counts: Dictionary = {}
	var adjacency_by_node_id: Dictionary = {}
	var key_node_id: int = NO_PENDING_NODE_ID
	var boss_node_id: int = NO_PENDING_NODE_ID
	var start_node_id: int = NO_PENDING_NODE_ID

	for entry_variant in graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
		var node_family: String = String(entry.get("node_family", ""))
		family_counts[node_family] = int(family_counts.get(node_family, 0)) + 1
		if node_family == "":
			return false
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		if adjacent_ids.size() < 1:
			return false
		if adjacent_ids.size() > SCATTER_MAX_NODE_DEGREE:
			return false

		var seen_adjacent_ids: Dictionary = {}
		for adjacent_node_id in adjacent_ids:
			if adjacent_node_id < 0 or adjacent_node_id == node_id or seen_adjacent_ids.has(adjacent_node_id):
				return false
			seen_adjacent_ids[adjacent_node_id] = true
		adjacency_by_node_id[node_id] = adjacent_ids

		if node_family == "start":
			start_node_id = node_id
		elif node_family == "key":
			key_node_id = node_id
		elif node_family == "boss":
			boss_node_id = node_id

		var degree: int = adjacent_ids.size()
		degree_counts[degree] = int(degree_counts.get(degree, 0)) + 1

	for node_id in adjacency_by_node_id.keys():
		for adjacent_node_id in adjacency_by_node_id.get(node_id, PackedInt32Array()):
			if not adjacency_by_node_id.has(adjacent_node_id):
				return false
			var reciprocal_adjacent_ids: PackedInt32Array = adjacency_by_node_id.get(adjacent_node_id, PackedInt32Array())
			if not reciprocal_adjacent_ids.has(node_id):
				return false

	var support_count: int = int(family_counts.get("rest", 0)) + int(family_counts.get("merchant", 0)) + int(family_counts.get("blacksmith", 0))
	if int(family_counts.get("start", 0)) != 1:
		return false
	if int(family_counts.get("event", 0)) != 1:
		return false
	if int(family_counts.get("reward", 0)) != 1:
		return false
	if int(family_counts.get("side_mission", 0)) != 1:
		return false
	if int(family_counts.get("key", 0)) != 1:
		return false
	if int(family_counts.get("boss", 0)) != 1:
		return false
	if support_count != 2:
		return false

	var depth_by_node_id: Dictionary = _build_scatter_depth_map(adjacency_by_node_id)
	if depth_by_node_id.size() != SCATTER_NODE_COUNT:
		return false
	var max_depth: int = 0
	for depth in depth_by_node_id.values():
		max_depth = max(max_depth, int(depth))

	var start_degree: int = adjacency_by_node_id.get(start_node_id, PackedInt32Array()).size()
	if start_degree < 2 or start_degree > SCATTER_MAX_NODE_DEGREE:
		return false
	if int(degree_counts.get(1, 0)) < 2:
		return false
	if int(degree_counts.get(2, 0)) < 2:
		return false
	if int(degree_counts.get(3, 0)) < 1:
		return false
	if int(degree_counts.get(0, 0)) > 0:
		return false

	if key_node_id == NO_PENDING_NODE_ID or boss_node_id == NO_PENDING_NODE_ID:
		return false
	var key_depth: int = int(depth_by_node_id.get(key_node_id, -1))
	var boss_depth: int = int(depth_by_node_id.get(boss_node_id, -1))
	if key_depth < max(2, max_depth - 1):
		return false
	if boss_depth < max_depth:
		return false

	var reconnect_count: int = _count_scatter_same_depth_reconnects(adjacency_by_node_id, depth_by_node_id)
	if reconnect_count < 1 and not allow_reconnect_shortfall:
		return false

	return true


func _build_controlled_scatter_adjacency(template_id: String) -> Dictionary:
	var node_adjacency: Dictionary = {}
	for node_id in range(SCATTER_NODE_COUNT):
		node_adjacency[node_id] = []

	var edge_pairs: Array = [
		[0, 1],
		[0, 2],
		[0, 3],
		[1, 4],
		[1, 5],
		[3, 6],
		[2, 7],
		[4, 8],
		[5, 9],
		[6, 10],
		[7, 11],
		[10, 12],
		[11, 13],
	]
	edge_pairs.append_array(_build_scatter_profile_extra_edges(template_id))

	for edge_pair_variant in edge_pairs:
		if typeof(edge_pair_variant) != TYPE_ARRAY:
			continue
		var edge_pair: Array = edge_pair_variant
		if edge_pair.size() != 2:
			continue
		_add_scatter_edge(node_adjacency, int(edge_pair[0]), int(edge_pair[1]))

	return node_adjacency


func _build_scatter_profile_extra_edges(template_id: String) -> Array:
	if template_id.find("openfield") != -1:
		return [
			[4, 7],
			[5, 6],
			[9, 10],
		]
	if template_id.find("loop") != -1:
		return [
			[4, 6],
			[5, 7],
			[8, 9],
		]
	return [
		[5, 6],
		[8, 9],
		[10, 11],
	]


func _build_controlled_scatter_family_assignments(node_adjacency: Dictionary, template_id: String, stage_index: int) -> Dictionary:
	var role_targets: Dictionary = _resolve_controlled_scatter_family_role_targets(template_id)
	if not _controlled_scatter_role_targets_are_valid(node_adjacency, role_targets):
		return {}
	var support_layout: Dictionary = _resolve_stage_support_layout(stage_index)
	var opening_support_family: String = String(support_layout.get("opening_support_family", "rest"))
	var late_support_family: String = String(support_layout.get("late_support_family", "merchant"))

	var assignments: Dictionary = {
		0: "start",
		int(role_targets.get("opening_combat_node_id", NO_PENDING_NODE_ID)): "combat",
		int(role_targets.get("opening_reward_node_id", NO_PENDING_NODE_ID)): "reward",
		int(role_targets.get("opening_support_node_id", NO_PENDING_NODE_ID)): opening_support_family,
		int(role_targets.get("late_support_node_id", NO_PENDING_NODE_ID)): late_support_family,
		int(role_targets.get("event_node_id", NO_PENDING_NODE_ID)): "event",
		int(role_targets.get("side_mission_node_id", NO_PENDING_NODE_ID)): "side_mission",
		int(role_targets.get("key_node_id", NO_PENDING_NODE_ID)): "key",
		int(role_targets.get("boss_node_id", NO_PENDING_NODE_ID)): "boss",
	}

	for node_id_variant in node_adjacency.keys():
		var node_id: int = int(node_id_variant)
		if assignments.has(node_id):
			continue
		assignments[node_id] = "combat"

	return assignments


func _resolve_controlled_scatter_family_role_targets(template_id: String) -> Dictionary:
	if template_id.find("openfield") != -1:
		return {
			"opening_combat_node_id": 1,
			"opening_reward_node_id": 2,
			"opening_support_node_id": 3,
			"late_support_node_id": 6,
			"event_node_id": 8,
			"side_mission_node_id": 13,
			"key_node_id": 9,
			"boss_node_id": 12,
		}
	if template_id.find("loop") != -1:
		return {
			"opening_combat_node_id": 1,
			"opening_reward_node_id": 2,
			"opening_support_node_id": 3,
			"late_support_node_id": 6,
			"event_node_id": 9,
			"side_mission_node_id": 13,
			"key_node_id": 8,
			"boss_node_id": 12,
		}
	return {
		"opening_combat_node_id": 1,
		"opening_reward_node_id": 2,
		"opening_support_node_id": 3,
		"late_support_node_id": 6,
		"event_node_id": 8,
		"side_mission_node_id": 12,
		"key_node_id": 10,
		"boss_node_id": 13,
	}


func _controlled_scatter_role_targets_are_valid(node_adjacency: Dictionary, role_targets: Dictionary) -> bool:
	if node_adjacency.is_empty() or role_targets.is_empty():
		return false

	var required_role_names: PackedStringArray = [
		"opening_combat_node_id",
		"opening_reward_node_id",
		"opening_support_node_id",
		"late_support_node_id",
		"event_node_id",
		"side_mission_node_id",
		"key_node_id",
		"boss_node_id",
	]
	var used_node_ids: Dictionary = {0: true}
	for role_name in required_role_names:
		var node_id: int = int(role_targets.get(role_name, NO_PENDING_NODE_ID))
		if node_id == NO_PENDING_NODE_ID or not node_adjacency.has(node_id) or used_node_ids.has(node_id):
			return false
		used_node_ids[node_id] = true

	var start_adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(node_adjacency.get(0, PackedInt32Array()))
	if not start_adjacent_ids.has(int(role_targets.get("opening_combat_node_id", NO_PENDING_NODE_ID))):
		return false
	if not start_adjacent_ids.has(int(role_targets.get("opening_reward_node_id", NO_PENDING_NODE_ID))):
		return false
	if not start_adjacent_ids.has(int(role_targets.get("opening_support_node_id", NO_PENDING_NODE_ID))):
		return false

	var opening_support_node_id: int = int(role_targets.get("opening_support_node_id", NO_PENDING_NODE_ID))
	var late_support_node_id: int = int(role_targets.get("late_support_node_id", NO_PENDING_NODE_ID))
	if not _coerce_adjacent_ids(node_adjacency.get(opening_support_node_id, PackedInt32Array())).has(late_support_node_id):
		return false

	var depth_by_node_id: Dictionary = _build_scatter_depth_map(node_adjacency)
	var event_node_id: int = int(role_targets.get("event_node_id", NO_PENDING_NODE_ID))
	var side_mission_node_id: int = int(role_targets.get("side_mission_node_id", NO_PENDING_NODE_ID))
	var key_node_id: int = int(role_targets.get("key_node_id", NO_PENDING_NODE_ID))
	var boss_node_id: int = int(role_targets.get("boss_node_id", NO_PENDING_NODE_ID))
	if int(depth_by_node_id.get(event_node_id, -1)) < 3:
		return false
	if int(depth_by_node_id.get(side_mission_node_id, -1)) < 3:
		return false
	if int(depth_by_node_id.get(key_node_id, -1)) < 3:
		return false
	if int(depth_by_node_id.get(boss_node_id, -1)) < 4:
		return false
	if _build_scatter_path_length(node_adjacency, key_node_id, boss_node_id) < 2:
		return false

	return true


func _build_scatter_path_length(node_adjacency: Dictionary, start_node_id: int, target_node_id: int) -> int:
	if start_node_id == target_node_id:
		return 0
	if not node_adjacency.has(start_node_id) or not node_adjacency.has(target_node_id):
		return -1

	var visited: Dictionary = {start_node_id: true}
	var queue: Array[Dictionary] = [{"node_id": start_node_id, "distance": 0}]
	while not queue.is_empty():
		var entry: Dictionary = queue.pop_front()
		var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
		var distance: int = int(entry.get("distance", 0))
		for adjacent_node_id in _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array())):
			if int(adjacent_node_id) == target_node_id:
				return distance + 1
			if visited.has(int(adjacent_node_id)):
				continue
			visited[int(adjacent_node_id)] = true
			queue.append({
				"node_id": int(adjacent_node_id),
				"distance": distance + 1,
			})
	return -1


func _count_scatter_same_depth_reconnects(adjacency_by_node_id: Dictionary, depth_by_node_id: Dictionary) -> int:
	var reconnect_count: int = 0
	var seen_edges: Dictionary = {}
	for node_id_variant in adjacency_by_node_id.keys():
		var node_id: int = int(node_id_variant)
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		for adjacent_node_id in _coerce_adjacent_ids(adjacency_by_node_id.get(node_id, PackedInt32Array())):
			var adjacent_depth: int = int(depth_by_node_id.get(adjacent_node_id, -1))
			var left_id: int = min(node_id, int(adjacent_node_id))
			var right_id: int = max(node_id, int(adjacent_node_id))
			var edge_key: String = "%d:%d" % [left_id, right_id]
			if seen_edges.has(edge_key):
				continue
			seen_edges[edge_key] = true
			if node_depth < 2 or adjacent_depth < 2:
				continue
			if node_depth != adjacent_depth:
				continue
			reconnect_count += 1
	return reconnect_count


func _resolve_scatter_depth_profile(template_id: String) -> Array[int]:
	if template_id.find("openfield") != -1:
		return [4, 4, 3, 2]
	if template_id.find("loop") != -1:
		return [3, 3, 4, 3]
	return [3, 4, 4, 2]


func _build_scatter_adjacency(depth_profile: Array[int], rng: RandomNumberGenerator) -> Dictionary:
	var depth_layers: Array = _build_scatter_depth_layers(depth_profile)
	if depth_layers.is_empty():
		return {}

	var node_adjacency: Dictionary = {}
	for node_id in range(SCATTER_NODE_COUNT):
		node_adjacency[node_id] = []

	for depth_index in range(1, depth_layers.size()):
		for node_id in depth_layers[depth_index]:
			var candidate_parent_ids: Array = depth_layers[depth_index - 1]
			if candidate_parent_ids.is_empty():
				return {}
			var parents: Array[int] = []
			for parent_id in candidate_parent_ids:
				parents.append(int(parent_id))
			_shuffle_int_array(parents, rng)
			_add_scatter_edge(node_adjacency, int(parents[0]), int(node_id))

	var extra_edge_count: int = rng.randi_range(SCATTER_EXTRA_EDGES_MIN, SCATTER_EXTRA_EDGES_MAX)
	for _edge_index in range(extra_edge_count):
		var new_edge: Array = _pick_scatter_reconnect_edge(node_adjacency, depth_layers, rng)
		if new_edge.size() != 2:
			continue
		var left_id: int = int(new_edge[0])
		var right_id: int = int(new_edge[1])
		if left_id == right_id or _has_scatter_edge(node_adjacency, left_id, right_id):
			continue
		if _get_scatter_degree(node_adjacency, left_id) >= SCATTER_MAX_NODE_DEGREE:
			continue
		if _get_scatter_degree(node_adjacency, right_id) >= SCATTER_MAX_NODE_DEGREE:
			continue
		_add_scatter_edge(node_adjacency, left_id, right_id)

	return node_adjacency


func _build_scatter_depth_layers(depth_profile: Array[int]) -> Array:
	if depth_profile.is_empty():
		return []

	var depth_layers: Array = [[0]]
	var remaining_nodes: int = SCATTER_NODE_COUNT - 1
	var next_node_id: int = 1
	for depth_index in range(depth_profile.size()):
		var slot_count: int = int(depth_profile[depth_index])
		var layer_nodes: Array[int] = []
		var placed_count: int = min(slot_count, remaining_nodes)
		for _count in range(placed_count):
			layer_nodes.append(next_node_id)
			next_node_id += 1
			remaining_nodes -= 1
		depth_layers.append(layer_nodes)

	if remaining_nodes > 0:
		for _count in range(remaining_nodes):
			if depth_layers.is_empty():
				return []
			depth_layers[depth_layers.size() - 1].append(next_node_id)
			next_node_id += 1
	elif remaining_nodes < 0:
		return []

	return depth_layers


func _pick_scatter_reconnect_edge(node_adjacency: Dictionary, depth_layers: Array, rng: RandomNumberGenerator) -> Array:
	var leaf_node_ids: Array[int] = []
	for node_id in node_adjacency.keys():
		if (node_adjacency[node_id] as Array).size() == 1:
			leaf_node_ids.append(int(node_id))
	if leaf_node_ids.size() >= 2:
		_shuffle_int_array(leaf_node_ids, rng)
		for left_index in range(leaf_node_ids.size()):
			for right_index in range(left_index + 1, leaf_node_ids.size()):
				var left_id: int = int(leaf_node_ids[left_index])
				var right_id: int = int(leaf_node_ids[right_index])
				if _has_scatter_edge(node_adjacency, left_id, right_id):
					continue
				if _get_scatter_degree(node_adjacency, left_id) >= SCATTER_MAX_NODE_DEGREE:
					continue
				if _get_scatter_degree(node_adjacency, right_id) >= SCATTER_MAX_NODE_DEGREE:
					continue
				if abs(_node_depth_from_layer(depth_layers, left_id) - _node_depth_from_layer(depth_layers, right_id)) > 1:
					continue
				return [left_id, right_id]

	var candidate_node_ids: Array[int] = []
	for node_id in node_adjacency.keys():
		candidate_node_ids.append(int(node_id))
	if candidate_node_ids.size() < 2:
		return []
	_shuffle_int_array(candidate_node_ids, rng)
	for _attempt in range(64):
		var left_id: int = int(candidate_node_ids[rng.randi_range(0, candidate_node_ids.size() - 1)])
		var right_id: int = int(candidate_node_ids[rng.randi_range(0, candidate_node_ids.size() - 1)])
		if left_id == right_id:
			continue
		if _has_scatter_edge(node_adjacency, left_id, right_id):
			continue
		if _get_scatter_degree(node_adjacency, left_id) >= SCATTER_MAX_NODE_DEGREE:
			continue
		if _get_scatter_degree(node_adjacency, right_id) >= SCATTER_MAX_NODE_DEGREE:
			continue
		return [left_id, right_id]

	return []


func _node_depth_from_layer(depth_layers: Array, node_id: int) -> int:
	for layer_index in range(depth_layers.size()):
		for layer_node_id in depth_layers[layer_index]:
			if int(layer_node_id) == node_id:
				return layer_index
	return 0


func _has_scatter_edge(node_adjacency: Dictionary, left_id: int, right_id: int) -> bool:
	return (node_adjacency.get(left_id, []) as Array[int]).has(right_id)


func _add_scatter_edge(node_adjacency: Dictionary, left_id: int, right_id: int) -> void:
	var left_adjacent: Array = node_adjacency.get(left_id, [])
	var right_adjacent: Array = node_adjacency.get(right_id, [])
	left_adjacent.append(right_id)
	right_adjacent.append(left_id)
	node_adjacency[left_id] = left_adjacent
	node_adjacency[right_id] = right_adjacent


func _get_scatter_degree(node_adjacency: Dictionary, node_id: int) -> int:
	return int((node_adjacency.get(node_id, []) as Array).size())


func _build_scatter_graph_payload(node_adjacency: Dictionary, family_assignments: Dictionary) -> Array[Dictionary]:
	var graph: Array[Dictionary] = []
	var ordered_node_ids: Array[int] = []
	for node_id in node_adjacency.keys():
		ordered_node_ids.append(int(node_id))
	ordered_node_ids.sort()

	for node_id in ordered_node_ids:
		var adjacent_node_ids: PackedInt32Array = _coerce_adjacent_ids(node_adjacency.get(node_id, PackedInt32Array()))
		adjacent_node_ids.sort()
		graph.append({
			"node_id": node_id,
			"node_family": String(family_assignments.get(node_id, "")),
			"node_state": NODE_STATE_UNDISCOVERED,
			"adjacent_node_ids": PackedInt32Array(adjacent_node_ids),
		})
	return graph


func _validate_scatter_runtime_graph(graph: Array[Dictionary]) -> bool:
	if graph.size() != SCATTER_NODE_COUNT:
		return false
	if not _is_graph_connected_scatter(graph):
		return false

	var family_counts: Dictionary = {}
	var adjacency_by_node_id: Dictionary = {}
	for entry_variant in graph:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			return false
		var entry: Dictionary = entry_variant
		var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
		if node_id < 0:
			return false
		if adjacency_by_node_id.has(node_id):
			return false
		var node_family: String = String(entry.get("node_family", ""))
		family_counts[node_family] = int(family_counts.get(node_family, 0)) + 1
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		if adjacent_ids.is_empty() and node_family != "boss":
			return false
		var seen_adjacent_ids: Dictionary = {}
		for adjacent_node_id in adjacent_ids:
			if adjacent_node_id < 0 or adjacent_node_id == node_id or seen_adjacent_ids.has(adjacent_node_id):
				return false
			seen_adjacent_ids[adjacent_node_id] = true
		adjacency_by_node_id[node_id] = adjacent_ids

	for node_id in adjacency_by_node_id.keys():
		var adjacent_node_ids: PackedInt32Array = adjacency_by_node_id[node_id]
		for adjacent_node_id in adjacent_node_ids:
			if not adjacency_by_node_id.has(adjacent_node_id):
				return false
			var reciprocal_adjacent_node_ids: PackedInt32Array = adjacency_by_node_id[adjacent_node_id]
			if not reciprocal_adjacent_node_ids.has(node_id):
				return false

	var expected_families: Dictionary = {
		"start": 1,
		"combat": 6,
		"event": 1,
		"reward": 1,
		"side_mission": 1,
		"key": 1,
		"boss": 1,
	}
	var support_count: int = int(family_counts.get("rest", 0)) + int(family_counts.get("merchant", 0)) + int(family_counts.get("blacksmith", 0))
	if int(family_counts.get("start", 0)) != expected_families["start"]:
		return false
	if int(family_counts.get("combat", 0)) != expected_families["combat"]:
		return false
	if int(family_counts.get("event", 0)) != expected_families["event"]:
		return false
	if int(family_counts.get("reward", 0)) != expected_families["reward"]:
		return false
	if int(family_counts.get("side_mission", 0)) != expected_families["side_mission"]:
		return false
	if int(family_counts.get("key", 0)) != expected_families["key"]:
		return false
	if int(family_counts.get("boss", 0)) != expected_families["boss"]:
		return false
	if support_count != 2:
		return false

	var node0_entry: Dictionary = {}
	for entry in graph:
		if int(entry.get("node_id", NO_PENDING_NODE_ID)) == 0:
			node0_entry = entry
			break
	if node0_entry.is_empty():
		return false
	var start_degree: int = int(_coerce_adjacent_ids(node0_entry.get("adjacent_node_ids", [])).size())
	if start_degree < 2 or start_degree > 4:
		return false

	var degree_counts: Dictionary = {}
	for entry in graph:
		var adjacent_ids: PackedInt32Array = _coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		var degree: int = adjacent_ids.size()
		degree_counts[degree] = int(degree_counts.get(degree, 0)) + 1
		if degree < 1 or degree > SCATTER_MAX_NODE_DEGREE:
			return false

	if int(degree_counts.get(1, 0)) < 2:
		return false
	if int(degree_counts.get(2, 0)) < 2:
		return false
	if int(degree_counts.get(3, 0)) < 1:
		return false

	var depth_by_node_id: Dictionary = _build_scatter_depth_map(adjacency_by_node_id)
	if _count_scatter_same_depth_reconnects(adjacency_by_node_id, depth_by_node_id) < 1:
		# Keep at least one late reconnect so the graph does not collapse into a pure tree.
		return false

	return true


func _is_graph_connected_scatter(graph: Array[Dictionary]) -> bool:
	var adjacency_by_node_id: Dictionary = {}
	var node_ids: Array[int] = []
	for entry in graph:
		var node_id: int = int(entry.get("node_id", NO_PENDING_NODE_ID))
		adjacency_by_node_id[node_id] = _coerce_adjacent_ids(entry.get("adjacent_node_ids", []))
		node_ids.append(node_id)
	if not adjacency_by_node_id.has(0):
		return false

	var visited: Dictionary = {}
	var queue: Array[int] = [0]
	while not queue.is_empty():
		var node_id: int = queue.pop_front()
		if visited.has(node_id):
			continue
		visited[node_id] = true
		for adjacent_node_id in adjacency_by_node_id.get(node_id, []):
			if not visited.has(adjacent_node_id):
				queue.append(adjacent_node_id)
	return visited.size() == node_ids.size()


func _build_scaffold_family_assignments(
	node_adjacency: Dictionary,
	stage_index: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var depth_by_node_id: Dictionary = _build_scatter_depth_map(node_adjacency)
	if not depth_by_node_id.has(0) or depth_by_node_id.size() != SCATTER_NODE_COUNT:
		return {}

	var assignments: Dictionary = {0: "start"}
	var remaining_node_ids: Array[int] = []
	for node_id in node_adjacency.keys():
		var typed_node_id: int = int(node_id)
		if typed_node_id != 0:
			remaining_node_ids.append(typed_node_id)
	remaining_node_ids.sort()

	var max_depth: int = 0
	for node_id in depth_by_node_id.keys():
		max_depth = max(max_depth, int(depth_by_node_id.get(node_id, 0)))
	if max_depth < 2:
		return {}

	var support_layout: Dictionary = _resolve_stage_support_layout(stage_index)
	var opening_support_family: String = String(support_layout.get("opening_support_family", "rest"))
	var late_support_family: String = String(support_layout.get("late_support_family", "merchant"))

	var opening_support_candidates: Array[int] = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, 1, 2)
	if opening_support_candidates.is_empty():
		opening_support_candidates = remaining_node_ids.duplicate()
	var opening_support_id: int = _pick_node_with_depth_bias(opening_support_candidates, depth_by_node_id, rng, false)
	if opening_support_id == NO_PENDING_NODE_ID:
		return {}
	assignments[opening_support_id] = opening_support_family
	remaining_node_ids.erase(opening_support_id)

	var reward_candidates: Array[int] = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, 1, 2)
	if reward_candidates.is_empty():
		reward_candidates = remaining_node_ids.duplicate()
	var reward_node_id: int = _pick_node_with_depth_bias(reward_candidates, depth_by_node_id, rng, false)
	if reward_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[reward_node_id] = "reward"
	remaining_node_ids.erase(reward_node_id)

	var event_candidates: Array[int] = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, 2, max_depth)
	if event_candidates.is_empty():
		event_candidates = remaining_node_ids.duplicate()
	var event_node_id: int = _pick_node_with_depth_bias(event_candidates, depth_by_node_id, rng, true)
	if event_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[event_node_id] = "event"
	remaining_node_ids.erase(event_node_id)

	var side_mission_candidates: Array[int] = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, 2, max_depth)
	if side_mission_candidates.is_empty():
		side_mission_candidates = remaining_node_ids.duplicate()
	var side_mission_node_id: int = _pick_node_with_depth_bias(side_mission_candidates, depth_by_node_id, rng, true)
	if side_mission_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[side_mission_node_id] = "side_mission"
	remaining_node_ids.erase(side_mission_node_id)

	var late_support_candidates: Array[int] = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, 2, max_depth)
	if late_support_candidates.is_empty():
		late_support_candidates = remaining_node_ids.duplicate()
	var late_support_id: int = _pick_node_with_depth_bias(late_support_candidates, depth_by_node_id, rng, true)
	if late_support_id == NO_PENDING_NODE_ID:
		return {}
	assignments[late_support_id] = late_support_family
	remaining_node_ids.erase(late_support_id)

	var key_candidates: Array[int] = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, max(2, max_depth - 1), max_depth)
	if key_candidates.is_empty():
		key_candidates = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, 2, max_depth)
	if key_candidates.is_empty():
		return {}
	var key_node_id: int = _pick_node_with_depth_bias(key_candidates, depth_by_node_id, rng, true)
	if key_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[key_node_id] = "key"
	remaining_node_ids.erase(key_node_id)

	var boss_candidates: Array[int] = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, max(2, max_depth), max_depth)
	if boss_candidates.is_empty():
		boss_candidates = _filter_nodes_by_depth_and_max(remaining_node_ids, depth_by_node_id, 2, max_depth)
	if boss_candidates.is_empty():
		return {}
	var boss_node_id: int = _pick_node_with_depth_bias(boss_candidates, depth_by_node_id, rng, true)
	if boss_node_id == NO_PENDING_NODE_ID:
		return {}
	assignments[boss_node_id] = "boss"
	remaining_node_ids.erase(boss_node_id)

	for remaining_node_id in remaining_node_ids:
		assignments[remaining_node_id] = "combat"
	return assignments


func _build_scatter_depth_map(node_adjacency: Dictionary) -> Dictionary:
	var depth_by_node_id: Dictionary = {}
	var queue: Array[int] = [0]
	depth_by_node_id[0] = 0
	while not queue.is_empty():
		var node_id: int = queue.pop_front()
		var current_depth: int = int(depth_by_node_id.get(node_id, 0))
		for adjacent_node_id in node_adjacency.get(node_id, []):
			if depth_by_node_id.has(adjacent_node_id):
				continue
			depth_by_node_id[adjacent_node_id] = current_depth + 1
			queue.append(adjacent_node_id)
	return depth_by_node_id


func _filter_nodes_by_depth_and_max(node_ids: Array[int], depth_by_node_id: Dictionary, min_depth: int, max_depth: int) -> Array[int]:
	var filtered_node_ids: Array[int] = []
	for node_id in node_ids:
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		if node_depth >= min_depth and node_depth <= max_depth:
			filtered_node_ids.append(node_id)
	return filtered_node_ids


func _pick_node_with_depth_bias(
	node_ids: Array[int],
	depth_by_node_id: Dictionary,
	rng: RandomNumberGenerator,
	prefer_outer: bool
) -> int:
	if node_ids.is_empty():
		return NO_PENDING_NODE_ID

	var target_depth: int = -1
	var depth_match: Array[int] = []
	for node_id in node_ids:
		var node_depth: int = int(depth_by_node_id.get(node_id, -1))
		if prefer_outer:
			if node_depth > target_depth:
				target_depth = node_depth
				depth_match = [node_id]
			elif node_depth == target_depth:
				depth_match.append(node_id)
		else:
			if target_depth == -1 or node_depth < target_depth:
				target_depth = node_depth
				depth_match = [node_id]
			elif node_depth == target_depth:
				depth_match.append(node_id)

	if depth_match.is_empty():
		depth_match = node_ids.duplicate()
	_shuffle_int_array(depth_match, rng)
	return depth_match[0]


func _resolve_stage_support_layout(stage_index: int) -> Dictionary:
	if STAGE_SUPPORT_LAYOUTS.is_empty():
		return {
			"opening_support_family": "rest",
			"late_support_family": "merchant",
		}
	var stage_offset: int = max(0, stage_index - 1)
	return (STAGE_SUPPORT_LAYOUTS[stage_offset % STAGE_SUPPORT_LAYOUTS.size()] as Dictionary).duplicate(true)


func _extract_realized_graph_array(value: Variant) -> Array[Dictionary]:
	var realized_graph: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return realized_graph

	for entry_variant in value:
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		realized_graph.append((entry_variant as Dictionary).duplicate(true))
	return realized_graph


func _build_graph_from_realized_payload(realized_graph: Array[Dictionary]) -> Array[Dictionary]:
	var graph: Array[Dictionary] = []
	for entry in realized_graph:
		var node_family: String = String(entry.get("node_family", ""))
		if node_family.is_empty():
			continue
		graph.append({
			"node_id": int(entry.get("node_id", NO_PENDING_NODE_ID)),
			"node_family": node_family,
			"node_state": String(entry.get("node_state", NODE_STATE_UNDISCOVERED)),
			"adjacent_node_ids": _coerce_adjacent_ids(entry.get("adjacent_node_ids", [])),
		})
	graph.sort_custom(Callable(self, "_sort_graph_nodes_by_id"))
	return graph


func _sort_graph_nodes_by_id(left: Dictionary, right: Dictionary) -> bool:
	return int(left.get("node_id", NO_PENDING_NODE_ID)) < int(right.get("node_id", NO_PENDING_NODE_ID))


func _shuffle_int_array(values: Array[int], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current_value: int = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value
